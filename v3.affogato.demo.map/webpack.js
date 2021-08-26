const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
// const CleanWebpackPlugin = require("clean-webpack-plugin");

/**
 * 참고
 * 		output: https://webpack.js.org/configuration/output/
 */
module.exports = [
  {
    entry: {
      map: path.join(__dirname, "/src/map/map.ts"),
    },
    resolve: {
      extensions: [".ts", ".js"],
    },
    output: {
      path: path.resolve(__dirname, "dist"),
      library: ["kore3lab"],
      libraryTarget: "umd",
      filename: "kore3lab.[name].js",
      globalObject: "this",
    },
    module: {
      rules: [
        { test: /\.tsx?$/, use: "ts-loader", exclude: /node_modules/ },
        { test: /\.css$/, use: ["style-loader", "css-loader"] },
      ],
    },
    plugins: [
      new HtmlWebpackPlugin({
        chunks: ["map"],
        template: "./examples/map.html",
        filename: "map.html",
      }),
    ],
    devtool: "source-map",
    devServer: {
      historyApiFallback: true,
      compress: true,
      host: "0.0.0.0",
      port: 8080,
      proxy: {
        "/api/*": "http://localhost:3000/",
      },
    },
  },
];
