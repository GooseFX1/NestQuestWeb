import {
  Metadata,
  PROGRAM_ID as METADATA_ID,
} from "@metaplex-foundation/mpl-token-metadata";
import { Account } from "@metaplex-foundation/mpl-core";
import { web3, utils } from "@project-serum/anchor";
import { createAssociatedTokenAccountInstruction } from "@solana/spl-token";
import { BaseSignerWalletAdapter } from "@solana/wallet-adapter-base";
import { z } from "zod";
import { deposit as depositFn } from "./codegen/instructions/deposit";
import { withdraw as withdrawFn } from "./codegen/instructions/withdraw";
import { Stake } from "./codegen/accounts/Stake";
import { PROGRAM_ID } from "./codegen/programId";

const UPDATE_AUTH = new web3.PublicKey(
  "nestFGrTJ4QoRtvo8ZbASZZ2PSuv8AvvmaN1H31GhBQ"
);

const GOFX = new web3.PublicKey("GFX1ZjR2P15tmrSwow6FjyDYcEkoFb4p4gJCpLBjaxHD");

const connection = new web3.Connection(
  "https://solana-api.syndica.io/access-token/kKNTdSoSx35CV9cKOQjdpAHQgVyX5wiFPaqy4za5XHjRyjxWdPUKY2bKqxIabR79/rpc",
  { confirmTransactionInitialTimeout: 60000 }
);

interface Nft {
  mintId: string;
  name: string;
  tier: number;
}

const Offchain = z.object({
  description: z.string(),
});

const isNotNull = <T>(item: T | null): item is T => item !== null;

const vaultAddress = (mintId: web3.PublicKey) =>
  web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), mintId.toBuffer()],
    PROGRAM_ID
  );

const stakeAddress = (walletAddress: web3.PublicKey) =>
  web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), walletAddress.toBytes()],
    PROGRAM_ID
  );

const launch = async (
  wallet: BaseSignerWalletAdapter,
  transaction: web3.Transaction
) => {
  const { blockhash } = await connection.getRecentBlockhash();

  /* eslint-disable fp/no-mutation */
  transaction.recentBlockhash = blockhash;
  if (wallet.publicKey) {
    transaction.feePayer = wallet.publicKey;
  }
  /* eslint-enable fp/no-mutation */

  const signedTransaction = await wallet.signTransaction(transaction);

  return connection.sendRawTransaction(signedTransaction.serialize());
};

const hasBeenStaked = async (mintId: web3.PublicKey): Promise<boolean> => {
  const [vaultAddr] = await vaultAddress(mintId);
  const res = await connection.getAccountInfo(vaultAddr);
  return Boolean(res);
};

const getMetadataPDA = async (
  mintId: web3.PublicKey
): Promise<web3.PublicKey> => {
  const [addr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("metadata"), METADATA_ID.toBuffer(), mintId.toBuffer()],
    METADATA_ID
  );

  return addr;
};

const fetchStake = async (walletAddress: web3.PublicKey) => {
  const [stakeAddr] = await stakeAddress(walletAddress);

  const stake = await Stake.fetch(connection, stakeAddr);
  if (!stake) {
    return null;
  }

  const [vaultAddr] = await vaultAddress(stake.mintId);

  const balance = await connection.getTokenAccountBalance(vaultAddr);

  if (balance.value.uiAmount === 0) {
    return null;
  }

  return stake;
};

const withdraw = async (
  wallet: BaseSignerWalletAdapter,
  mintId: web3.PublicKey
) => {
  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const [stakeAddr, stakeBump] = await stakeAddress(wallet.publicKey);

  const [vaultAddr, vaultBump] = await vaultAddress(mintId);

  const [gofxVaultAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("gofx")],
    PROGRAM_ID
  );

  const gofxAssocAddr = await utils.token.associatedAddress({
    mint: GOFX,
    owner: wallet.publicKey,
  });
  const gofxAssocAccount = await connection.getAccountInfo(gofxAssocAddr);

  const nftAssocAddr = await utils.token.associatedAddress({
    mint: mintId,
    owner: wallet.publicKey,
  });
  const nftAssocAccount = await connection.getAccountInfo(nftAssocAddr);

  const args = { vaultBump, stakeBump };

  const accounts = {
    payer: wallet.publicKey,
    vault: vaultAddr,
    tokenAccount: nftAssocAddr,
    gofxMint: GOFX,
    gofxVault: gofxVaultAddr,
    gofxUserAccount: gofxAssocAddr,
    stake: stakeAddr,
    tokenProgram: utils.token.TOKEN_PROGRAM_ID,
  };

  const ix = withdrawFn(args, accounts);

  const transaction = new web3.Transaction();
  if (!gofxAssocAccount) {
    transaction.add(
      createAssociatedTokenAccountInstruction(
        wallet.publicKey,
        gofxAssocAddr,
        wallet.publicKey,
        GOFX,
        utils.token.TOKEN_PROGRAM_ID,
        utils.token.ASSOCIATED_PROGRAM_ID
      )
    );
  }
  if (!nftAssocAccount) {
    transaction.add(
      createAssociatedTokenAccountInstruction(
        wallet.publicKey,
        nftAssocAddr,
        wallet.publicKey,
        mintId,
        utils.token.TOKEN_PROGRAM_ID,
        utils.token.ASSOCIATED_PROGRAM_ID
      )
    );
  }
  transaction.add(ix);

  return launch(wallet, transaction);
};

const deposit = async (
  wallet: BaseSignerWalletAdapter,
  mintId: web3.PublicKey
) => {
  const [vaultAddr] = await vaultAddress(mintId);

  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const [stakeAddr] = await stakeAddress(wallet.publicKey);

  const metadataAddr = await getMetadataPDA(mintId);

  const accounts = {
    payer: wallet.publicKey,
    vault: vaultAddr,
    tokenAccount: await utils.token.associatedAddress({
      mint: mintId,
      owner: wallet.publicKey,
    }),
    mint: mintId,
    meta: metadataAddr,
    stake: stakeAddr,
    tokenProgram: utils.token.TOKEN_PROGRAM_ID,
    systemProgram: web3.SystemProgram.programId,
    rent: web3.SYSVAR_RENT_PUBKEY,
  };

  const transaction = new web3.Transaction();

  const ix = depositFn(accounts);

  transaction.add(ix);

  return launch(wallet, transaction);
};

const fetchOwned = async (walletAddress: web3.PublicKey): Promise<Nft[]> => {
  const tokensRaw = await connection.getParsedTokenAccountsByOwner(
    walletAddress,
    {
      programId: utils.token.TOKEN_PROGRAM_ID,
    }
  );

  const tokensFiltered = tokensRaw.value.filter(
    (tk) =>
      tk.account.data.parsed.info.tokenAmount.uiAmount === 1 &&
      tk.account.data.parsed.info.tokenAmount.decimals === 0
  );

  if (tokensFiltered.length === 0) {
    return [];
  }

  const tokens = tokensFiltered.map(
    (token) => new web3.PublicKey(token.account.data.parsed.info.mint)
  );

  const pdas: web3.PublicKey[] = await Promise.all(tokens.map(getMetadataPDA));

  const accounts = await Account.getInfos(connection, pdas);

  const metadatas = Array.from(accounts.values()).map((account) => {
    try {
      const [res] = Metadata.fromAccountInfo(account);
      return res;
    } catch (e) {
      console.error(e);
      return null;
    }
  });

  const gooseNfts = metadatas
    .filter(isNotNull)
    .filter((md) => md.updateAuthority.equals(UPDATE_AUTH));

  const data = await Promise.all(
    gooseNfts.map(async (metadata) => {
      const res = await fetch(metadata.data.uri);
      const json = await res.json();
      const offchain = Offchain.parse(json);
      return {
        mintId: metadata.mint.toString(),
        name: metadata.data.name,
        tier: offchain.description.includes("hatchling") ? 2 : 1,
      };
    })
  );

  return data;
};

export { withdraw, hasBeenStaked, fetchOwned, fetchStake, deposit };
