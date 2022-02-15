import { TOKEN_PROGRAM_ID } from "@solana/spl-token";
import * as web3 from "@solana/web3.js";
import { Metadata } from "@metaplex-foundation/mpl-token-metadata";
import { Account } from "@metaplex-foundation/mpl-core";

const connection = new web3.Connection("https://api.mainnet-beta.solana.com");

const fetchMeta = async (mintId) => {
  const metadata = await Metadata.getPDA(mintId);
  const metadataInfo = await Account.getInfo(connection, metadata);
  const { data } = new Metadata(metadata, metadataInfo);
  return data;
};

const fetchOwned = async (wallet) => {
  const tokensRaw = await connection.getParsedTokenAccountsByOwner(
    wallet.publicKey,
    {
      programId: TOKEN_PROGRAM_ID,
    }
  );

  const tokens = tokensRaw.value.filter(
    (tk) => tk.account.data.parsed.info.tokenAmount.uiAmount === 1
  );

  if (tokens.length == 0) {
    return 0;
  }

  const metadata = await Promise.all(
    tokens.map((x) => fetchMeta(x.account.data.parsed.info.mint))
  );

  return metadata.filter(
    (md) => md.updateAuthority === "nestFGrTJ4QoRtvo8ZbASZZ2PSuv8AvvmaN1H31GhBQ"
  ).length;
};

export { fetchOwned };
