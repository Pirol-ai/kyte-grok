#!/bin/sh
# Does this repository actually work as a Grok marketplace?
#
# Everything happens in a throwaway HOME: Grok keeps its config, its plugins and its marketplaces
# under $HOME/.grok, and the data folder resolves under $HOME too, so neither the Grok you use nor
# a real workspace is touched. What is checked is the whole path a newcomer walks — add the
# marketplace, install the plugin, see what Grok discovered, and get an answer out of the server.
#
# Run it from anywhere:  sh check.sh
#
# It needs grok, node and kyte on the machine. The manifests alone are checked by
# `node --test tests/*.test.mjs`, which needs none of them.

set -eu

repo=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

HOME="$work/home"
mkdir -p "$HOME"
export HOME

fail() {
  echo "FAILED: $1" >&2
  exit 1
}

echo "1. the manifests"
node --test "$repo"/tests/*.test.mjs >"$work/tests.txt" 2>&1 || fail "the manifest checks do not pass
$(tail -30 "$work/tests.txt")"

echo "2. grok reads the manifest"
grok plugin validate "$repo/plugins/kyte" >"$work/validate.txt" 2>&1 ||
  fail "grok rejects the plugin manifest
$(cat "$work/validate.txt")"
grep -q 'valid' "$work/validate.txt" || fail "grok did not call the manifest valid
$(cat "$work/validate.txt")"

echo "3. the marketplace, and the install"
grok plugin marketplace add "$repo" >"$work/add.txt" 2>&1 || fail "grok would not add the marketplace
$(cat "$work/add.txt")"
grok plugin install kyte --trust >"$work/install.txt" 2>&1 || fail "the plugin would not install
$(cat "$work/install.txt")"
grep -q 'kyte' "$work/install.txt" || fail "nothing called kyte was installed
$(cat "$work/install.txt")"

echo "4. what grok discovered"
# Both halves have to be there. A plugin whose skill is not loaded is a server with no manual, and
# a plugin whose server is not loaded is a manual for tools that do not exist.
grok inspect >"$work/inspect.txt" 2>&1 || fail "grok inspect did not run"
grep -qE '^ *└ kyte +plugin: kyte' "$work/inspect.txt" ||
  fail "the skill is not among the skills grok loaded
$(sed -n '/Skills/,/^$/p' "$work/inspect.txt")"
grep -qE '^ *└ kyte \(stdio\) +plugin: kyte' "$work/inspect.txt" ||
  fail "the server is not among the MCP servers grok loaded
$(sed -n '/MCP Servers/,/^$/p' "$work/inspect.txt")"

echo "5. the server answers"
# No workspace has been opened in this throwaway HOME, so kyte serves the single tool that says
# why — which is exactly what the skill tells the model to relay.
grok mcp doctor >"$work/doctor.txt" 2>&1 || fail "grok mcp doctor did not run"
sed -n '/^  kyte /,$p' "$work/doctor.txt" | sed 's/^/   /'
grep -q 'handshake OK' "$work/doctor.txt" || fail "the server did not complete the handshake
$(cat "$work/doctor.txt")"
grep -q '0 failing' "$work/doctor.txt" || fail "a server is failing
$(cat "$work/doctor.txt")"

# Grok expands the ~ in the data folder before it starts the server, and kyte expands it too
# (0.1.1227 and newer). If both ever stop, the folder is created literally named "~" — a second,
# empty database that looks like a lost sign-in.
[ ! -e "$HOME/~" ] && [ ! -e "$repo/~" ] ||
  fail "a folder called '~' was created: nothing expanded the tilde in --db"

echo
echo "All five passed."
