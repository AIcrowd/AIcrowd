const ExtractTextPlugin = require('extract-text-webpack-plugin')
const { env } = require('../configuration.js')

module.exports = {
  test:  /\.(scss|sass|css)$/i,
  use: [
    'style-loader',
    {
      loader: 'css-loader',
      options: {
        url: false,
        modules: {
          auto: true,
          localIdentName: '[local]--[hash:base64:5]',
        },
      },
    },
    'sass-loader',
  ],
  // include: require('../../../app/javascript'),
}