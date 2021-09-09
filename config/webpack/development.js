// Note: You must restart bin/webpack-dev-server for changes to take effect

const merge = require('webpack-merge')
const sharedConfig = require('./shared.js')
const { settings, output } = require('./configuration.js')

module.exports = merge(sharedConfig, {
  devtool: 'cheap-eval-source-map',

  stats: {
    errorDetails: true
  },

  output: {
    pathinfo: true
  },

  devServer: {
    client: {
      logging: 'none',
    },
    https: settings.dev_server.https,
    host: settings.dev_server.host,
    port: settings.dev_server.port,
    static: {
      publicPath: output.publicPath,
      directory: output.path,
    },
    compress: true,
    headers: { 'Access-Control-Allow-Origin': '*' },
    historyApiFallback: true,
  },
  watchOptions: {
    ignored: /node_modules/
  }
})
