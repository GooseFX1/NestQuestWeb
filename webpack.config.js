const { resolve } = require("path");
const webpack = require("webpack");
const NodePolyfillPlugin = require("node-polyfill-webpack-plugin");

const { RPC_URL, PROGRAM_ID, BACKEND_URL } = process.env;

const publicFolder = resolve("./public");

module.exports = (env) => {
  const devMode = Boolean(env.WEBPACK_SERVE);

  const loaderConfig = {
    loader: "elm-webpack-loader",
    options: {
      debug: false,
      optimize: !devMode,
      cwd: __dirname,
    },
  };

  const elmLoader = devMode
    ? [{ loader: "elm-reloader" }, loaderConfig]
    : [loaderConfig];

  return {
    mode: devMode ? "development" : "production",
    entry: "./src/index.ts",
    output: {
      publicPath: "/",
      path: publicFolder,
      filename: "bundle.js",
    },
    stats: devMode ? "errors-warnings" : "normal",
    infrastructureLogging: {
      level: "warn",
    },
    devServer: {
      port: 8000,
      hot: "only",
    },
    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: elmLoader,
        },
        {
          test: /\.(ttf|woff2)$/,
          type: "asset/inline",
        },
        {
          test: /\.css$/,
          use: ["style-loader", "css-loader"],
        },
        {
          test: /\.ts$/,
          use: "ts-loader",
          exclude: /node_modules/,
        },
      ],
    },
    resolve: {
      extensions: [".ts", ".js"],
    },
    plugins: [
      new NodePolyfillPlugin(),
      new webpack.NoEmitOnErrorsPlugin(),
      new webpack.DefinePlugin({
        RPC_URL_: JSON.stringify(RPC_URL),
        BACKEND_URL_: JSON.stringify(BACKEND_URL),
        PROGRAM_ID_: JSON.stringify(PROGRAM_ID),
      }),
    ],
  };
};
