require("./index.css");

const { Elm } = require("./Main.elm");

Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    screen: { width: window.innerWidth, height: window.innerHeight },
  },
});
