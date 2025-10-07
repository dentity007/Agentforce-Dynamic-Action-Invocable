#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const blueprintsDir = path.join(projectRoot, 'blueprints');
const staticResourceDir = path.join(projectRoot, 'force-app', 'main', 'default', 'staticresources');
const outputFile = path.join(staticResourceDir, 'BlueprintLibrary.resource');

const files = fs
  .readdirSync(blueprintsDir)
  .filter((file) => file.toLowerCase().endsWith('.json'))
  .sort();

if (files.length === 0) {
  console.error('No blueprint JSON files found in', blueprintsDir);
  process.exit(1);
}

const entries = files.map((file) => {
  const fullPath = path.join(blueprintsDir, file);
  const raw = fs.readFileSync(fullPath, 'utf8');
  try {
    const parsed = JSON.parse(raw);
    if (!parsed.name) {
      throw new Error(`Blueprint ${file} is missing required field 'name'.`);
    }
    return parsed;
  } catch (err) {
    console.error(`Failed to parse ${file}:`, err.message);
    process.exit(1);
  }
});

fs.mkdirSync(staticResourceDir, { recursive: true });
fs.writeFileSync(outputFile, JSON.stringify(entries, null, 2));
console.log(`Wrote ${entries.length} entries to ${outputFile}`);
