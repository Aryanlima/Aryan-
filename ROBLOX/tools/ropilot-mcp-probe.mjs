import { spawn } from 'node:child_process';
const exe = 'C:/Users/Administrator/AppData/Roaming/ropilot/bin/ropilot-infra-helper.exe';
const p = spawn(exe, ['mcp', '--ropilot-external-mcp'], { env: { ...process.env, ROPILOT_USERDATA: 'C:/Users/Administrator/AppData/Roaming/ropilot' } });
let buf = '', id = 0; const wait = new Map();
p.stdout.on('data', d => { buf += d; let i; while ((i = buf.indexOf('\n')) >= 0) { const l = buf.slice(0, i).trim(); buf = buf.slice(i + 1); if (!l) continue; try { const m = JSON.parse(l); if (m.id && wait.has(m.id)) { wait.get(m.id)(m); wait.delete(m.id); } } catch {} } });
p.stderr.on('data', d => process.stderr.write('[err] ' + String(d).slice(0, 300)));
const call = (method, params) => new Promise(r => { const i = ++id; wait.set(i, r); p.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: i, method, params }) + '\n'); setTimeout(() => r({ timeout: true }), 20000); });
const init = await call('initialize', { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'claude-code', version: '2.1' } });
console.log('INIT', JSON.stringify(init.result?.serverInfo ?? init).slice(0, 200));
p.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
const tools = await call('tools/list', {});
for (const n of ['ropilot_listchildren','ropilot_studio_screenshot']) { const t=(tools.result?.tools??[]).find(x=>x.name===n); console.log(n, JSON.stringify(t?.inputSchema?.properties ?? {}).slice(0,300), 'req', JSON.stringify(t?.inputSchema?.required ?? [])); }
const r1 = await call('tools/call', { name: 'ropilot_listchildren', arguments: { path: 'Workspace' } });
console.log('LISTCHILDREN', JSON.stringify(r1.result ?? r1).slice(0, 700));
p.kill();
