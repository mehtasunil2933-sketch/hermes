#!/bin/bash
# Installs / repairs Hermes on the persistent volume. Called from zerops.yaml initCommands.
# Always exits 0 so a failed install never fails the deploy; read the log instead:
#   /mnt/vol/hermes/logs/init-install.log
LOG=/mnt/vol/hermes/logs/init-install.log
H=/mnt/vol/hermes/hermes-agent/.hermes/bin/hermes
mkdir -p /mnt/vol/hermes/logs
exec > >(tee -a "$LOG") 2>&1

# Zerops runs initCommands with a minimal environment; the installer needs these.
export HOME=/home/zerops USER=zerops LOGNAME=zerops SHELL=/bin/bash
mkdir -p "$HOME"

# If anything sends us SIGTERM, log who is running instead of dying silently.
trap 'echo "!!! SIGTERM received at $(date -u)"; ps -eo pid,ppid,pgid,cmd | head -40' TERM

echo "===== hermes-init $(date -u) ====="

if [ -f /mnt/vol/hermes/hermes-agent/.hermes-bootstrap-complete ] && "$H" --version >/dev/null 2>&1; then
  echo "hermes already installed: $("$H" --version 2>&1 | head -1)"
else
  echo "--- running official installer"
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh -o /tmp/hermes-install.sh
  # own session/process group, so nothing it does can signal this script
  setsid bash /tmp/hermes-install.sh --skip-browser --skip-computer-use --non-interactive --verbose < /dev/null
  echo "INSTALLER EXIT CODE: $?"
fi

if [ -x "$H" ]; then
  echo "--- adding extras (messaging, daytona)"
  # --extra and --without cannot be combined in one pm call
  setsid "$H" pm install --extra messaging --extra daytona < /dev/null
  echo "PM INSTALL (extras) EXIT CODE: $?"
  setsid "$H" pm install --without cua-driver --without agent-browser < /dev/null
  echo "PM INSTALL (without) EXIT CODE: $?"
else
  echo "hermes binary missing at $H - skipping extras"
fi

echo "===== hermes-init done $(date -u) ====="
exit 0
