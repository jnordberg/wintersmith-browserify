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

Set as the `browserify` object in your wintersmith `config.json`.

Name                 | Default                 | Description
-------------------: |------------------------ | --------------------------------------
`ignore`             | `[]`                    | files to ignore `["filename", ..]`
`transforms`         | `["coffeeify"]`         | list of transform modules to can be in the format `[["module", {"some": "option"}], ..]` to pass options to transforms
`plugins`            | `[]`                    | list of browserify plugin modules, same format as transforms
`requires`           | `[]`                    | per-file bundle.require() mapping - `[{"filename": ["module", {name: "module", "expose": "exposed_name"}, ..]}, ..]`
`externals`          | `[]`                    | per-file bundle.external() mapping - `[{"filename": ["module", ..]}, ..]`
`static`             | `[]`                    | list of files that will only be compiled once and cached in memory for subsequent requests - `["filename", ..]`
`extensions`         | `[".js", ".coffee"]`    | list of file extensions for matching files - used for finding files in wintersmith and is passed on as the extensions option to browserify
`fileGlob`           | `"**/*.*(extensions)"`  | file matching glob - provides more powerful control over files matched, e.g. `"my/files/*.js"`
`staticLibs`         | `[]`                    | static libraries added to separate bundle - for heavy dependencies that increase bundle times. you must include the static libs bundle for it to work, see below.
`staticLibsFilename` | `"scripts/libs.js"`     | path where the static library bundle will be served. the bundle is also in the content tree as `contents.browserifyLibs`

See https://github.com/substack/node-browserify#usage for more details.


Example
-------

A project with a heavy dependency can impact bundle times, you can move heavy dependencies out to a separate file that is bundled only once and then cached.

```json
{
    "browserify": {
        "staticLibs": ["d3"],
        "staticLibsFilename": "js/libs.js"
    }
}
```

Or if you need more control, the same thing can be achieved using the externals, requires and static options.

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


Tips and Tricks
---------------

[Sometimes](https://github.com/jnordberg/wintersmith-browserify/issues/3) you
only want to browserify specific files or folders instead of all of a particular
file type. You can control exactly which files (and extension options) get
passed to browserify with the `extensions` option. Any file extension listed
here is matched by wintersmith and by browserify - for example, you can use
the `extensions` option with '.coffee' to require('./foo') and have it resolve
foo.coffee.

By default, the `fileGlob` parameter is simply built from the `extensions` list,
but you can manually set a fileGlob for even more control of the wintersmith
matching side. Keep in mind that the `extensions` option is left unchanged (and
is passed as an option to browserify).


##### FileGlob / Extensions Examples:

Only process 'filename.js.browserify' files using the `extensions` option:
```
    "browserify": {
        "extensions": [
            ".js.browserify"
        ],
        ...
    }
```

Only process .js files in (or under) the 'scripts/prod' folder using the `fileGlob` option:
```
    "browserify": {
        "fileGlob": "scripts/prod/**/*js",
        ...
    }
```



---

![browserify!](http://substack.net/images/browserify/browserify.png)
