#!/usr/bin/env bash
# Central notification library — posts to the self-hosted ntfy server on tailnet.
#
# Usage:
#   source "$(dirname "$0")/lib.sh"
#   notify::send <topic> <title> <message> [flags]
#
# Flags:
#   -p, --priority   <min|low|default|high|urgent|1..5>   Default: default
#   -t, --tags       <csv>                                Emoji slugs render as emojis
#   -c, --click      <url>                                Tap action — http(s)/obsidian://intent://...
#   -i, --icon       <url>                                64-128px image, shown next to title
#   -m, --markdown                                        Render body as Markdown (web full, Android partial, iOS limited)
#   -A, --attach     <url>                                Server fetches & re-serves; default 3h expiry
#   -F, --filename   <name>                               Display name for attachment
#   -D, --delay      <30min|9am|2026-04-27T08:00|unix>    Schedule for future delivery (max 3 days)
#   -E, --email      <addr>                               Forward as email (requires server SMTP config)
#   -N, --no-cache                                        Cache: no — only deliver to live subscribers
#   -a, --action     <type|label|url[|k=v[;k=v...]]>      Repeatable, max 3 actions
#                                                          types: view | http | broadcast
#                                                          field separator: PIPE (|)  — URLs contain colons, so : doesn't work
#                                                          kv separator:    SEMICOLON (;) — JSON bodies contain commas
#   --auth-token     <env-var-name>                       Read Bearer token from named env var
#
# Action mini-DSL examples:
#   -a "view|Open dashboard|https://grafana.local/|clear=true"
#   -a "http|Run GC|http://beelink:9099/action/run-gc|method=POST;headers.Authorization=Bearer $T;clear=true"
#   -a "broadcast|Snooze 4h||intent=net.dinglisch.android.tasker.ACTION_TASK;extras.task=NtfySnooze4h"
#
# All notifications travel over Tailscale. No auth required — tailnet is the boundary.
#
# See: system_scripts/notify/topics.md, docs/system/ntfy Advanced Features Reference.md

# Server configuration (override via env if publishing from another tailnet host).
: "${NTFY_HOST:=beelink-ser8-desktop}"
: "${NTFY_PORT:=8090}"
: "${NTFY_BASE_URL:=http://${NTFY_HOST}:${NTFY_PORT}}"
: "${NTFY_WEBHOOK_BASE:=http://${NTFY_HOST}:9099}"

# notify::send <topic> <title> <message> [flags]
notify::send() {
    local topic="$1" title="$2" message="$3"
    shift 3 || { echo "notify::send: need topic, title, message" >&2; return 2; }

    local priority="default" tags="" click="" icon="" markdown=""
    local attach="" filename="" delay="" email="" nocache=""
    local token_env=""
    local -a actions=()

    while (( $# )); do
        case "$1" in
            -p|--priority)   priority="$2";   shift 2 ;;
            -t|--tags)       tags="$2";       shift 2 ;;
            -c|--click)      click="$2";      shift 2 ;;
            -i|--icon)       icon="$2";       shift 2 ;;
            -m|--markdown)   markdown=1;      shift   ;;
            -A|--attach)     attach="$2";     shift 2 ;;
            -F|--filename)   filename="$2";   shift 2 ;;
            -D|--delay)      delay="$2";      shift 2 ;;
            -E|--email)      email="$2";      shift 2 ;;
            -N|--no-cache)   nocache=1;       shift   ;;
            -a|--action)     actions+=("$2"); shift 2 ;;
            --auth-token)    token_env="$2";  shift 2 ;;
            *) echo "notify::send: unknown flag $1" >&2; return 2 ;;
        esac
    done

    (( ${#actions[@]} > 3 )) && {
        echo "notify::send: max 3 actions (got ${#actions[@]})" >&2
        return 2
    }

    local auth_header=""
    if [[ -n "$token_env" ]]; then
        local tok="${!token_env-}"
        [[ -n "$tok" ]] && auth_header="Authorization: Bearer ${tok}"
    fi

    # Decide path: header-mode (fast, simple) vs JSON-mode (structured).
    # JSON-mode is required when actions/delay/email are set, since these
    # are awkward to express in shorthand headers.
    local use_json=0
    (( ${#actions[@]} )) && use_json=1
    [[ -n "$delay" || -n "$email" ]] && use_json=1

    if (( use_json )); then
        notify::_send_json "$topic" "$title" "$message" \
            "$priority" "$tags" "$click" "$icon" "$markdown" \
            "$attach" "$filename" "$delay" "$email" "$nocache" \
            "$auth_header" "${actions[@]}"
    else
        notify::_send_headers "$topic" "$title" "$message" \
            "$priority" "$tags" "$click" "$icon" "$markdown" \
            "$attach" "$filename" "$nocache" "$auth_header"
    fi
}

# Header-mode publish — simple cases.
notify::_send_headers() {
    local topic="$1" title="$2" message="$3"
    local priority="$4" tags="$5" click="$6" icon="$7" markdown="$8"
    local attach="$9" filename="${10}" nocache="${11}" auth_header="${12}"

    local -a h=( -fsS --max-time 5
        -H "Title: ${title}"
        -H "Priority: ${priority}"
    )
    [[ -n "$tags"     ]] && h+=( -H "Tags: ${tags}" )
    [[ -n "$click"    ]] && h+=( -H "Click: ${click}" )
    [[ -n "$icon"     ]] && h+=( -H "Icon: ${icon}" )
    [[ -n "$markdown" ]] && h+=( -H "Markdown: yes" )
    [[ -n "$attach"   ]] && h+=( -H "Attach: ${attach}" )
    [[ -n "$filename" ]] && h+=( -H "Filename: ${filename}" )
    [[ -n "$nocache"  ]] && h+=( -H "Cache: no" )
    [[ -n "$auth_header" ]] && h+=( -H "$auth_header" )

    curl "${h[@]}" -d "${message}" "${NTFY_BASE_URL}/${topic}" >/dev/null \
        || { echo "notify::send: header POST to ${NTFY_BASE_URL}/${topic} failed" >&2; return 1; }
}

# JSON-mode publish — structured fields (actions, delay, email).
# Builds payload via jq for safe escaping, posts to base URL with topic in body.
notify::_send_json() {
    local topic="$1" title="$2" message="$3"
    local priority="$4" tags="$5" click="$6" icon="$7" markdown="$8"
    local attach="$9" filename="${10}" delay="${11}" email="${12}" nocache="${13}"
    local auth_header="${14}"
    shift 14
    local -a actions=( "$@" )

    # Map priority names to integers (ntfy accepts both, but JSON expects int)
    local pri_int=3
    case "$priority" in
        min)     pri_int=1 ;;
        low)     pri_int=2 ;;
        default) pri_int=3 ;;
        high)    pri_int=4 ;;
        urgent)  pri_int=5 ;;
        [1-5])   pri_int="$priority" ;;
    esac

    local actions_json
    actions_json="$(notify::_actions_json "${actions[@]}")"

    local payload
    payload=$(jq -nc \
        --arg topic "$topic" \
        --arg title "$title" \
        --arg msg   "$message" \
        --argjson pri "$pri_int" \
        --arg tags  "$tags" \
        --arg click "$click" \
        --arg icon  "$icon" \
        --arg attach "$attach" \
        --arg fn    "$filename" \
        --arg delay "$delay" \
        --arg email "$email" \
        --argjson md "${markdown:-0}" \
        --argjson nc "${nocache:-0}" \
        --argjson actions "$actions_json" '
        { topic: $topic, title: $title, message: $msg, priority: $pri }
        + ( if $tags  != "" then { tags:    ($tags|split(",")) } else {} end )
        + ( if $click != "" then { click:   $click   } else {} end )
        + ( if $icon  != "" then { icon:    $icon    } else {} end )
        + ( if $attach!= "" then { attach:  $attach  } else {} end )
        + ( if $fn    != "" then { filename: $fn     } else {} end )
        + ( if $delay != "" then { delay:   $delay   } else {} end )
        + ( if $email != "" then { email:   $email   } else {} end )
        + ( if $md    == 1  then { markdown: true    } else {} end )
        + ( if $nc    == 1  then { cache:   "no"     } else {} end )
        + ( if ($actions|length) > 0 then { actions: $actions } else {} end )')

    local -a h=( -fsS --max-time 5
        -H "Content-Type: application/json"
    )
    [[ -n "$auth_header" ]] && h+=( -H "$auth_header" )

    curl "${h[@]}" -d "$payload" "${NTFY_BASE_URL}/" >/dev/null \
        || { echo "notify::send: JSON POST failed (payload: $payload)" >&2; return 1; }
}

# Parse the action mini-DSL into a JSON array.
# Spec format: <type>|<label>|<url>|<k=v>;<k=v>...
#   - type: view | http | broadcast
#   - label: button text
#   - url:   target URL (empty for broadcast)
#   - rest:  key=value pairs joined by semicolon, supports dotted nesting
#           (headers.Authorization=Bearer xyz becomes nested {"headers":{"Authorization":"Bearer xyz"}})
#           special keys: method, body, intent, clear, headers.X, extras.X
#
# Why pipe (|)? URLs contain colons (http://, :port) so `:` would split URLs.
# Why semicolon (;) for kvs? JSON bodies contain commas so `,` would split JSON.
# `key=value` is split on the FIRST `=` only — values can contain `=`.
notify::_actions_json() {
    local out="[]"
    local spec
    for spec in "$@"; do
        local type label url rest
        IFS='|' read -r type label url rest <<< "$spec"
        out=$(jq -c \
            --arg t "$type" \
            --arg l "$label" \
            --arg u "$url" \
            --arg r "$rest" '
            def split_kv: capture("^(?<k>[^=]+)=(?<v>.*)$");
            . + [
                ({ action: $t, label: $l }
                 + ( if $u != "" then { url: $u } else {} end )
                 + ( if $r != "" then
                       ( $r | split(";") | map(split_kv) | map(
                           if (.k | startswith("headers.")) then
                             {"headers": {(.k | sub("^headers\\."; "")): .v}}
                           elif (.k | startswith("extras.")) then
                             {"extras":  {(.k | sub("^extras\\.";  "")): .v}}
                           elif .k == "clear" then
                             {"clear": (.v == "true")}
                           else
                             {(.k): .v}
                           end)
                         | reduce .[] as $kv ({}; . * $kv) )
                     else {} end )
                )
            ]' <<< "$out")
    done
    echo "$out"
}

# ── Convenience severity wrappers ──────────────────────────────────────────
notify::info()  { local t="$1" T="$2" M="$3"; shift 3; notify::send "$t" "$T" "$M" -p low     "$@"; }
notify::ok()    { local t="$1" T="$2" M="$3"; shift 3; notify::send "$t" "$T" "$M" -p default -t white_check_mark "$@"; }
notify::warn()  { local t="$1" T="$2" M="$3"; shift 3; notify::send "$t" "$T" "$M" -p high    -t warning          "$@"; }
notify::alert() { local t="$1" T="$2" M="$3"; shift 3; notify::send "$t" "$T" "$M" -p urgent  -t rotating_light   "$@"; }
notify::error() { local t="$1" T="$2" M="$3"; shift 3; notify::send "$t" "$T" "$M" -p high    -t x,bug            "$@"; }

# ── Action helpers ─────────────────────────────────────────────────────────
# Build an http-action spec that targets the local webhook receiver.
# The webhook receiver authenticates via Bearer token from $NTFY_WEBHOOK_TOKEN.
#
# Usage:
#   spec=$(notify::action_webhook "Run GC" run-gc "$REASON_JSON_OR_EMPTY")
#   notify::send disk "Title" "Msg" -a "$spec"
notify::action_webhook() {
    local label="$1" action_name="$2" body="${3:-}"
    local token="${NTFY_WEBHOOK_TOKEN:-}"
    [[ -z "$token" ]] && {
        echo "notify::action_webhook: NTFY_WEBHOOK_TOKEN unset" >&2
        return 1
    }
    local spec="http|${label}|${NTFY_WEBHOOK_BASE}/action/${action_name}|method=POST;headers.Authorization=Bearer ${token};clear=true"
    if [[ -n "$body" ]]; then
        # Include Content-Type so the receiver knows to parse the body as JSON.
        # Without this, Android sends the body but our parser sees no "json"
        # in Content-Type and ignores it, leading to empty params at dispatch.
        spec+=";headers.Content-Type=application/json;body=${body}"
    fi
    echo "$spec"
}

# Build a view-action spec for opening a URL.
notify::action_view() {
    local label="$1" url="$2" clear="${3:-true}"
    echo "view|${label}|${url}|clear=${clear}"
}

# Build a broadcast-action spec (Android only — silent on iOS).
notify::action_broadcast() {
    local label="$1" intent="$2" extras="${3:-}"
    # extras input is expected to use ; as separator already (e.g. "extras.task=Foo;extras.dur=10")
    local spec="broadcast|${label}||intent=${intent}"
    [[ -n "$extras" ]] && spec+=";${extras}"
    echo "$spec"
}

# ── CLI mode ────────────────────────────────────────────────────────────────
# Direct invocation: ./lib.sh <topic> <title> <message> [flags]
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    notify::send "$@"
fi
