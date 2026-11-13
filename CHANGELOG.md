# Changelog

## 0.1.0 (unreleased)

- `bin/rails jspm:install` traces `app/javascript/application.js` with jspm at the versions in `package-lock.json`, and vendors every module it reaches.
- `javascript_jspm_tags` renders the import map with Propshaft's digested paths, preloads, and the entry module.
- Warns when the import map can't match `package-lock.json`.
