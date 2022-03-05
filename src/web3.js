import { Metadata } from "@metaplex-foundation/mpl-token-metadata";
import { Account } from "@metaplex-foundation/mpl-core";
import { web3, Provider, Program, utils } from "@project-serum/anchor";

const PROGRAM_ID = "NQDKVecDDY3espZ7LynBrFSy8fTr8VrTrXQ7PRBMK1a";
const UPDATE_AUTH = "nestFGrTJ4QoRtvo8ZbASZZ2PSuv8AvvmaN1H31GhBQ";

const idl = require("./nestquest.json");

const connection = new web3.Connection(
  "https://solana-api.syndica.io/access-token/kKNTdSoSx35CV9cKOQjdpAHQgVyX5wiFPaqy4za5XHjRyjxWdPUKY2bKqxIabR79/rpc"
);

const provider = new Provider(connection, "processed");

const program = new Program(idl, new web3.PublicKey(PROGRAM_ID), provider);

const launch = async (wallet, transaction) => {
  const { blockhash } = await connection.getRecentBlockhash();

  /* eslint-disable fp/no-mutation */
  transaction.recentBlockhash = blockhash;
  transaction.feePayer = wallet.publicKey;
  /* eslint-enable fp/no-mutation */

  const signedTransaction = await wallet.signTransaction(transaction);

  return connection.sendRawTransaction(signedTransaction.serialize());
};

const fetchMeta = async (mintId) => {
  const metadata = await Metadata.getPDA(mintId);
  const metadataInfo = await Account.getInfo(connection, metadata);
  const res = new Metadata(metadata, metadataInfo);
  return res.data || null;
};

const fetchStake = async (wallet) => {
  const [stakeAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), wallet.publicKey.toBytes()],
    program.programId
  );

  const stake = await program.account.stake.fetchNullable(stakeAddr);
  if (!stake) {
    return null;
  }

  const [vaultAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), stake.mintId.toBuffer()],
    program.programId
  );

  const balance = await connection.getTokenAccountBalance(vaultAddr);

  if (balance.value.uiAmount === 0) {
    return null;
  }

  return stake;
};

const withdraw = async (wallet, mintId) => {
  const mintKey = new web3.PublicKey(mintId);

  const [stakeAddr, stakeBump] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), wallet.publicKey.toBuffer()],
    program.programId
  );

  const [vaultAddr, vaultBump] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), mintKey.toBuffer()],
    program.programId
  );

  const transaction = await program.transaction.withdraw(vaultBump, stakeBump, {
    accounts: {
      payer: wallet.publicKey,
      vault: vaultAddr,
      tokenAccount: await utils.token.associatedAddress({
        mint: mintKey,
        owner: wallet.publicKey,
      }),
      stake: stakeAddr,
      systemProgram: web3.SystemProgram.programId,
      tokenProgram: utils.token.TOKEN_PROGRAM_ID,
    },
  });

  return launch(wallet, transaction);
};

const deposit = async (wallet, mintId) => {
  const mintKey = new web3.PublicKey(mintId);

  const [vaultAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("vault"), mintKey.toBuffer()],
    program.programId
  );

  const [stakeAddr] = await web3.PublicKey.findProgramAddress(
    [Buffer.from("stake"), wallet.publicKey.toBuffer()],
    program.programId
  );

  const metadataAddr = await Metadata.getPDA(mintId);

  const transaction = await program.transaction.deposit({
    accounts: {
      payer: wallet.publicKey,
      vault: vaultAddr,
      systemProgram: web3.SystemProgram.programId,
      tokenAccount: await utils.token.associatedAddress({
        mint: mintKey,
        owner: wallet.publicKey,
      }),
      tokenProgram: utils.token.TOKEN_PROGRAM_ID,
      mint: mintId,
      rent: web3.SYSVAR_RENT_PUBKEY,
      meta: metadataAddr,
      stake: stakeAddr,
    },
  });

  return launch(wallet, transaction);
};

const fetchOwned = async (wallet) => {
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

  const metadata = await Promise.all(
    tokens.map((x) =>
      fetchMeta(x.account.data.parsed.info.mint).catch(() => null)
    )
  );

  return metadata
    .filter((x) => x)
    .filter((md) => md.updateAuthority === UPDATE_AUTH)
    .map((md) => md.mint);
};

export { withdraw, fetchOwned, fetchStake, deposit };
