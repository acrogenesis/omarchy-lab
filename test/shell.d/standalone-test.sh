#!/bin/bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
test_tmp=$(mktemp -d)
trap 'rm -rf -- "$test_tmp"' EXIT
package="$test_tmp/Lab package"
mkdir -p "$package" "$test_tmp/host-runtime/bin"
cp -a "$ROOT/bin" "$ROOT/default" "$package/"
export OMARCHY_PATH="$test_tmp/host-runtime"

(
  source "$package/bin/omarchy-lab-common"
  [[ $LAB_ROOT == "$package" ]] || fail "package root with spaces"
  [[ $OMARCHY_PATH == "$test_tmp/host-runtime" ]] || fail "host Omarchy runtime was overwritten"
  [[ -f $LAB_ROOT/default/lab-vm/display-resize && -f $LAB_ROOT/default/lab-vm/display-resize.service ]] || fail "guest assets missing"
  DESKTOP_FILE="$test_tmp/desktop/lab-vm.desktop"
  write_desktop
  desktop-file-validate "$DESKTOP_FILE"
  rg -Fq "Exec=\"$package/bin/omarchy-labctl\" launch" "$DESKTOP_FILE" || fail "launcher must use the bundled controller"
  ssh_config_block lab >"$test_tmp/ssh-config"
  ssh -G -F "$test_tmp/ssh-config" omarchy-lab >"$test_tmp/ssh-effective" 2>/dev/null
  rg -q '^proxycommand .*omarchy-labctl proxy %p$' "$test_tmp/ssh-effective" || fail "SSH proxy must use the bundled controller"
  is_tty() { return 1; }
  launch_lifecycle_terminal() { [[ $1 == "$package/bin/omarchy-lab-vm" && $2 == "install" ]]; }
  have_domain() { fail "graphical setup must hand off before touching a VM"; }
  install_lab
)
pass "package relocates with spaces without changing host runtime, launcher or SSH routing"

ln -s "$package/bin/omarchy-labctl" "$test_tmp/lab-command"
"$test_tmp/lab-command" help >/dev/null
"$test_tmp/lab-command" action list --json | jq -e '.actions | length == 8' >/dev/null
if "$test_tmp/lab-command" '../unsafe'; then fail "dispatcher accepted traversal"; fi
if "$test_tmp/lab-command" doctor; then fail "doctor accepted missing Quickshell components"; fi
pass "standalone dispatcher works through a symlink and rejects unsupported hosts and commands"

run_node_test <<'JS'
const fs = require('fs')
const manifest = requireFromRoot('manifest.json')
assertEqual(manifest.id, 'acrogenesis.lab', 'standalone plugin owns a non-reserved namespace')
for (const entry of Object.values(manifest.entryPoints)) assert(fs.existsSync(path.join(root, entry)), `entry point exists: ${entry}`)
for (const file of ['Panel.qml', 'BarWidget.qml']) {
  const text = fs.readFileSync(path.join(root, file), 'utf8')
  assert(text.includes('Qt.resolvedUrl("bin/" + name)'), `${file} resolves private package commands`)
  assert(!text.includes('command: ["omarchy-lab-'), `${file} does not dispatch to native Lab commands`)
}
assert(fs.readFileSync(path.join(root, 'Panel.qml'), 'utf8').includes('Install Lab VM'), 'standalone panel exposes first-time setup')
JS
