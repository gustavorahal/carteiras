const { environment } = require('@rails/webpacker')

// See https://www.timdisab.com/installing-bootstrap-4-on-rails-6/

const webpack = require('webpack')
environment.plugins.append('Provide',
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        Popper: ['popper.js', 'default']
    })
)

module.exports = environment
