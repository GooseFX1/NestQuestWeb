import {
  Metadata,
  MetadataData,
} from "@metaplex-foundation/mpl-token-metadata";
import { Account } from "@metaplex-foundation/mpl-core";
import { web3, utils } from "@project-serum/anchor";
import { BaseSignerWalletAdapter } from "@solana/wallet-adapter-base";
import { deposit as depositFn } from "./codegen/instructions/deposit";
import { withdraw as withdrawFn } from "./codegen/instructions/withdraw";
import { Stake } from "./codegen/accounts/Stake";
import { PROGRAM_ID } from "./codegen/programId";

const isNotNull = <T>(item: T | null): item is T => item !== null;

const UPDATE_AUTH = "nestFGrTJ4QoRtvo8ZbASZZ2PSuv8AvvmaN1H31GhBQ";

const connection = new web3.Connection(
  "https://solana-api.syndica.io/access-token/kKNTdSoSx35CV9cKOQjdpAHQgVyX5wiFPaqy4za5XHjRyjxWdPUKY2bKqxIabR79/rpc"
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

const fetchMeta = async (mintId: web3.PublicKey): Promise<MetadataData> => {
  const metadata = await Metadata.getPDA(mintId);
  const metadataInfo = await Account.getInfo(connection, metadata);
  const res = new Metadata(metadata, metadataInfo);
  return res.data;
};

const fetchStake = async (wallet: BaseSignerWalletAdapter) => {
  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const [stakeAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), wallet.publicKey.toBytes()],
    PROGRAM_ID
  );

  const stake = await Stake.fetch(connection, stakeAddr);
  if (!stake) {
    return null;
  }

  const [vaultAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), stake.mintId.toBuffer()],
    PROGRAM_ID
  );

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
  const mintKey = new web3.PublicKey(mintId);

  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const [stakeAddr, stakeBump] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), wallet.publicKey.toBuffer()],
    PROGRAM_ID
  );

  const [vaultAddr, vaultBump] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), mintKey.toBuffer()],
    PROGRAM_ID
  );

  const args = { vaultBump, stakeBump };

  const accounts = {
    payer: wallet.publicKey,
    vault: vaultAddr,
    tokenAccount: await utils.token.associatedAddress({
      mint: mintKey,
      owner: wallet.publicKey,
    }),
    stake: stakeAddr,
    systemProgram: web3.SystemProgram.programId,
    tokenProgram: utils.token.TOKEN_PROGRAM_ID,
  };

  const ix = withdrawFn(args, accounts);

  const transaction = new web3.Transaction();
  transaction.add(ix);

  return launch(wallet, transaction);
};

const deposit = async (
  wallet: BaseSignerWalletAdapter,
  mintId: web3.PublicKey
) => {
  const mintKey = new web3.PublicKey(mintId);

  const [vaultAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), mintKey.toBuffer()],
    PROGRAM_ID
  );

  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const [stakeAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), wallet.publicKey.toBuffer()],
    PROGRAM_ID
  );

  const metadataAddr = await Metadata.getPDA(mintId);

  const accounts = {
    payer: wallet.publicKey,
    vault: vaultAddr,
    tokenAccount: await utils.token.associatedAddress({
      mint: mintKey,
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

const fetchOwned = async (
  wallet: BaseSignerWalletAdapter
): Promise<string[]> => {
  if (!wallet.publicKey) {
    throw "No publicKey";
  }

  const tokensRaw = await connection.getParsedTokenAccountsByOwner(
    wallet.publicKey,
    {
      programId: utils.token.TOKEN_PROGRAM_ID,
    }
  );

  const tokens = tokensRaw.value.filter(
    (tk) =>
      tk.account.data.parsed.info.tokenAmount.uiAmount === 1 &&
      tk.account.data.parsed.info.tokenAmount.decimals === 0
  );

  if (tokens.length === 0) {
    return [];
  }

  const metadata: (MetadataData | null)[] = await Promise.all(
    tokens.map((x) =>
      fetchMeta(x.account.data.parsed.info.mint).catch(() => null)
    )
  );

  const mints = metadata
    .filter(isNotNull)
    .filter((md) => md.updateAuthority === UPDATE_AUTH)
    .map((md) => md.mint);

  return mints;
};

export { withdraw, fetchOwned, fetchStake, deposit };
