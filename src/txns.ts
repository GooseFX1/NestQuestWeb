import {
  Metadata,
  PROGRAM_ID as METADATA_ID,
} from "@metaplex-foundation/mpl-token-metadata";
import { Account } from "@metaplex-foundation/mpl-core";
import { web3, utils } from "@project-serum/anchor";
import { createAssociatedTokenAccountInstruction } from "@solana/spl-token";
import { BaseSignerWalletAdapter } from "@solana/wallet-adapter-base";
import { z } from "zod";
import { deposit as depositFn } from "./codegen/staking/instructions/deposit";
import { withdraw as withdrawFn } from "./codegen/staking/instructions/withdraw";
import { claimOrb } from "./codegen/staking/instructions/claimOrb";
import { Stake } from "./codegen/staking/accounts/Stake";
import { PROGRAM_ID } from "./codegen/staking/programId";

// @ts-ignore
// eslint-disable-next-line no-undef
const RPC_URL: string = RPC_URL_;

const UPDATE_AUTH = new web3.PublicKey(
  "nestFGrTJ4QoRtvo8ZbASZZ2PSuv8AvvmaN1H31GhBQ"
);

const GOFX = new web3.PublicKey("GFX1ZjR2P15tmrSwow6FjyDYcEkoFb4p4gJCpLBjaxHD");

const ORB_MINT = new web3.PublicKey(
  "orbs7FDskYc92kNer1M9jHBFaB821iCmPJkumZA4yyd"
);

const connection = new web3.Connection(RPC_URL, {
  confirmTransactionInitialTimeout: 60000,
});

interface Nft {
  mintId: string;
  name: string;
  tier: number;
}

const Offchain = z.object({
  description: z.string(),
  attributes: z.array(z.object({ trait_type: z.string(), value: z.string() })),
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

  return {
    mintId: stake.mintId.toString(),
    stakingStart: stake.stakingStart.toNumber(),
  };
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

const claim = async (
  wallet: BaseSignerWalletAdapter,
  mintId: web3.PublicKey,
  sig: number[]
) => {
  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const userOrbAcct = await utils.token.associatedAddress({
    mint: ORB_MINT,
    owner: wallet.publicKey,
  });
  const userOrbData = await connection.getAccountInfo(userOrbAcct);

  const [claimState] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("orb"), mintId.toBytes()],
    PROGRAM_ID
  );

  const [authorityAcct] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("orb")],
    PROGRAM_ID
  );

  const accounts = {
    payer: wallet.publicKey,
    userOrbAcct,
    authorityAcct,
    claimState,
    orbMint: ORB_MINT,
    tier3Nft: mintId,
    instructions: web3.SYSVAR_INSTRUCTIONS_PUBKEY,
    tokenProgram: utils.token.TOKEN_PROGRAM_ID,
    systemProgram: web3.SystemProgram.programId,
  };

  const edIx = web3.Ed25519Program.createInstructionWithPublicKey({
    message: mintId.toBytes(),
    publicKey: UPDATE_AUTH.toBytes(),
    signature: Buffer.from(sig),
  });

  const transaction = new web3.Transaction();

  if (!userOrbData) {
    transaction.add(
      createAssociatedTokenAccountInstruction(
        wallet.publicKey,
        userOrbAcct,
        wallet.publicKey,
        ORB_MINT,
        utils.token.TOKEN_PROGRAM_ID,
        utils.token.ASSOCIATED_PROGRAM_ID
      )
    );
  }

  transaction.add(edIx);

  const ix = claimOrb(accounts);
  transaction.add(ix);

  return launch(wallet, transaction);
};

const fetchOrbs = async (walletAddress: web3.PublicKey): Promise<number> => {
  const addr = await utils.token.associatedAddress({
    mint: ORB_MINT,
    owner: walletAddress,
  });

  const account = await connection.getAccountInfo(addr);

  if (!account) {
    return 0;
  }

  const token = await connection.getTokenAccountBalance(addr);

  return parseInt(token.value.amount);
};

const fetchOwned = async (walletAddress: web3.PublicKey): Promise<Nft[]> => {
  const tokensRaw = await connection.getParsedTokenAccountsByOwner(
    walletAddress,
    {
      programId: utils.token.TOKEN_PROGRAM_ID,
    }
  );

  const metadataPDAs = tokensRaw.value.flatMap((tk) =>
    tk.account.data.parsed.info.tokenAmount.uiAmount === 1 &&
    tk.account.data.parsed.info.tokenAmount.decimals === 0
      ? [getMetadataPDA(new web3.PublicKey(tk.account.data.parsed.info.mint))]
      : []
  );

  if (metadataPDAs.length === 0) {
    return [];
  }

  const pdas: web3.PublicKey[] = await Promise.all(metadataPDAs);

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

  const data = await Promise.all(gooseNfts.map(parseNft));

  return data;
};

const parseNft = async (metadata: Metadata): Promise<Nft> => {
  const res = await fetch(metadata.data.uri, { cache: "no-store" });
  const json = await res.json();
  const offchain = Offchain.parse(json);
  const tierAttribute = offchain.attributes.find(
    (attr) => attr.trait_type === "Tier"
  );
  const tier =
    tierAttribute === undefined
      ? offchain.description.includes("stronger Gosling")
        ? 3
        : offchain.description.includes("hatchling has emerged")
        ? 2
        : 1
      : Number(tierAttribute.value);
  return {
    mintId: metadata.mint.toString(),
    name: metadata.data.name,
    tier,
  };
};

const fetchNFT = async (mintId: web3.PublicKey): Promise<Nft> => {
  const pda = await getMetadataPDA(mintId);
  const metadata = await Metadata.fromAccountAddress(connection, pda);
  return parseNft(metadata);
};

export {
  withdraw,
  hasBeenStaked,
  fetchOwned,
  fetchStake,
  fetchOrbs,
  deposit,
  fetchNFT,
  claim,
};
