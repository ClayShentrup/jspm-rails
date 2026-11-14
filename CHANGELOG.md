# Changelog

## 0.2.0 (unreleased)

- Reads Yarn 1's `yarn.lock` as well as `package-lock.json`.
- Copies stylesheets, fonts and images only from the `node_modules` directories named in `config.jspm.asset_directories`, instead of from every dependency.

## 0.1.0 (2026-11-13)

- `bin/rails jspm:install` traces `app/javascript/application.js` with jspm and vendors every module it reaches. It copies npm dependencies' stylesheets, fonts and images. `config/importmap.json` locks versions, and `package-lock.json` overrides it for packages installed with npm.
- `javascript_jspm_tags` renders the import map with Propshaft's digested paths, preloads, and the entry module.
- Modules on Propshaft's load path, including engines', are importable by asset name, the way importmap-rails pins work.
- Modules on Propshaft's load path, including engines', are importable by asset name, the way importmap-rails pins work.
- `bin/rails jspm:check` fails when `config/importmap.json` or `vendor/jspm` is out of date.
- Warns when the import map can't match `package-lock.json`.
