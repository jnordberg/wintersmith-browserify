wintersmith-browserify
======================

[browserify](https://github.com/substack/node-browserify) plugin for [wintersmith](https://github.com/jnordberg/wintersmith)


Install
-------

Using wintersmith:

`wintersmith plugin install browserify`

Manually:

`npm install --save wintersmith-browserify`

Then add `wintersmith-browserify` to your plugins list in wintersmith's `config.json`.


Options
-------

The `browserify` object in `config.json` is passed as browserify's bundle options.

In addition to browserify's standard options wintersmith-browserify adds the following:

	* `requires` - `[{"filename": ["module", {name: "module", "expose": "exposed_name"}, ..]}, ..]` - per-file bundle.require() mapping
	* `externals` - `[{"filename": ["module", ..]}, ..]` - per-file bundle.external() mapping
	* `static` - `["filename", ..]` - list of files that will only be compiled once and cached in memory for subsequent requests


Example
-------

A project with a heavy dependency can impact bundle times, this example uses requires, externals and static options to include react.js with minimal overhead.

```json
{
    "browserify": {
        "transforms": [
            "reactify",
            "coffeeify"
        ],
        "extensions": [
            ".js",
            ".coffee",
            ".jsx"
        ],
        "externals": {
            "scripts/main.jsx": ["react"]
        },
        "requires": {
            "scripts/libs.js": ["react"]
        },
        "static": ["scripts/libs.js"]
    }
}
```

`wintersmith preview` output

```
  first request
  200 /scripts/main.js BrowserifyPlugin 1899ms
  200 /scripts/libs.js BrowserifyPlugin 5299ms
  ..

  second request
  200 /scripts/libs.js BrowserifyPlugin 8ms
  200 /scripts/main.js BrowserifyPlugin 50ms
  ..
```


---

![browserify!](http://substack.net/images/browserify/browserify.png)
