#!/usr/bin/env python3
"""
Analyze ALL Claude Code conversation data from ~/.claude/
Reads both history.jsonl (index) and all conversation .jsonl files.
Usage:
  python3 analyze-claude-history.py           # Summary
  python3 analyze-claude-history.py --all     # All user messages
  python3 analyze-claude-history.py --recent 50  # Recent N messages
  python3 analyze-claude-history.py --full    # Deep analysis with conversation files
"""

import json
import sys
import os
from collections import Counter
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
HISTORY_FILE = CLAUDE_DIR / "history.jsonl"
PROJECTS_DIR = CLAUDE_DIR / "projects"


def load_jsonl(path):
    entries = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        entries.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass
    except (IOError, PermissionError):
        pass
    return entries


def extract_user_messages_from_conversation(jsonl_path):
    """Extract human/user messages from a conversation JSONL file."""
    entries = load_jsonl(jsonl_path)
    user_msgs = []
    for entry in entries:
        entry_type = entry.get("type", "")

        # Claude Code format: type=user with message.content
        if entry_type == "user":
            message = entry.get("message", {})
            content = message.get("content", "")
            if isinstance(content, str) and content.strip():
                user_msgs.append(content)
            elif isinstance(content, list):
                for block in content:
                    if isinstance(block, dict):
                        text = block.get("text", "")
                        if text and text.strip():
                            user_msgs.append(text)
                    elif isinstance(block, str) and block.strip():
                        user_msgs.append(block)

        # Also try legacy format: role=human
        elif entry.get("role") == "human":
            content = entry.get("content", "")
            if isinstance(content, str) and content.strip():
                user_msgs.append(content)

    return user_msgs


def categorize(msg):
    ml = msg.lower()
    checks = [
        ('NixOS/System Config', ['nixos', 'nix ', 'configuration.nix', 'deploy', 'rebuild', 'flake', 'package', 'systemd', 'systemctl']),
        ('Obsidian Vault', ['obsidian', 'vault', 'journal', 'inbox', 'frontmatter', 'yaml', 'para', 'daily note']),
        ('Desktop/WM Config', ['polybar', 'awesome', 'eww', 'hyprland', 'waybar', 'rofi', 'picom', 'widget', 'bar ', 'theme']),
        ('Git Operations', ['commit', 'git ', 'push', 'branch', 'diff', 'rebase', 'merge']),
        ('VNC/Remote Access', ['vnc', 'realvnc', 'remote desktop']),
        ('Chezmoi/Dotfiles', ['chezmoi', 'dotfile']),
        ('Debugging/Fixing', ['debug', 'error', 'fix', 'broken', 'not working', 'issue', 'problem', 'failing', 'crash']),
        ('Documentation', ['document', 'readme', 'update doc', 'guide']),
        ('Research/Planning', ['research', 'plan', 'architect', 'design', 'evaluate', 'analyze', 'compare', 'learn']),
        ('Software/Tool Setup', ['install', 'setup', 'zeroclaw', 'claude', 'opencode', 'tool', 'configure']),
        ('Coding/Development', ['plugin', 'typescript', 'function', 'class', 'implement', 'script', 'api', 'endpoint']),
        ('File Operations', ['read', 'file', 'create', 'write', 'edit', 'search', 'find', 'list', 'show']),
        ('Continuation/Confirm', ['continue', 'resume', 'proceed', '/login', '/exit', '/model', '/usage', '/plan', 'yes', ' ok']),
    ]
    for cat, keywords in checks:
        if any(w in ml for w in keywords):
            return cat
    return 'Other'


def daemon_complexity(msg):
    """What model tier would this task need if handled by ZeroClaw?"""
    ml = msg.lower()
    # CHEAP: read-only queries, monitoring, simple responses
    if any(w in ml for w in ['status', 'health', 'list', 'show', 'check', 'what', 'search',
                              'uptime', 'disk', 'memory', 'service', 'yes', 'ok', 'remind',
                              'schedule', 'cron', 'morning']):
        return 'CHEAP'
    # MID: file writes, vault management, debugging
    if any(w in ml for w in ['create', 'move', 'update', 'process', 'write', 'edit',
                              'fix', 'error', 'debug', 'broken']):
        return 'MID'
    # SMART: complex reasoning, code gen, architecture
    if any(w in ml for w in ['research', 'plan', 'architect', 'design', 'implement',
                              'code', 'function', 'deep', 'analyze', 'evaluate']):
        return 'SMART'
    return 'CHEAP'  # Default to cheap for simple/ambiguous messages


def main():
    print("=" * 70)
    print("CLAUDE CODE CONVERSATION ANALYSIS")
    print("=" * 70)

    # === Part 1: History index ===
    history_entries = load_jsonl(HISTORY_FILE)
    print(f"\n[history.jsonl] Total conversation starters: {len(history_entries)}")

    projects = Counter()
    for e in history_entries:
        proj = e.get('project', 'unknown').replace('/home/shantanu/', '~/')
        projects[proj] += 1
    print("\nConversations by project:")
    for proj, count in projects.most_common():
        print(f"  {count:3d}  {proj}")

    # === Part 1b: Extract display text from history.jsonl (conversation starters) ===
    history_messages = [e.get('display', '') for e in history_entries if e.get('display', '').strip()]
    print(f"\n  Conversation starters with text: {len(history_messages)}")

    # === Part 2: Deep conversation analysis ===
    all_conversation_files = list(PROJECTS_DIR.rglob("*.jsonl"))
    main_convos = [f for f in all_conversation_files if 'subagents' not in str(f)]
    subagent_convos = [f for f in all_conversation_files if 'subagents' in str(f)]

    print(f"\n[Conversation files]")
    print(f"  Main conversations: {len(main_convos)}")
    print(f"  Subagent sessions:  {len(subagent_convos)}")
    print(f"  Total JSONL files:  {len(all_conversation_files)}")

    # Extract all user messages from ALL conversation files (main + subagent)
    all_user_messages = []
    msg_by_project = {}
    msg_by_file = {}  # Track messages per conversation file
    total_entries = 0
    total_size_bytes = 0

    for f in all_conversation_files:  # Process ALL files, not just main
        entries = load_jsonl(f)
        total_entries += len(entries)
        total_size_bytes += f.stat().st_size

        # Determine project from path
        rel = str(f.relative_to(PROJECTS_DIR))
        proj_dir = rel.split('/')[0].replace('-home-shantanu-', '~/').replace('-', '/')
        if proj_dir.startswith('~/'):
            pass
        else:
            proj_dir = '~/' + proj_dir

        user_msgs = extract_user_messages_from_conversation(f)
        all_user_messages.extend(user_msgs)
        msg_by_file[f.name] = user_msgs

        if proj_dir not in msg_by_project:
            msg_by_project[proj_dir] = []
        msg_by_project[proj_dir].extend(user_msgs)

    print(f"\n  Total message entries (all roles): {total_entries}")
    print(f"  Total user messages extracted: {len(all_user_messages)}")
    print(f"  Total conversation data: {total_size_bytes / 1024 / 1024:.1f} MB")

    # === Part 3: Task categorization ===
    print(f"\n{'=' * 70}")
    print("TASK CATEGORY ANALYSIS")
    print(f"{'=' * 70}")

    categories = Counter()
    complexity = Counter()
    for msg in all_user_messages:
        if len(msg.strip()) > 3:  # Skip tiny messages
            categories[categorize(msg)] += 1
            complexity[daemon_complexity(msg)] += 1

    total_cat = sum(categories.values())
    print(f"\nTask categories ({total_cat} meaningful messages):")
    for cat, count in categories.most_common():
        pct = count / total_cat * 100 if total_cat > 0 else 0
        print(f"  {count:3d} ({pct:4.1f}%)  {cat}")

    # === Part 4: Model tier analysis ===
    print(f"\n{'=' * 70}")
    print("MODEL TIER REQUIREMENTS (for ZeroClaw daemon)")
    print(f"{'=' * 70}")

    total_comp = sum(complexity.values())
    tier_info = {
        'CHEAP': 'Read-only queries, monitoring, simple responses',
        'MID': 'File writes, vault management, light debugging',
        'SMART': 'Complex reasoning, code generation, deep analysis',
    }
    for tier in ['CHEAP', 'MID', 'SMART']:
        count = complexity[tier]
        pct = count / total_comp * 100 if total_comp > 0 else 0
        print(f"  {tier:6s}: {count:3d} ({pct:4.1f}%)  -- {tier_info[tier]}")

    print(f"\n  NOTE: SMART tasks are typically done interactively by you with Claude.")
    if total_comp > 0:
        print(f"  ZeroClaw daemon handles mostly CHEAP + MID tasks (~{(complexity['CHEAP']+complexity['MID'])/total_comp*100:.0f}% of workload).")

    # === Part 5: Message length analysis ===
    print(f"\n{'=' * 70}")
    print("MESSAGE LENGTH ANALYSIS (token estimation)")
    print(f"{'=' * 70}")

    lengths = [len(m.split()) for m in all_user_messages if m.strip()]
    if lengths:
        avg_words = sum(lengths) / len(lengths)
        med_words = sorted(lengths)[len(lengths) // 2]
        max_words = max(lengths)
        short = sum(1 for l in lengths if l < 20)
        medium = sum(1 for l in lengths if 20 <= l < 100)
        long_msgs = sum(1 for l in lengths if l >= 100)
        print(f"  Average message length: {avg_words:.0f} words (~{avg_words*1.3:.0f} tokens)")
        print(f"  Median message length:  {med_words} words (~{med_words*1.3:.0f} tokens)")
        print(f"  Max message length:     {max_words} words (~{max_words*1.3:.0f} tokens)")
        print(f"  Short (<20 words):      {short} ({short/len(lengths)*100:.0f}%)")
        print(f"  Medium (20-100 words):  {medium} ({medium/len(lengths)*100:.0f}%)")
        print(f"  Long (100+ words):      {long_msgs} ({long_msgs/len(lengths)*100:.0f}%)")

    # === Part 6: User messages by project ===
    if "--all" in sys.argv or "--messages" not in sys.argv:
        print(f"\n{'=' * 70}")
        print(f"ALL USER MESSAGES ({len(all_user_messages)} total from {len(all_conversation_files)} conversation files)")
        print(f"{'=' * 70}")
        for i, msg in enumerate(all_user_messages):
            if msg.strip():
                display = msg[:500].replace('\n', ' \\n ')
                print(f"\n[{i+1}] {display}")

    if "--recent" in sys.argv:
        n = 50
        idx = sys.argv.index("--recent")
        if idx + 1 < len(sys.argv):
            try:
                n = int(sys.argv[idx + 1])
            except ValueError:
                pass
        print(f"\n{'=' * 70}")
        print(f"RECENT {n} USER MESSAGES")
        print(f"{'=' * 70}")
        for msg in all_user_messages[-n:]:
            if msg.strip():
                print(f"  - {msg[:200]}")

    # === Part 6b: Print all messages if requested ===
    if "--messages" in sys.argv:
        print(f"\n{'=' * 70}")
        print(f"ALL USER MESSAGES FROM CONVERSATION FILES ({len(all_user_messages)} total)")
        print(f"{'=' * 70}")
        for i, msg in enumerate(all_user_messages, 1):
            if msg.strip():
                # Truncate very long messages but show enough
                display = msg[:500].replace('\n', ' \\n ')
                print(f"\n[{i:3d}] {display}")

        print(f"\n{'=' * 70}")
        print(f"HISTORY.JSONL CONVERSATION STARTERS ({len(history_messages)} total)")
        print(f"{'=' * 70}")
        for i, msg in enumerate(history_messages, 1):
            display = msg[:300].replace('\n', ' \\n ')
            print(f"[{i:3d}] {display}")

    # === Part 7: Per-conversation stats ===
    print(f"\n{'=' * 70}")
    print("PER-CONVERSATION STATISTICS")
    print(f"{'=' * 70}")

    convo_stats = []
    for f in all_conversation_files:  # ALL conversations
        entries = load_jsonl(f)
        user_msgs = extract_user_messages_from_conversation(f)
        assistant_msgs = sum(1 for e in entries if e.get('type') == 'assistant')
        tool_calls = sum(1 for e in entries if e.get('type') == 'tool_result' or e.get('type') == 'tool_use')
        total_user_tokens_est = sum(len(m.split()) * 1.3 for m in user_msgs)
        convo_stats.append({
            'file': f.name,
            'total_entries': len(entries),
            'user_msgs': len(user_msgs),
            'assistant_msgs': assistant_msgs,
            'tool_calls': tool_calls,
            'user_tokens_est': int(total_user_tokens_est),
            'size_kb': f.stat().st_size / 1024,
        })

    if convo_stats:
        user_msg_counts = [c['user_msgs'] for c in convo_stats]
        entry_counts = [c['total_entries'] for c in convo_stats]
        token_counts = [c['user_tokens_est'] for c in convo_stats]
        sizes = [c['size_kb'] for c in convo_stats]

        print(f"  Conversations analyzed: {len(convo_stats)}")
        print(f"")
        print(f"  Messages per conversation:")
        print(f"    User messages:     avg={sum(user_msg_counts)/len(user_msg_counts):.1f}  min={min(user_msg_counts)}  max={max(user_msg_counts)}  median={sorted(user_msg_counts)[len(user_msg_counts)//2]}")
        print(f"    Total entries:     avg={sum(entry_counts)/len(entry_counts):.1f}  min={min(entry_counts)}  max={max(entry_counts)}  median={sorted(entry_counts)[len(entry_counts)//2]}")
        print(f"")
        print(f"  Token estimates (user input only):")
        print(f"    Per conversation:  avg={sum(token_counts)/len(token_counts):.0f}  min={min(token_counts)}  max={max(token_counts)}  median={sorted(token_counts)[len(token_counts)//2]}")
        print(f"    Total across all:  {sum(token_counts):,} tokens")
        print(f"")
        print(f"  Conversation sizes:")
        print(f"    Per conversation:  avg={sum(sizes)/len(sizes):.0f}KB  min={min(sizes):.0f}KB  max={max(sizes):.0f}KB")
        print(f"    Total:             {sum(sizes)/1024:.1f} MB")
        print(f"")
        print(f"  Top 10 largest conversations:")
        for c in sorted(convo_stats, key=lambda x: -x['total_entries'])[:10]:
            print(f"    {c['total_entries']:5d} entries  {c['user_msgs']:3d} user msgs  {c['user_tokens_est']:6d} est tokens  {c['size_kb']:.0f}KB  {c['file']}")

    # === Summary stats ===
    print(f"\n{'=' * 70}")
    print("SUMMARY STATISTICS")
    print(f"{'=' * 70}")
    print(f"  History entries (conversation starters): {len(history_entries)}")
    print(f"  Main conversation files:                 {len(main_convos)}")
    print(f"  Subagent session files:                  {len(subagent_convos)}")
    print(f"  Total JSONL entries parsed:               {total_entries}")
    print(f"  User messages extracted:                  {len(all_user_messages)}")
    print(f"  Total conversation data size:             {total_size_bytes / 1024 / 1024:.1f} MB")
    print(f"  Projects with conversations:              {len(msg_by_project)}")
    print(f"\n  User messages per project:")
    for proj, msgs in sorted(msg_by_project.items(), key=lambda x: -len(x[1])):
        print(f"    {len(msgs):4d}  {proj}")


if __name__ == "__main__":
    main()
