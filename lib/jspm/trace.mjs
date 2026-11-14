// Traces the app's entry module with @jspm/generator and prints the result as
// JSON. The generator is resolved from the app's own node_modules, so the app
// pins its version in package-lock.json like any other dependency.
//
// Ruby speaks file paths and jspm speaks URLs, so local files cross this
// boundary as absolute paths.
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

const { entries, inputMap, resolutions, root } = JSON.parse(readFileSync(0, 'utf8'));
const rootUrl = pathToFileURL(`${root}/`);
const generatorPath = createRequire(rootUrl).resolve('@jspm/generator');
const { Generator } = await import(pathToFileURL(generatorPath));

const toUrl = (target) => (target.startsWith('/') ? pathToFileURL(target).href : target);
const toPath = (target) => {
  const url = new URL(target, rootUrl);
  return url.protocol === 'file:' ? fileURLToPath(url) : url.href;
};
const mapEntries = (specifiers, convert) =>
  Object.fromEntries(Object.entries(specifiers).map(([name, target]) => [name, convert(target)]));
const mapScopes = (scopes, convert) =>
  Object.fromEntries(
    Object.entries(scopes).map(([scope, specifiers]) => [convert(scope), mapEntries(specifiers, convert)])
  );

const generator = new Generator({
  baseUrl: rootUrl,
  combineSubpaths: true,
  defaultProvider: 'jspm.io',
  env: ['browser', 'module', 'production'],
  flattenScopes: true,
  inputMap: { imports: mapEntries(inputMap.imports, toUrl), scopes: mapScopes(inputMap.scopes, toUrl) },
  inputPins: false,
  mapUrl: rootUrl,
  resolutions,
});

const { dynamicDeps, staticDeps } = await generator.link(entries);
const map = generator.getMap();

process.stdout.write(
  JSON.stringify({
    dynamicDeps: dynamicDeps.map(toPath),
    imports: mapEntries(map.imports ?? {}, toPath),
    scopes: mapScopes(map.scopes ?? {}, toPath),
    staticDeps: staticDeps.map(toPath),
  })
);
