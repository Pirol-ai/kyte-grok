#!/bin/sh
# Does this repository actually work as a Grok marketplace?
#
# Everything happens in a throwaway HOME: Grok keeps its config, its plugins and its marketplaces
# under $HOME/.grok, and kyte opens its data folder under $HOME too, so neither the Grok you use
# nor a real workspace is touched. What is checked is the whole path a newcomer walks — add the
# marketplace, install the plugin, see the server registered, and get an answer out of it.
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

echo "0. the manifests"
node --test "$repo"/tests/*.test.mjs >"$work/tests.txt" 2>&1 || fail "the manifest checks do not pass
$(tail -30 "$work/tests.txt")"

echo "1. the marketplace"
grok plugin marketplace add "$repo" >"$work/add.txt" 2>&1 || fail "grok would not add the marketplace
$(cat "$work/add.txt")"
grep -q 'kyte-grok' "$work/add.txt" || fail "the marketplace is not called kyte-grok
$(cat "$work/add.txt")"

echo "2. the install"
grok plugin install kyte --trust >"$work/install.txt" 2>&1 || fail "the plugin would not install
$(cat "$work/install.txt")"

grok plugin list >"$work/list.txt" 2>&1 || fail "grok plugin list did not run"
grep -q 'kyte' "$work/list.txt" || fail "the plugin is not installed
$(cat "$work/list.txt")"

echo "3. the server Grok registered"
grok mcp list >"$work/servers.txt" 2>&1 || fail "grok mcp list did not run"
grep -q 'kyte' "$work/servers.txt" || fail "no kyte server was registered
$(cat "$work/servers.txt")"
grep -q 'mcp --db\|"mcp", "--db"\|mcp, --db' "$work/servers.txt" ||
  fail "the server is not started as 'kyte mcp --db …'
$(cat "$work/servers.txt")"

echo "4. the answer"
# No workspace has been opened in this throwaway HOME, so the one tool kyte serves is the one that
# says why — which is exactly what the skill tells the model to relay.
node "$repo/scripts/mcp-probe.mjs" >"$work/probe.txt" 2>&1 || fail "the server did not answer
$(cat "$work/probe.txt")"
sed 's/^/   /' "$work/probe.txt"
grep -q 'kyte_status' "$work/probe.txt" ||
  fail "without a workspace the server should offer kyte_status and nothing else
$(cat "$work/probe.txt")"

# A folder literally named ~ means a kyte older than 0.1.1227, which left the tilde alone.
[ ! -e "$repo/~" ] && [ ! -e "$work/~" ] ||
  fail "a folder called '~' was created: this kyte does not expand the tilde in --db"

echo
echo "All five passed."
