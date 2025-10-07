#!/usr/bin/env node
const fs = require('fs');
const cp = require('child_process');

const [, , inputPath, alias='dynamicAction'] = process.argv;
const raw = fs.readFileSync(inputPath, 'utf8');

// try to parse pure JSON first
let parsed = null;
try { parsed = JSON.parse(raw); } catch {}

// if it's SF CLI --json output, try to find the debug JSON inside
function extractArtifacts(obj) {
  const candidate = obj?.result?.artifacts || obj?.artifacts || null;
  if (candidate) return candidate;
  const logs = obj?.result?.logs;
  if (typeof logs === 'string') {
    // find last {..."artifacts":{...}...} block
    const m = logs.match(/\{[\s\S]*"artifacts"\s*:\s*\{[\s\S]*?\}[\s\S]*\}/g);
    if (m && m.length) {
      try { return JSON.parse(m[m.length - 1]).artifacts; } catch {}
    }
  }
  return null;
}

let artifacts = extractArtifacts(parsed);

// as a fallback, scan raw text
if (!artifacts) {
  const m = raw.match(/\{[\s\S]*"artifacts"\s*:\s*\{[\s\S]*?\}[\s\S]*\}/g);
  if (m && m.length) {
    try { artifacts = JSON.parse(m[m.length - 1]).artifacts; } catch {}
  }
}
if (!artifacts) {
  console.error('Could not find artifacts JSON in input.');
  process.exit(1);
}

const outDir = '.tmp/generated';
fs.rmSync(outDir, { recursive: true, force: true });
for (const [rel, content] of Object.entries(artifacts)) {
  const full = `${outDir}/${rel}`;
  fs.mkdirSync(full.substring(0, full.lastIndexOf('/')), { recursive: true });
  fs.writeFileSync(full, content);
}
cp.execSync(`sf project deploy start -o ${alias} -p ${outDir}`, { stdio: 'inherit' });
console.log('Deployed generated artifacts from DynamicActionPipeline.');
