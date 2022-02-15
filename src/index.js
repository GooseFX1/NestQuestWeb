require("./index.css");

const web3 = require("./web3.js");
const { Elm } = require("./Main.elm");

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    screen: { width: window.innerWidth, height: window.innerHeight },
  },
});

const getWallet = () => window.solana || window.solflare || null;

const fetchState = async (wallet) => ({
  address: wallet.publicKey.toString(),
  count: await web3.fetchOwned(wallet),
});

app.ports.connect.subscribe(() =>
  (async () => {
    const wallet = getWallet();

    if (!wallet) {
      console.log("no wallet");
      return app.ports.connectResponse.send(null);
    }

    if (wallet.isConnected) {
      return app.ports.connectResponse.send(await fetchState(wallet));
    }

    await wallet.connect();

    return app.ports.connectResponse.send(await fetchState(wallet));
  })().catch((e) => {
    console.error(e);
    return app.ports.connectResponse.send(null);
  })
);
