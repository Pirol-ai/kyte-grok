// The parts of this repository that a pull request can check without Grok and without kyte.
//
// check.sh proves the real thing — marketplace, install, connection — but it needs both programs
// on the machine. These checks need neither, so they run on every pull request and catch what
// actually goes wrong in a manifest: a path that points nowhere, a data folder that drifts apart
// between the server line and the prose, and a skill the catalog's own rules would reject.

import { test } from "node:test";
import assert from "node:assert";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const read = (...parts) => readFileSync(join(root, ...parts), "utf8");
const readJson = (...parts) => JSON.parse(read(...parts));

const PLUGIN = join("plugins", "kyte");

test("the marketplace points at a plugin that is there", () => {
  const marketplace = readJson(".grok-plugin", "marketplace.json");
  assert.strictEqual(marketplace.name, "kyte-grok");

  const entries = marketplace.plugins ?? [];
  assert.strictEqual(entries.length, 1, "one plugin, or the readme is wrong");

  const [entry] = entries;
  assert.strictEqual(entry.name, "kyte");
  assert.strictEqual(entry.source.type, "local");
  assert.ok(
    existsSync(join(root, entry.source.path, ".grok-plugin", "plugin.json")),
    `${entry.source.path} holds no plugin manifest`,
  );
});

test("every path in the plugin manifest leads somewhere", () => {
  const manifest = readJson(PLUGIN, ".grok-plugin", "plugin.json");
  assert.strictEqual(manifest.name, "kyte");
  assert.match(manifest.version, /^\d+\.\d+\.\d+$/);

  for (const path of [manifest.skills, manifest.mcpServers, manifest.logo]) {
    assert.ok(path, "the manifest leaves out a path the plugin needs");
    assert.ok(existsSync(join(root, PLUGIN, path)), `${path} does not exist`);
  }

  // A folder that exists but holds no SKILL.md leaves Grok with "Skills (None)" and no complaint
  // anywhere — the plugin installs, the server runs, and the model is simply never told how to
  // work in a kyte workspace.
  const skills = readdirSync(join(root, PLUGIN, manifest.skills), { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .filter((entry) => existsSync(join(root, PLUGIN, manifest.skills, entry.name, "SKILL.md")));
  assert.ok(skills.length > 0, `${manifest.skills} holds no skill`);
});

test("the server is started as kyte mcp on its own folder", () => {
  const { mcpServers } = readJson(PLUGIN, ".mcp.json");
  assert.deepStrictEqual(Object.keys(mcpServers), ["kyte"]);

  const server = mcpServers.kyte;
  assert.strictEqual(server.type, "stdio");
  assert.strictEqual(server.command, "kyte");
  assert.deepStrictEqual(server.args, ["mcp", "--db", "~/.kyte/grok"]);

  // The handshake opens an encrypted replica, which takes longer than Grok's default 30 s on a
  // cold start. Nothing says so when it is too short: the server is simply dropped.
  //
  // The tilde is left for Grok to expand, which it does before it starts the server. kyte expands
  // it a second time (0.1.1227 and newer) should it ever arrive unexpanded.
  assert.ok(server.startup_timeout_sec >= 60, "the server gets too little time to come up");
});

test("the server, the skill and the readme name the same folder", () => {
  const { mcpServers } = readJson(PLUGIN, ".mcp.json");
  const inServer = mcpServers.kyte.args.at(-1);
  assert.match(inServer, /^~\/\.kyte\//, `no ~ data folder in the server line: ${inServer}`);

  for (const file of [join(PLUGIN, "skills", "kyte", "SKILL.md"), "README.md"]) {
    const folders = new Set(
      [...read(file).matchAll(/--db (~\/[\w./-]+?)[`\s]/g)].map((match) => match[1]),
    );
    assert.deepStrictEqual(
      folders,
      new Set([inServer]),
      `${file} sends the person to a different folder than the server opens`,
    );
  }
});

test("the skill is one Grok can read", () => {
  const skill = read(PLUGIN, "skills", "kyte", "SKILL.md");
  assert.match(skill, /^---\nname: kyte\n/, "the front matter does not name the skill");
  assert.ok(/^description: .{40,}/m.test(skill), "the skill does not say when to use it");
});

// xAI reviews submissions for supply-chain risk and names `curl … | sh` as arbitrary code
// execution; the Hermes skill gate blocks the same line outright. The install belongs in the
// documentation the skill points at, not in text handed to an agent.
test("the skill asks nobody to pipe a script into a shell", () => {
  const skill = read(PLUGIN, "skills", "kyte", "SKILL.md");
  assert.doesNotMatch(skill, /curl[^\n]*\|\s*(ba)?sh/, "the skill carries an installer pipeline");
  assert.match(skill, /kyte\.pirol\.ai\/docs/, "the skill does not say where the installer is");
});

// Grok suggests a plugin from its keywords and domains. Generic words ("crm", "database") fire
// that suggestion on unrelated work, which is the most common reason a submission is sent back.
test("the keywords and domains are ours, not generic", () => {
  const manifest = readJson(PLUGIN, ".grok-plugin", "plugin.json");
  const entry = readJson(".grok-plugin", "marketplace.json").plugins[0];

  for (const keywords of [manifest.keywords, entry.keywords]) {
    assert.ok(keywords.length > 0, "no keywords at all");
    for (const keyword of keywords) {
      assert.match(keyword, /kyte|pirol|company os/i, `"${keyword}" is not ours`);
    }
  }
  for (const domain of entry.domains) {
    assert.match(domain, /(^|\.)pirol\.ai$/, `${domain} is not a domain we own`);
  }
});
