#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const ORG = process.env.SF_ORG_ALIAS || 'dynamicAction';
const testsPath = 'goldens/tests.json';

function run(cmd, opts = {}) {
  console.log(`$ ${cmd}`);
  cp.execSync(cmd, { stdio: 'pipe', encoding: 'utf8', ...opts });
  return cp.execSync(cmd, { stdio: 'pipe', encoding: 'utf8', ...opts });
}

function runApexEval(name, goal) {
  // Generate a temporary Apex script that calls EvalHarness and prints JSON
  const apex = `
String out = EvalHarness.generateFromBlueprintName('${name.replace(/'/g, "\\'")}', '${goal.replace(/'/g, "\\'")}');
System.debug(out);
`;
  const tmp = `.tmp/eval-${name}.apex`;
  fs.mkdirSync('.tmp', { recursive: true });
  fs.writeFileSync(tmp, apex, 'utf8');

  // Run Apex
  const out = cp.execSync(`sf apex run -o ${ORG} -f ${tmp} --json`, { encoding: 'utf8' });
  const parsed = JSON.parse(out);

  // Extract latest DEBUG line that looks like JSON
  let jsonStr = null;
  const logs = parsed?.result?.logs || '';
  const matches = logs.match(/\{[\s\S]*\}$/m);
  if (matches) jsonStr = matches[0];

  if (!jsonStr) {
    console.error('Could not find JSON in apex run output for test:', name);
    console.error(out);
    process.exit(1);
  }
  let payload = null;
  try { payload = JSON.parse(jsonStr); } catch (e) {
    console.error('JSON parse error for test:', name, e);
    console.error(jsonStr);
    process.exit(1);
  }
  if (payload.error) {
    console.error('Harness error:', payload.error);
    process.exit(1);
  }
  return payload;
}

function listArtifacts(artifacts) {
  return Object.keys(artifacts).sort();
}

function writeArtifactsToTemp(name, artifacts) {
  const base = path.join('.tmp', 'artifacts', name);
  fs.rmSync(base, { recursive: true, force: true });
  for (const [rel, content] of Object.entries(artifacts)) {
    const full = path.join(base, rel);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, content, 'utf8');
  }
  return base;
}

function globMatch(glob, filename) {
  // very small glob: '*' matches any chars
  const re = new RegExp('^' + glob.replace(/\./g, '\\.').replace(/\*/g, '.*') + '$');
  return re.test(filename);
}

function fuzzyCheck(baseDir, checks, artifacts) {
  let ok = true;
  const errors = [];

  // Directory-level "mustExist"
  for (const dir in checks) {
    const cfg = checks[dir];
    const dirFull = path.join(baseDir, dir);
    const files = listArtifacts(artifacts).filter(f => f.startsWith(dir));

    if (cfg.mustExist) {
      for (const token of cfg.mustExist) {
        const match = files.find(f => f.includes(token));
        if (!match) {
          ok = false;
          errors.push(`Expected a file in ${dir} containing "${token}", but none found.`);
        }
      }
    }
    if (cfg.mustContain) {
      for (const glob in cfg.mustContain) {
        const patterns = cfg.mustContain[glob];
        const targets = files.filter(f => globMatch(glob, path.basename(f)));
        if (targets.length === 0) {
          ok = false;
          errors.push(`No files match pattern ${glob} under ${dir}`);
          continue;
        }
        for (const t of targets) {
          const content = artifacts[t];
          for (const p of patterns) {
            const re = new RegExp(p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')); // simple substring match
            if (!re.test(content)) {
              ok = false;
              errors.push(`File ${t} is missing required text: ${p}`);
            }
          }
        }
      }
    }
  }

  return { ok, errors };
}

function strictCompare(name, artifacts) {
  // If expected files exist for this test, compare exactly (text equality).
  const expectedBase = path.join('goldens', name, 'expected');
  if (!fs.existsSync(expectedBase)) return { used: false, ok: true, errors: [] };

  const expectedFiles = [];
  (function walk(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir)) {
      const full = path.join(dir, entry);
      const rel = path.relative(expectedBase, full);
      const stat = fs.statSync(full);
      if (stat.isDirectory()) walk(full);
      else expectedFiles.push(rel.replace(/\\/g, '/'));
    }
  })(expectedBase);

  const errors = [];
  // 1) Every expected file must exist in artifacts with exact content
  for (const rel of expectedFiles) {
    const expected = fs.readFileSync(path.join(expectedBase, rel), 'utf8');
    const got = artifacts[rel];
    if (got === undefined) {
      errors.push(`Missing generated file: ${rel}`);
      continue;
    }
    if (got !== expected) {
      errors.push(`Mismatch in ${rel}\n--- expected\n${expected}\n--- got\n${got}`);
    }
  }
  // 2) No extra files? (optional; comment out if not desired)
  // for (const rel of Object.keys(artifacts)) {
  //   if (!expectedFiles.includes(rel)) {
  //     errors.push(`Unexpected extra generated file: ${rel}`);
  //   }
  // }

  return { used: true, ok: errors.length === 0, errors };
}

function main() {
  if (!fs.existsSync(testsPath)) {
    console.error(`Missing ${testsPath}`);
    process.exit(1);
  }
  const tests = JSON.parse(fs.readFileSync(testsPath, 'utf8'));
  let failures = 0;

  for (const t of tests) {
    console.log(`\n=== Running golden: ${t.name} ===`);
    const payload = runApexEval(t.name, t.goal);
    const artifacts = payload.artifacts || {};
    const dumpBase = writeArtifactsToTemp(t.name, artifacts);
    console.log(`Generated ${Object.keys(artifacts).length} files -> ${dumpBase}`);

    // Strict compare if expected files exist
    const strict = strictCompare(t.name, artifacts);
    if (strict.used) {
      if (!strict.ok) {
        failures++;
        console.error(`❌ Strict mismatch for ${t.name}:\n- ${strict.errors.join('\n- ')}\n`);
        continue;
      } else {
        console.log(`✅ Strict match for ${t.name}`);
        continue;
      }
    }

    // Otherwise, run fuzzy checks
    if (t.checks) {
      const { ok, errors } = fuzzyCheck('', t.checks, artifacts);
      if (!ok) {
        failures++;
        console.error(`❌ Fuzzy check failed for ${t.name}:\n- ${errors.join('\n- ')}\n`);
      } else {
        console.log(`✅ Fuzzy checks passed for ${t.name}`);
      }
    } else {
      console.log('ℹ️ No checks specified; skipping validation.');
    }
  }

  if (failures > 0) {
    console.error(`\nFailures: ${failures}`);
    process.exit(1);
  }
  console.log('\nAll golden tests passed ✅');
}

main();