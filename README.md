```
   _                                   _  _
  (_) ___ _ __  _ __        _ _  __ _ (_)| | ___
  | |(_-<| '_ \| '  \  ___ | '_|/ _` || || |(_-<
 _/ |/__/| .__/|_|_|_||___||_|  \__,_||_||_|/__/
|__/     |_|
```

[![CI](https://github.com/ClayShentrup/jspm-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/ClayShentrup/jspm-rails/actions/workflows/ci.yml)

**Import maps for Rails, built by [jspm](https://jspm.org).**

Your JavaScript ships as the ES modules its authors wrote. There's no bundler, no build step and no Node in production, and the browser caches each module on its own. Use jspm alone, or install packages with npm too. npm then sets their versions, so Dependabot keeps working.

```sh
bin/rails jspm:install
```

```
      traced  ./app/javascript/application.js
    vendored  31 modules from ga.jspm.io
       wrote  config/importmap.json
```

## Contents

- [Why](#why)
- [Quick start](#quick-start)
- [Writing your JavaScript](#writing-your-javascript)
- [Versions: plain jspm, or npm too](#versions-plain-jspm-or-npm-too)
- [Stylesheets, fonts and images](#stylesheets-fonts-and-images)
- [Keeping up to date](#keeping-up-to-date)
- [Warnings](#warnings)
- [Deploying](#deploying)
- [How it works](#how-it-works)
- [Compared to](#compared-to)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## Why

Rails 8 ships import maps by default, through [importmap-rails](https://github.com/rails/importmap-rails). It vendors one file per package. That works until a package imports its own internal files or depends on other packages. Then you pin the whole tree by hand, and `bin/importmap update` can't tell which versions belong together. A package spread across many modules ends up split across versions, or missing files.

jspm solves that. It traces your code and finds every module your code reaches, across whole dependency trees. jspm-rails runs that trace, vendors what it finds, and hands the result to Propshaft. So you get import maps that work for any package on npm, with versions locked the way you'd expect.

## Quick start

You need Rails 8 with Propshaft, and Node with npm on your development machine.

```sh
bundle add jspm-rails
npm install --save-dev @jspm/generator
```

Render the tags in your layout's `<head>`:

```erb
<%= javascript_jspm_tags %>
```

Write `app/javascript/application.js`:

```js
import confetti from 'canvas-confetti'

confetti()
```

Install, and commit what it writes:

```sh
bin/rails jspm:install
git add config/importmap.json vendor/jspm
```

Reload the page.

## Writing your JavaScript

**The entry point is `app/javascript/application.js`.** `javascript_jspm_tags` loads it as a module, and the install traces everything it imports.

**Import packages by name,** as their documentation shows:

```js
import TomSelect from 'tom-select'
import { Controller } from '@hotwired/stimulus'
```

**Import your own modules by relative path,** with the extension:

```js
import { setUpForms } from './forms.js'
import './controllers/index.js'
```

**Import rarely used code dynamically.** The install vendors it too, but the page doesn't preload it, so the browser fetches it only when it runs:

```js
const { default: katex } = await import('katex')
```

## Versions: plain jspm, or npm too

**Plain jspm works on its own.** The install resolves each package you import from jspm.io. That's the latest version, or the newest within a range you give in `package.json`'s `dependencies`, as jspm does. `config/importmap.json` is jspm's lockfile: every install keeps the versions it already holds.

**Install a package with npm when you want more.** Its version in `package-lock.json` then overrides the import map, and you get:

- Dependabot pull requests for it.
- Its stylesheets, fonts and images in `node_modules`, at the same version as its JavaScript.

Mix the two freely. A package's JavaScript always comes from jspm.io either way. npm decides the version, not the files.

## Stylesheets, fonts and images

jspm.io serves JavaScript. For a package's other files, install it with npm and put its directory on Propshaft's load path, as Rails's generated `config/initializers/assets.rb` suggests:

```ruby
Rails.application.config.assets.paths << Rails.root.join('node_modules/katex/dist')
```

```erb
<%= stylesheet_link_tag 'katex' %>
```

Propshaft rewrites the `url()`s in the stylesheet to digested paths, so the fonts load too. The CSS comes from npm and the JavaScript from jspm.io, both at the version in `package-lock.json`.

## Keeping up to date

**npm packages:** when Dependabot, or you, changes `package-lock.json`, run `bin/rails jspm:install` again.

**Plain jspm packages:** delete the package's entries from `config/importmap.json`, then run the install. jspm resolves it afresh.

**To keep the map from drifting,** run the check in CI:

```sh
bin/rails jspm:check
```

It traces again without writing anything. It fails when an install would change `config/importmap.json`, for example after Dependabot bumps `package-lock.json`, or when a module is missing from `vendor/jspm`:

```
       stale  config/importmap.json
         run  bin/rails jspm:install
```

## Warnings

The install warns when the import map can't match `package-lock.json`:

```
        warn  @orchidjs/unicode-variants: package-lock.json has 1.1.1 and 1.2.2, and the import map uses 1.1.1 everywhere
```

npm installs two versions of a package when its dependents' ranges don't overlap. An import map gives each package one version per scope, so jspm-rails uses the top-level version everywhere and tells you. Check that the packages needing the other version still work, or upgrade them so the ranges meet.

## Deploying

- **Commit `config/importmap.json` and `vendor/jspm`.** `assets:precompile` digests the vendored modules like any other asset.
- **Production needs no Node and no jspm.io.** The one exception is stylesheets served from `node_modules`, which need `npm ci` before precompiling.
- **An `asset_host` on another origin must send `Access-Control-Allow-Origin`.** Browsers load modules and fonts across origins only with CORS.
- **Content Security Policy works.** Every tag carries the request's nonce.
- **Turbo reloads the page when the import map changes,** because the map's tag has `data-turbo-track="reload"`.

## How it works

`bin/rails jspm:install`:

1. Traces `app/javascript/application.js` with [`@jspm/generator`](https://github.com/jspm/generator). The previous `config/importmap.json` locks versions, and `package-lock.json` pins every package npm installed. Only packages your code reaches end up in the map, so KaTeX's command-line dependency stays out.
2. Downloads each traced module from jspm.io, with its source map, into `vendor/jspm/ga.jspm.io`.
3. Writes jspm's import map to `config/importmap.json`, with the list of modules to preload.

`javascript_jspm_tags` renders that map for Propshaft. Propshaft serves each file under a digested name, so the helper rewrites the map's URLs:

```json
"tom-select": "https://ga.jspm.io/npm:tom-select@2.4.3/dist/esm/tom-select.complete.js"
```

becomes

```json
"tom-select": "/assets/ga.jspm.io/npm/tom-select@2.4.3/dist/esm/tom-select.complete-c479c3ee.js"
```

A module imports its siblings by their plain names, though. When `tom-select.complete.js` imports `./constants.js`, the browser asks for `/assets/.../constants.js`, which Propshaft doesn't serve. So the rendered map also sends each plain module URL to its digested one:

```json
"/assets/ga.jspm.io/npm/tom-select@2.4.3/dist/esm/constants.js":
  "/assets/ga.jspm.io/npm/tom-select@2.4.3/dist/esm/constants-115aef3a.js"
```

That's a standard import-map feature, so nothing gets rewritten inside the files.

## Compared to

- **importmap-rails** pins one file per package, and you resolve the dependency tree by hand. jspm-rails traces the whole tree.
- **jsbundling-rails** resolves the tree too, but compiles your JavaScript into a bundle. That means a watcher in development and a build in CI and deploys. And a change to any module busts the cache for the whole bundle. jspm-rails ships the modules as written.

## FAQ

**Why vendor, instead of loading from jspm.io?**
For the reasons importmap-rails switched to vendoring in [rails/importmap-rails#217](https://github.com/rails/importmap-rails/pull/217). Under HTTP/2, every extra origin costs a connection, so serving from your own costs less. Your app also stops depending on a third party at runtime, and development works offline.

**Do I need npm at all?**
You need it to install `@jspm/generator`. Beyond that, no: plain jspm packages need nothing in `package.json`.

**Can I use TypeScript or JSX?**
Not with jspm-rails, which doesn't transpile. Use jsbundling-rails.

**Can I import a stylesheet as a module (`with { type: 'css' }`)?**
Safari doesn't support CSS module scripts yet, so link stylesheets with `stylesheet_link_tag`.

**Can I have more than one entry point?**
Not yet. Import everything from `application.js`, dynamically for code only some pages need.

**Can I use it alongside importmap-rails?**
Use one or the other. Both render the page's import map.

**Does it work on Windows?**
It's untested there.

## Troubleshooting

**`tracing ./app/javascript/application.js failed`**
Node printed the reason just above. Usually Node isn't on your `PATH`, or `@jspm/generator` isn't installed: run `npm install --save-dev @jspm/generator`.

**`Propshaft::MissingAssetError` for a file under `ga.jspm.io`**
`config/importmap.json` names a module that `vendor/jspm` doesn't have. Run `bin/rails jspm:install` and commit both.

**Modules or fonts fail to load with an asset host**
The asset host must send `Access-Control-Allow-Origin`. See [Deploying](#deploying).

**A package's stylesheet 404s**
Add its directory to `config.assets.paths`. See [Stylesheets, fonts and images](#stylesheets-fonts-and-images).

## Development

```sh
bundle install
npm ci && npx playwright install chromium
(cd spec/dummy && npm ci) && (cd spec/fixtures/conflicted && npm ci)
bundle exec rake
```

The specs install into a dummy Rails app through `bin/rails jspm:install`. Then they drive it in Chromium through Playwright, on one origin and on two, finding elements by their accessible role and name. Any JavaScript error fails the example. So they need network access to jspm.io.

Report security issues privately; see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
