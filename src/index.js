require("./index.css");

const { Elm } = require("./Main.elm");

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    screen: { width: window.innerWidth, height: window.innerHeight },
  },
});

const getWallet = () => window.solana || window.solflare || null;

app.ports.connect.subscribe(() =>
  (async () => {
    const wallet = getWallet();

    if (!wallet) {
      console.log("no wallet");
      return app.ports.connectResponse.send(null);
    }

    if (wallet.isConnected) {
      return app.ports.connectResponse.send(wallet.publicKey.toString());
    }

    await wallet.connect();

    return app.ports.connectResponse.send(wallet.publicKey.toString());
  })().catch((e) => {
    console.error(e);
    return app.ports.connectResponse.send(null);
  })
);
