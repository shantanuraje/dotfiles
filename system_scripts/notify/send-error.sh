#!/usr/bin/env bash
# send-error.sh — generic systemd OnFailure handler.
#
# Designed to be used as `OnFailure=send-error@%n.service` (template) or by a
# fixed wrapper. Posts unit name + last 10 journal lines to the `errors` topic.
#
# Usage:
#   send-error.sh <unit-name>
#
# When invoked as a systemd OnFailure handler with %n, the unit name is the
# triggering unit (including .service suffix).

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

unit="${1:?need unit name}"
host="$(hostname)"

# Last 10 lines from the failing unit's journal — gives context without flooding.
log_tail="$(journalctl -u "$unit" --no-pager --lines=10 --output=short 2>/dev/null \
            | tail -10 \
            || echo '(no log lines available)')"

notify::alert errors \
    "💥 Unit failed: ${unit}" \
    "**Host**: ${host}

\`\`\`
${log_tail}
\`\`\`" \
    -t boom,bug \
    -m
