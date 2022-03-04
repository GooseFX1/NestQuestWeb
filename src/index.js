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

// eslint-disable-next-line fp/no-let
let activeWallet = null;

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    screen: { width: window.innerWidth, height: window.innerHeight },
    now: Date.now(),
  },
});

const getWallet = (n) => {
  const wallet = (() => {
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
      default: {
        return new LedgerWalletAdapter();
      }
    }
  })();

  return wallet.readyState === "Installed" || wallet.readyState === "Loadable"
    ? wallet
    : null;
};

const fetchState = async (wallet) => {
  const data = await web3.fetchStake(wallet);
  const stake = data
    ? {
        mintId: data.mintId.toString(),
        stakingStart: data.stakingStart.toNumber(),
      }
    : null;
  return {
    address: wallet.publicKey.toString(),
    nfts: await web3.fetchOwned(wallet),
    stake,
  };
};

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
    if (!(activeWallet && activeWallet.connected)) {
      return;
    }
    const res = await web3.deposit(activeWallet, mintId);
    console.log(res);
    return app.ports.stakeResponse.send(true);
  })().catch((e) => {
    console.error(e);
    return app.ports.stakeResponse.send(false);
  })
);

app.ports.withdraw.subscribe((mintId) =>
  (async () => {
    if (!(activeWallet && activeWallet.connected)) {
      return;
    }
    const res = await web3.withdraw(activeWallet, mintId);
    console.log(res);
    alert("Success!");
  })().catch((e) => {
    console.error(e);
  })
);

app.ports.connect.subscribe((id) =>
  (async () => {
    const wallet = getWallet(id);

    if (!wallet) {
      console.log("no wallet");
      return app.ports.connectResponse.send(null);
    }

    await wallet.connect();

    // eslint-disable-next-line fp/no-mutation
    activeWallet = wallet;

    return app.ports.connectResponse.send(await fetchState(wallet));
  })().catch((e) => {
    console.error(e);
    return app.ports.connectResponse.send(null);
  })
);

app.ports.disconnect.subscribe(async () => {
  if (activeWallet && activeWallet.connected) {
    await activeWallet.disconnect();
  }
});
