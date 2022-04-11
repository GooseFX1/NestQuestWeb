require("./index.css");

import {
  PhantomWalletAdapter,
  SolflareWalletAdapter,
  SlopeWalletAdapter,
  LedgerWalletAdapter,
} from "@solana/wallet-adapter-wallets";
import { BaseSignerWalletAdapter } from "@solana/wallet-adapter-base";
import { web3 } from "@project-serum/anchor";
import * as txns from "./txns";

const { Elm } = require("./Main.elm");

// eslint-disable-next-line fp/no-let
let theme: null | HTMLAudioElement = null;

// eslint-disable-next-line fp/no-let
let activeWallet: null | BaseSignerWalletAdapter = null;

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    screen: { width: window.innerWidth, height: window.innerHeight },
    now: Date.now(),
  },
});

const getWallet = (n: number) => {
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

const fetchState = async (wallet: BaseSignerWalletAdapter) => {
  const data = await txns.fetchStake(wallet);
  const stake = data
    ? {
        mintId: data.mintId.toString(),
        stakingStart: data.stakingStart.toNumber(),
      }
    : null;
  if (!wallet.publicKey) {
    throw "No publicKey";
  }
  return {
    address: wallet.publicKey.toString(),
    nfts: await txns.fetchOwned(wallet),
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

app.ports.stake.subscribe((mintId: string) =>
  (async () => {
    if (!(activeWallet && activeWallet.connected)) {
      return;
    }
    const mintPK = new web3.PublicKey(mintId);

    if (await txns.hasBeenStaked(mintPK)) {
      alert("This NFT has already been staked.");
      return app.ports.alreadyStaked.send(mintPK.toString());
    }

    const res = await txns.deposit(activeWallet, mintPK);
    console.log(res);
    return app.ports.stakeResponse.send({ stakingStart: Date.now(), mintId });
  })().catch((e) => {
    console.error(e);
    return app.ports.stakeResponse.send(null);
  })
);

app.ports.withdraw.subscribe((mintId: string) =>
  (async () => {
    if (!(activeWallet && activeWallet.connected)) {
      return;
    }
    const mintPK = new web3.PublicKey(mintId);

    const res = await txns.withdraw(activeWallet, mintPK);
    console.log(res);
    return app.ports.withdrawResponse.send(null);
  })().catch((e) => {
    console.error(e);
  })
);

app.ports.connect.subscribe((id: number) =>
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
