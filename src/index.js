require("./index.css");

import {
  PhantomWalletAdapter,
  SolflareWalletAdapter,
  SlopeWalletAdapter,
  LedgerWalletAdapter,
} from "@solana/wallet-adapter-wallets";

const web3 = require("./web3.js");
const { Elm } = require("./Main.elm");

// eslint-disable-next-line fp/no-let
let theme = null;

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    screen: { width: window.innerWidth, height: window.innerHeight },
  },
});

const getWallet = (n) => {
  switch (n) {
    case 0: {
      return new PhantomWalletAdapter();
    }
    case 1: {
      return new SolflareWalletAdapter();
    }
    case 2: {
      return new SlopeWalletAdapter();
    }
    case 3: {
      return new LedgerWalletAdapter();
    }
    default: {
      return null;
    }
  }
};

const fetchState = async (wallet) => ({
  address: wallet.publicKey.toString(),
  nfts: await web3.fetchOwned(wallet),
});

app.ports.playTheme.subscribe(() => {
  if (theme) {
    return theme.play();
  }

  const audio = new Audio("/theme.mp3");

  audio.addEventListener("canplay", () => {
    // eslint-disable-next-line fp/no-mutation
    theme = audio;
    audio.play();
  });
});

app.ports.stopTheme.subscribe(() => {
  if (!theme) {
    return;
  }

  theme.pause();
});

app.ports.stake.subscribe((mintId) =>
  (async () => {
    console.log(mintId);
  })().catch((e) => {
    console.error(e);
  })
);

app.ports.connect.subscribe((n) =>
  (async () => {
    const wallet = getWallet(n);

    if (!wallet) {
      console.log("no wallet");
      return app.ports.connectResponse.send(null);
    }

    //if (wallet.isConnected) {
    //return app.ports.connectResponse.send(await fetchState(wallet));
    //}

    await wallet.connect();

    return app.ports.connectResponse.send(await fetchState(wallet));
  })().catch((e) => {
    console.error(e);
    return app.ports.connectResponse.send(null);
  })
);
