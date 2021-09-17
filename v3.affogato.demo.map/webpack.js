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
      library: ["cloudbarista"],
      libraryTarget: "umd",
      filename: "cloudbarista.[name].js",
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
        template: "./html/index.html",
        filename: "index.html",
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
