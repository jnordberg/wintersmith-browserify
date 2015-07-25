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
