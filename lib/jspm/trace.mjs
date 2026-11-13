// Traces the app's entry module with @jspm/generator and prints the result as
// JSON. The generator is resolved from the app's own node_modules, so the app
// pins its version in package-lock.json like any other dependency.
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { relative } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const { entry, resolutions, root } = JSON.parse(readFileSync(0, 'utf8'));
const rootUrl = pathToFileURL(`${root}/`);
const generatorPath = createRequire(rootUrl).resolve('@jspm/generator');
const { Generator } = await import(pathToFileURL(generatorPath));

const generator = new Generator({
  baseUrl: rootUrl,
  combineSubpaths: true,
  defaultProvider: 'jspm.io',
  env: ['browser', 'module', 'production'],
  flattenScopes: true,
  mapUrl: rootUrl,
  resolutions,
});

const { dynamicDeps, staticDeps } = await generator.link(entry);
const preload = staticDeps.map((url) =>
  url.startsWith('file:') ? `./${relative(root, fileURLToPath(url))}` : url
);

process.stdout.write(JSON.stringify({ dynamicDeps, map: generator.getMap(), preload, staticDeps }));
