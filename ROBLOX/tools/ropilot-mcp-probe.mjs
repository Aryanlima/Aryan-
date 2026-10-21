// Llama UNA herramienta de Ropilot por stdio (sin reiniciar Claude). Uso:
//   node ROBLOX/tools/ropilot-mcp-probe.mjs list
//   node ROBLOX/tools/ropilot-mcp-probe.mjs <herramienta> '{"path":"game.Workspace"}'
// Las imágenes devueltas se guardan en ROBLOX/.toolchain/ropilot/. Cada llamada puede gastar "acciones" de Ropilot.
import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';
const home = process.env.APPDATA.split(String.fromCharCode(92)).join('/') + '/ropilot';
const p = spawn(home + '/bin/ropilot-infra-helper.exe', ['mcp', '--ropilot-external-mcp'], { env: { ...process.env, ROPILOT_USERDATA: home } });
let buf = '', id = 0; const wait = new Map();
p.stdout.on('data', d => { buf += d; let i; while ((i = buf.indexOf('\n')) >= 0) { const l = buf.slice(0, i).trim(); buf = buf.slice(i + 1); try { const m = JSON.parse(l); if (m.id && wait.has(m.id)) { wait.get(m.id)(m); wait.delete(m.id); } } catch {} } });
const call = (method, params, ms = 120000) => new Promise(r => { const i = ++id; wait.set(i, r); p.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: i, method, params }) + '\n'); setTimeout(() => r({ timeout: true }), ms); });
const init = await call('initialize', { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'claude-code', version: '2.1' } });
p.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
const [name, args] = [process.argv[2] ?? 'list', JSON.parse(process.argv[3] ?? '{}')];
if (name === 'list') { for (const t of (await call('tools/list', {})).result?.tools ?? []) console.log('-', t.name); }
// Metodo MCP crudo: initialize | prompts/list | prompts/get | resources/list | resources/read | tools/list
else if (name === 'initialize') console.log(JSON.stringify(init.result, null, 1));
else if (name.includes('/')) console.log(JSON.stringify((await call(name, args)).result ?? 'sin resultado', null, 1));
else {
  const r = await call('tools/call', { name, arguments: args });
  mkdirSync('ROBLOX/.toolchain/ropilot', { recursive: true });
  let n = 0;
  for (const c of r.result?.content ?? []) {
    if (c.type === 'image') { const f = `ROBLOX/.toolchain/ropilot/${name}-${++n}.png`; writeFileSync(f, Buffer.from(c.data, 'base64')); console.log('IMAGEN', f); }
    else console.log((c.text ?? '').slice(0, 1500));
  }
  if (r.timeout) console.log('TIMEOUT');
}
p.kill();
