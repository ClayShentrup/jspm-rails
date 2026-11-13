```
   _                                   _  _
  (_) ___ _ __  _ __        _ _  __ _ (_)| | ___
  | |(_-<| '_ \| '  \  ___ | '_|/ _` || || |(_-<
 _/ |/__/| .__/|_|_|_||___||_|  \__,_||_||_|/__/
|__/     |_|
```

**Import maps for Rails, built by [jspm](https://jspm.org) from your `package-lock.json`.**

No bundler, no build step, no Node in production. Your JavaScript ships as the ES modules its authors wrote. Each module is cached on its own, and npm stays the source of truth for versions, so Dependabot keeps working.

```sh
npm install tom-select katex
bin/rails jspm:install
```

```
      traced  ./app/javascript/application.js
    vendored  31 modules from ga.jspm.io
      copied  71 assets from node_modules
       wrote  config/importmap.json
```

## Why

[importmap-rails](https://github.com/rails/importmap-rails) vendors one file per package. That works until a package imports its own internal files or depends on other packages. Then you hand-pin the whole tree, and `bin/importmap update` can't tell which versions belong together. A package spread across many modules gets split across versions, or misses files and fails in the browser.

jspm traces your code and vendors every module it reaches, whole dependency trees included. jspm-rails runs that trace at the versions npm locked and hands the result to Propshaft.

## Installation

Add the gem, and jspm's generator as a development dependency:

```sh
bundle add jspm-rails
npm install --save-dev @jspm/generator
```

Then render the tags in your layout's `<head>`:

```erb
<%= javascript_jspm_tags %>
```

That emits the import map, a `modulepreload` link for each module your entry imports statically, and the entry itself as `<script type="module">`.

## Usage

1. Install browser packages with npm, as `dependencies`. Build tools belong in `devDependencies`; jspm-rails leaves those alone.
2. Import them from `app/javascript/application.js`. Import your own modules by relative path:

   ```js
   import TomSelect from 'tom-select'
   import { setUpForms } from './forms.js'

   const { default: katex } = await import('katex')
   ```

3. Run `bin/rails jspm:install` and commit `config/importmap.json` and `vendor/jspm`.

When Dependabot, or you, changes `package-lock.json`, run the install again. To keep the two from drifting, run it in CI and fail on a diff:

```sh
bin/rails jspm:install && git diff --exit-code config/importmap.json vendor/jspm
```

### Stylesheets, fonts and images

jspm.io serves JavaScript. For everything else, jspm-rails copies the stylesheets, fonts and images of each npm dependency into `vendor/jspm/<package>/`. Propshaft serves them, and rewrites the `url()`s in each stylesheet to digested paths:

```erb
<%= stylesheet_link_tag 'katex/dist/katex' %>
```

The JavaScript comes from jspm.io and the CSS from npm. Both are at the version in `package-lock.json`, so they always match.

## How it works

`bin/rails jspm:install`:

1. Reads every non-dev package in `package-lock.json`.
2. Traces `app/javascript/application.js` with [`@jspm/generator`](https://github.com/jspm/generator), pinning each of those packages to its locked version. Only packages your code reaches end up in the map, so KaTeX's command-line dependency stays out.
3. Downloads each traced module from `ga.jspm.io`, and its source map, into `vendor/jspm/ga.jspm.io`.
4. Copies each npm dependency's stylesheets, fonts and images into `vendor/jspm`.
5. Writes jspm's import map to `config/importmap.json`, with the list of modules to preload.

`javascript_jspm_tags` rewrites the map's jspm.io URLs to Propshaft's digested paths. Propshaft renames every file to include its digest, but a module imports its siblings by their plain names. So the rendered map also sends each plain module URL to its digested one, and relative imports land on the right file.

## Warnings

The install warns when the import map can't match `package-lock.json`:

```
        warn  @orchidjs/unicode-variants: package-lock.json has 1.1.1 and 1.2.2, and the import map uses 1.1.1 everywhere
        warn  canvas-confetti isn't in package-lock.json, so its version isn't locked
```

npm can install two versions of one package when their ranges don't overlap. An import map gives each package one version per scope, so jspm-rails uses the top-level version everywhere and tells you. Check that the packages needing the other version still work, or upgrade them.

## Requirements and limits

- Rails 8 with Propshaft.
- Node and npm when you run the install, and network access to jspm.io. Production needs neither.
- One entry point: `app/javascript/application.js`.
- If `asset_host` points at another origin, that origin must send `Access-Control-Allow-Origin`, because browsers load modules and fonts across origins only with CORS.
- Untested on Windows.

## Compared to

- **importmap-rails** pins one file per package, by hand. jspm-rails traces whole dependency trees at npm's locked versions.
- **jsbundling-rails** resolves trees too, but compiles your JavaScript into a bundle. That means a watcher in development, a build in CI and deploys, and a bundle whose cache busts whenever any module in it changes. jspm-rails serves the modules as written.

## Development

```sh
bundle install
(cd spec/dummy && npm ci) && (cd spec/fixtures/conflicted && npm ci)
bundle exec rake
```

The specs install into a dummy Rails app through `bin/rails jspm:install`, then drive it in headless Chrome, so they need network access to jspm.io.

## License

[MIT](LICENSE)
