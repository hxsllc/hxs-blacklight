const path    = require("path")
const webpack = require("webpack")
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');

module.exports = {
  entry: {
    application: "./app/javascript/application.js"
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    }),
    new NodePolyfillPlugin(),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    })
  ]
}
