# Changelog

## 0.1.0 (unreleased)

- `bin/rails jspm:install` traces `app/javascript/application.js` with jspm and vendors every module it reaches. `config/importmap.json` locks versions, and `package-lock.json` overrides it for packages installed with npm.
- `javascript_jspm_tags` renders the import map with Propshaft's digested paths, preloads, and the entry module.
- `bin/rails jspm:check` fails when `config/importmap.json` or `vendor/jspm` is out of date.
- Warns when the import map can't match `package-lock.json`.
