var Webpack = require('webpack');
var path = require('path');
var nodeModulesPath = path.resolve(__dirname, 'node_modules');
var buildPath = path.resolve(__dirname, 'public', 'build');
var mainPath = path.resolve(__dirname, 'app', 'main.js');

var fs = require('fs');

var config = function(port) {
    return {

        // Makes sure errors in console map to the correct file
        // and line number
        devtool: 'eval',
        entry: [

            // For hot style updates
            'webpack/hot/dev-server',

            // The script refreshing the browser on none hot updates
            'webpack-dev-server/client?http://localhost:' + port,

            // Our application
            mainPath
        ],
        output: {

            // We need to give Webpack a path. It does not actually need it,
            // because files are kept in memory in webpack-dev-server, but an
            // error will occur if nothing is specified. We use the buildPath
            // as that points to where the files will eventually be bundled
            // in production
            path: buildPath,
            filename: 'bundle.js',

            // Everything related to Webpack should go through a build path,
            // localhost:3000/build. That makes proxying easier to handle
            publicPath: '/build/'
        },
        module: {

            loaders: [

                // I highly recommend using the babel-loader as it gives you
                // ES6/7 syntax and JSX transpiling out of the box
                {
                    test: /\.js$/,
                    loader: 'babel-loader',
                    exclude: [nodeModulesPath],
                    query: {
                        presets: ["es2015"]
                    }
                }, {
                    test: /\.(css|scss)$/,
                    loaders: [
                        'style-loader',
                        'css-loader',
                    ]
                }, {
                    test: /\.html$/,
                    exclude: /node_modules/,
                    loader: 'file?name=[name].[ext]',
                }, {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loader: 'elm-webpack?debug=true',
                }, {
                    test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                    loader: 'url-loader?limit=10000&mimetype=application/font-woff',
                }, {
                    test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                    loader: 'file-loader',
                },

            ]
        },

        // We have to manually add the Hot Replacement plugin when running
        // from Node
        plugins: [new Webpack.HotModuleReplacementPlugin()]
    };

};

module.exports = config;
