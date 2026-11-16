# kyte for Grok

**kyte** is the company OS by [Pirol Labs](https://pirol.ai): customers, contacts, deals, projects,
hours, invoices, goals, people and the company's documents, in one workspace. This repository is a
marketplace for [Grok Build](https://docs.x.ai/build/overview) with one plugin in it, which serves
that workspace to Grok — ask which projects still have unbilled hours, book three hours on an
implementation, look up who is out next week.

Grok works **as you**: it sees exactly what your role in kyte may see and changes only what your
role may change.

## What you need

The **kyte command line**, version 0.1.1227 or newer, installed and signed in once:

1. Install it — macOS and Linux: `curl -fsSL https://updates.pirol.ai/cli/install.sh | sh`
   ([what the installer does](https://kyte.pirol.ai/docs/en/mcp/)). `kyte --version` says whether
   it is already there.
2. Sign in for this plugin's own folder: `kyte login --db ~/.kyte/grok`

The folder is this connection's own copy of the workspace, kept apart from any kyte session you
run in a terminal, so the two never compete for one database. kyte expands the leading `~`
itself — that is what the version floor is for; an older kyte would open a folder literally
named `~`.

## Install

```
grok plugin marketplace add Pirol-ai/kyte-grok
grok plugin install kyte
```

Then start a new Grok session: the server is connected at session start, so a running session does
not pick it up. `grok mcp doctor kyte` says whether it came up.

## Use it

Ask in plain words: *"Which projects for Meyer GmbH still have unbilled hours?"*, *"Book three
hours on the Northwind implementation for today"*, *"Who is out next week?"*. Grok looks things up
with the kyte tools before it answers and says afterwards what it changed.

The plugin carries two halves, and both matter: the **server**, which is where the tools come
from, and the **skill**, which is how to work in a kyte workspace — look before you answer, name a
record before you delete it, never report a change that did not happen.

## Another folder

`~/.kyte/grok` is this plugin's folder. To use another one, add the server by hand in
`~/.grok/config.toml`, where your own entry wins over the plugin's:

```toml
[mcp_servers.kyte]
command = "kyte"
args = ["mcp", "--db", "~/.kyte/grok"]
startup_timeout_sec = 60
```

On Windows, name the program in full:
`command = "%LOCALAPPDATA%\\Programs\\kyte\\kyte.exe"`.

## What it runs, sends and stores

- **Runs:** the `kyte` program on your own computer, as `kyte mcp`. Nothing is downloaded at
  install time and nothing is executed on your behalf.
- **Sends:** what Grok reads through these tools goes to Grok's model, as with any tool you use
  there. kyte itself keeps your workspace in step with **your company's kyte team server**, run by
  your company itself or by Pirol on its behalf in German data centres. This plugin sends nothing
  anywhere else.
- **Stores:** an encrypted local copy of your workspace in the data folder. Every change Grok makes
  is recorded in kyte as made by an agent on your behalf.
- **Never:** builds apps or extensions, runs commands, or reads your files — only the data tools of
  your kyte workspace exist for it.

## Checking it

`node --test tests/*.test.mjs` checks the manifests alone and runs on every pull request: that
every path leads somewhere, that the server line and the prose name the same folder, and that the
skill carries no installer pipeline.

`sh check.sh` walks the real path in a throwaway `GROK_HOME` and a throwaway `HOME`, so neither
your Grok nor your workspace is touched: it adds this marketplace, installs the plugin, looks at
the server Grok registered, and talks to that server. It needs `grok`, `node` and `kyte` on the
machine. `node scripts/mcp-probe.mjs` is the last step on its own — it starts the server straight
from `.mcp.json` and prints the tools it serves, without Grok.

## Support

Questions and problems: [github.com/Pirol-ai/kyte-grok/issues](https://github.com/Pirol-ai/kyte-grok/issues).
Documentation: [kyte.pirol.ai/docs/en/mcp/](https://kyte.pirol.ai/docs/en/mcp/) ·
Privacy: [pirol.ai/privacy](https://pirol.ai/privacy) · Terms: [pirol.ai/terms](https://pirol.ai/terms)

## License

MIT — see [LICENSE](LICENSE). The licence covers this plugin; the kyte program it starts is
licensed separately.
