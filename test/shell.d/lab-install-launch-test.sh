#!/bin/bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
source "$ROOT/bin/omarchy-lab-install-launch"
test_tmp=$(mktemp -d)
trap 'if [[ -f $test_tmp/installer-pid ]]; then kill "$(cat "$test_tmp/installer-pid")" 2>/dev/null || true; fi; rm -rf -- "$test_tmp"' EXIT
export XDG_RUNTIME_DIR="$test_tmp/runtime" LAB_INSTALL_TEST_DIR="$test_tmp"
mkdir -p "$XDG_RUNTIME_DIR" "$test_tmp/Lab package/bin"
LAB_ROOT="$test_tmp/Lab package"
cat >"$LAB_ROOT/bin/omarchy-lab-vm" <<'SH'
#!/bin/bash
[[ $1 == "install" && -t 0 && -t 1 ]] || exit 2
echo "$$" >"$LAB_INSTALL_TEST_DIR/installer-pid"
exec sleep 30
SH
chmod +x "$LAB_ROOT/bin/omarchy-lab-vm"

(
  launch_lifecycle_terminal() {
    local command
    printf -v command '%q ' "$@"
    script -q -e -c "$command" /dev/null
  }
  SECONDS=0
  launch_installer >"$test_tmp/result"
  ((SECONDS < 5)) || fail "launch waited for installation completion"
  [[ -f $test_tmp/installer-pid ]] || fail "terminal did not enter the installer"
  kill -0 "$(cat "$test_tmp/installer-pid")" || fail "installer died after handoff"
  rg -q 'Installer opened' "$test_tmp/result" || fail "missing startup acknowledgement"
)
pass "real PTY startup acknowledges before installer exit, with spaces in package path"

(
  launch_lifecycle_terminal() { echo 'terminal launcher unavailable' >&2; return 7; }
  if launch_installer >"$test_tmp/output" 2>"$test_tmp/error"; then fail "launch failure reported success"; fi
  rg -q 'terminal launcher unavailable' "$test_tmp/error" || fail "launcher error was lost"
)
pass "terminal launch failure is propagated with actionable error"

(
  launch_lifecycle_terminal() { return 0; }
  sleep() { command sleep 0.001; }
  if launch_installer >"$test_tmp/output" 2>"$test_tmp/error"; then fail "early launcher exit counted as readiness"; fi
  rg -q 'did not become ready' "$test_tmp/error" || fail "missing bounded timeout error"
)
pass "launcher success without a terminal times out instead of dismissing the panel"

(
  launch_lifecycle_terminal() { "$@"; }
  if launch_installer >"$test_tmp/output" 2>"$test_tmp/error"; then fail "non-terminal process counted as readiness"; fi
)
[[ -z $(ls -A "$XDG_RUNTIME_DIR") ]] || fail "startup handshake files leaked"
pass "non-TTY launch rejected and private handshake files cleaned up"

run_node_test <<'JS'
const fs = require('fs')
const vm = require('vm')
const panel = fs.readFileSync(path.join(root, 'Panel.qml'), 'utf8')
const names = ['openInstaller', 'runCommand', 'actionFailedToStart']
const context = {
  busy: false, actionProc: {running: false}, armedAction: '', confirmTimer: {stop() {}},
  errorText: '', actionOutput: '', stderrText: '', actionLabel: '', closeAfterAction: false,
  labCommand: name => '/plugin/bin/' + name
}
vm.createContext(context)
for (const name of names) {
  const match = panel.match(new RegExp('  function ' + name + '\\([^]*?\\n  }'))
  assert(match, `${name} exists`)
  vm.runInContext(match[0], context)
}
context.openInstaller()
assert(context.busy, 'launch is immediately busy')
assertEqual(context.actionLabel, 'Opening installer', 'launch state has a clear label')
assert(context.closeAfterAction, 'successful readiness dismisses the panel')
assertEqual(context.actionProc.command[0], '/plugin/bin/omarchy-lab-install-launch', 'uses readiness helper')
context.actionProc.command = ['sentinel']
context.openInstaller()
assertEqual(context.actionProc.command[0], 'sentinel', 'double click cannot start another process')
context.actionProc.running = false
context.actionFailedToStart()
assert(!context.busy && !context.closeAfterAction && context.errorText, 'spawn failure unlocks retry without closing')
context.openInstaller()
assertEqual(context.errorText, '', 'retry clears stale error')
assert(panel.includes('root.installerOpening ? "Opening installer…" : "Install Lab VM"'), 'button reflects launch state')
assert(panel.includes('visible: root.inlineInstallError'), 'launch error shown beside button')
assert(panel.includes('visible: root.errorText !== "" && !root.inlineInstallError'), 'launch error is not duplicated in global banner')
assert(panel.includes('else if (root.closeAfterAction) root.dismiss()'), 'only successful exit dismisses')
JS
