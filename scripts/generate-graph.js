// Parses content/*.md, extracts wikilinks, outputs static/graph-data.json
import { readFileSync, writeFileSync, readdirSync, existsSync, mkdirSync } from 'fs';
import { join, basename, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONTENT_DIR = join(__dirname, '..', 'content');
const STATIC_DIR = join(__dirname, '..', 'static');
const OUTPUT_FILE = join(STATIC_DIR, 'graph-data.json');
const BASE_PATH = '/pyeong';

function parseFrontmatter(raw) {
  const m = raw.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) return { title: null, aliases: [] };
  const fm = m[1];

  const titleMatch = fm.match(/^title:\s*(.+)$/m);
  const title = titleMatch ? titleMatch[1].trim().replace(/^["']|["']$/g, '') : null;

  const aliases = [];
  const aliasBlock = fm.match(/^aliases:\s*\r?\n((?:[ \t]+-[ \t]+.+\r?\n?)*)/m);
  if (aliasBlock) {
    for (const line of aliasBlock[1].split(/\r?\n/)) {
      const a = line.match(/^\s+-\s+(.+)/);
      if (a) aliases.push(a[1].trim().replace(/^["']|["']$/g, ''));
    }
  }

  return { title, aliases };
}

function extractWikilinks(raw) {
  const links = new Set();
  const re = /\[\[([^\]|#\n]+)/g;
  let match;
  while ((match = re.exec(raw)) !== null) {
    const target = match[1].trim();
    if (target) links.add(target);
  }
  return [...links];
}

function toSlug(id) {
  if (id === 'index') return '';
  return id
    .toLowerCase()
    .replace(/ /g, '-')
    .split('')
    .map(c => (c.charCodeAt(0) > 127 ? encodeURIComponent(c) : c))
    .join('');
}

function getUrl(id) {
  const slug = toSlug(id);
  return slug ? `${BASE_PATH}/${slug}` : `${BASE_PATH}/`;
}

const files = readdirSync(CONTENT_DIR).filter(f => f.endsWith('.md'));

const nodes = [];
const nameMap = {};

for (const file of files) {
  const id = basename(file, '.md');
  const raw = readFileSync(join(CONTENT_DIR, file), 'utf8');
  const { title, aliases } = parseFrontmatter(raw);

  const idx = nodes.length;
  nodes.push({ id, title: title || id, url: getUrl(id) });

  nameMap[id] = idx;
  for (const alias of aliases) {
    if (!(alias in nameMap)) nameMap[alias] = idx;
  }
}

const links = [];
const seen = new Set();

for (const file of files) {
  const sourceId = basename(file, '.md');
  const raw = readFileSync(join(CONTENT_DIR, file), 'utf8');
  const wikilinks = extractWikilinks(raw);

  for (const target of wikilinks) {
    if (target in nameMap) {
      const targetId = nodes[nameMap[target]].id;
      const key = `${sourceId}|${targetId}`;
      if (sourceId !== targetId && !seen.has(key)) {
        seen.add(key);
        links.push({ source: sourceId, target: targetId });
      }
    }
  }
}

if (!existsSync(STATIC_DIR)) mkdirSync(STATIC_DIR, { recursive: true });

writeFileSync(OUTPUT_FILE, JSON.stringify({ nodes, links }, null, 2), 'utf8');
console.log(`graph-data.json: ${nodes.length} nodes, ${links.length} links`);
for (const n of nodes) console.log(`  [${n.id}] "${n.title}" → ${n.url}`);
