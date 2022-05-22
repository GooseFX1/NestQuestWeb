require("./index.css");

import {
  PhantomWalletAdapter,
  SolflareWalletAdapter,
  SlopeWalletAdapter,
  LedgerWalletAdapter,
} from "@solana/wallet-adapter-wallets";
import {
  BaseMessageSignerWalletAdapter,
  BaseSignerWalletAdapter,
} from "@solana/wallet-adapter-base";
import { web3 } from "@project-serum/anchor";
import * as txns from "./txns";

import { Elm, FromElm } from "./Main.elm";

const DEBUG = window.location.search.includes("debug=true");

// eslint-disable-next-line fp/no-let
let theme: null | HTMLAudioElement = null;

// eslint-disable-next-line fp/no-let
let activeWallet:
  | null
  | BaseMessageSignerWalletAdapter
  | BaseSignerWalletAdapter = null;

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

const fetchState = async (
  wallet: BaseMessageSignerWalletAdapter | BaseSignerWalletAdapter
) => {
  if (!wallet.publicKey) {
    throw "No publicKey";
  }
  const data = await txns.fetchStake(wallet.publicKey);
  const stake = data
    ? {
        mintId: data.mintId.toString(),
        stakingStart: data.stakingStart.toNumber(),
      }
    : null;
  return {
    address: wallet.publicKey.toString(),
    nfts: await txns.fetchOwned(wallet.publicKey),
    stake,
  };
};

const playTheme = () => {
  if (theme) {
    return theme.play();
  }

  const audio = new Audio("/theme.mp3");

  audio.addEventListener("canplay", () => {
    // eslint-disable-next-line fp/no-mutation
    theme = audio;
    audio.play();
  });
};

const stopTheme = () => {
  if (!theme) {
    return;
  }

  theme.pause();
};

const stake = (mintId: string) =>
  (async () => {
    if (!(activeWallet && activeWallet.connected)) {
      return;
    }
    const mintPK = new web3.PublicKey(mintId);

    if (await txns.hasBeenStaked(mintPK)) {
      alert("This NFT has already been staked.");
      return app.ports.interopToElm.send({
        tag: "alreadyStaked",
        data: mintId.toString(),
      });
    }

    const res = await txns.deposit(activeWallet, mintPK);
    console.log(res);
    return app.ports.interopToElm.send({
      tag: "stakeResponse",
      data: { stakingStart: Date.now(), mintId },
    });
  })().catch((e) => {
    console.error(e);
    if (DEBUG) {
      alert(e);
    }
    return app.ports.interopToElm.send({
      tag: "stakeResponse",
      data: null,
    });
  });

const withdraw = (mintId: string) =>
  (async () => {
    if (!(activeWallet && activeWallet.connected)) {
      return;
    }
    const mintPK = new web3.PublicKey(mintId);

    const res = await txns.withdraw(activeWallet, mintPK);

    const nft = await txns.fetchNFT(mintPK);

    console.log(res);
    return app.ports.interopToElm.send({
      tag: "withdrawResponse",
      data: nft,
    });
  })().catch((e) => {
    console.error(e);
    if (DEBUG) {
      alert(e);
    }
    return app.ports.interopToElm.send({
      tag: "withdrawResponse",
      data: null,
    });
  });

const signMessage = (mintId: string) =>
  (async () => {
    const encodedMessage = new TextEncoder().encode(
      "NestQuest verify:\n" + mintId
    );

    if (!(activeWallet && activeWallet.connected)) {
      return;
    }

    if (!(activeWallet instanceof BaseMessageSignerWalletAdapter)) {
      alert("This wallet does not support message signing.");
      return app.ports.interopToElm.send({
        tag: "signResponse",
        data: null,
      });
    }

    const signedMessage = await activeWallet.signMessage(encodedMessage);

    if (!signedMessage) {
      return console.error("empty signature");
    }

    return app.ports.interopToElm.send({
      tag: "signResponse",
      data: {
        mintId,
        signature: Buffer.from(signedMessage).toString("hex"),
      },
    });
  })().catch((e) => {
    console.error(e);
    return app.ports.interopToElm.send({
      tag: "signResponse",
      data: null,
    });
  });

const connect = (id: number) =>
  (async () => {
    const wallet = getWallet(id);

    if (!wallet) {
      console.log("no wallet");
      return app.ports.interopToElm.send({
        tag: "connectResponse",
        data: null,
      });
    }

    await wallet.connect();

    // eslint-disable-next-line fp/no-mutation
    activeWallet = wallet;

    return app.ports.interopToElm.send({
      tag: "connectResponse",
      data: await fetchState(wallet),
    });
  })().catch((e) => {
    console.error(e);
    return app.ports.interopToElm.send({ tag: "connectResponse", data: null });
  });

const disconnect = async () => {
  if (activeWallet && activeWallet.connected) {
    await activeWallet.disconnect();
  }
};

app.ports.interopFromElm.subscribe((fromElm) => handlePorts(fromElm));

// Returning a boolean ensures the switch statement is exhaustive.
const handlePorts = (fromElm: FromElm): boolean => {
  switch (fromElm.tag) {
    case "connect": {
      connect(fromElm.data);
      return true;
    }
    case "disconnect": {
      disconnect();
      return true;
    }
    case "stake": {
      stake(fromElm.data);
      return true;
    }
    case "signTimestamp": {
      signMessage(fromElm.data);
      return true;
    }
    case "withdraw": {
      withdraw(fromElm.data);
      return true;
    }
    case "stopTheme": {
      stopTheme();
      return true;
    }
    case "playTheme": {
      playTheme();
      return true;
    }
    case "log": {
      console.log(fromElm.data);
      return true;
    }
    case "alert": {
      alert(fromElm.data);
      return true;
    }
  }
};
