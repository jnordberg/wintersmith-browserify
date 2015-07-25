wintersmith-browserify examples
-------------------------------

### Quick Start

- `cd examples/basic`
- `wintersmith build`
- `cd build`
- `python -m SimpleHTTPServer`
- `open http://localhost:8000`

You will need to `npm install` inside the root of the plugin directory if you
have not already. Also, if you don't have `open`, just open the path in your
browser.


### Details

This folder contains the examples for the wintersmith-browserify plugin that
demonstrate how the plugin works and a few different options for configuration.

Run the examples by navigating to one of the example subfolders (start with
basic) and running `wintersmith build`. You will get a local build folder with
the generated output where you can see the results of that particular
configuration.

Each example has its on subfolder, with the content and templates at the top
shared between all of the examples (they are symlinked into each folder).
Effectively, each example subfolder acts like a regular wintersmith install
with a local config, contents, and templates folder. This results in a file
structure something like this:

```
- examples
  |- contents -- this holds
  |- templates -- this holds the templates
  |- <example-name>
     |- config.json -- the config for this example
     |- symlink to contents
     |- symlink to templates
```


### Examples


#### Basic
The basic example has no special configuration (everything is the default). All
of the .js and .coffee files are compiled and browserified and the end result is
a working build with the various included files contributing messages to the
'log' output div.


#### Custom Extension
The custom-extension example uses the `extensions` option to only process files
with names like 'xyz.browserify.js'. This can be particularly helpful when
working with external libraries that don't play nicely with browserify, allowing
you to exactly specify which files are processed and which are not via a
prominent naming scheme. Unlike the basic example, this config results in a
broken build but you can inspect the various files to confirm that only
'test.browserify.js' was processed.


#### Specific Path
The specific-path example uses the `fileGlob` option to *only* send .js files
inside scripts/prod through the build process and browserify. This results in a
broken build (since the main.js and everything else above prod are not properly
browserified). You can manually inspect `scripts/prod/prod_only.js` and
`scripts/prod/nested/nested.js` to see that they were in fact converted.
