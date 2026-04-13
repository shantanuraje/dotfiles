---
title: LiteLLM Supply Chain Attack Audit
dateCreated: 2026-03-25T20:30:00.000-04:00
dateModified: 2026-03-25T20:30:00.000-04:00
tags:
  - security
  - nixos
  - supply-chain
  - audit
  - litellm
  - python
status: open
priority: high
area: Productivity
archived: false
---

# LiteLLM Supply Chain Attack Audit — System Impact Assessment

**System**: Beelink SER8 Desktop, NixOS 26.05
**Date audited**: 2026-03-25
**Conclusion**: **NOT AFFECTED** — system has litellm 1.80.0 (safe); attack targeted 1.82.7-1.82.8 only

---

## Attack Summary (CVE-2026-33634, CVSS 9.4)

### What Happened

On **March 24, 2026**, threat actor group **TeamPCP** published backdoored versions of the `litellm` Python package to PyPI: **versions 1.82.7 and 1.82.8**. LiteLLM is a popular LLM abstraction layer with ~3.4 million downloads/day (~95 million/month).

### Attack Chain

1. **March 19**: TeamPCP compromised `trivy-action` (GitHub Action for the Trivy security scanner) by rewriting Git tags to point to a malicious release (v0.69.4)
2. LiteLLM's CI/CD pipeline used Trivy, giving attackers access to the maintainer's PyPI credentials
3. **March 24 ~10:52 UTC**: Malicious litellm 1.82.7 and 1.82.8 published to PyPI
4. **~3 hours later**: PyPI quarantined the package

### Two Injection Methods

- **Version 1.82.7 (source injection)**: Base64-encoded payload in `litellm/proxy/proxy_server.py` — executes when `litellm.proxy` is imported
- **Version 1.82.8 (.pth file)**: Added `litellm_init.pth` to `site-packages/` — fires on **every Python interpreter startup** (including pip, IDEs, scripts) with no import required

### Payload Capabilities (Three-Stage Attack)

**Stage 1 — Credential Harvester:**
- SSH private keys (`~/.ssh/`)
- `.env` files
- Cloud credentials (AWS, GCP, Azure)
- Kubernetes configs
- CI/CD secrets (Jenkins, Travis CI, Terraform)
- Docker configs
- Database credentials
- Cryptocurrency wallets
- Git credentials
- Shell history (for API keys)
- Slack and Discord webhook tokens
- `/etc/shadow` password hashes
- `/var/log/auth.log` entries
- System info: hostname, processes, network routing

**Stage 2 — Kubernetes Lateral Movement:**
- Deploys privileged pods to every node in accessible clusters

**Stage 3 — Persistent Systemd Backdoor:**
- Installs `sysmon.service` that polls attacker C2 for additional binaries
- Persists via `~/.config/systemd/user/sysmon.service`

### C2 Infrastructure
- `models[.]litellm[.]cloud` (exfiltration — NOT the official `litellm.ai`)
- `checkmarx[.]zone` (related TeamPCP infrastructure)

---

## System Audit Results

### litellm Presence on System

| Check | Result | Status |
|-------|--------|--------|
| litellm in nix store | `/nix/store/hdj09x28bgannk5nxxwv596pyf2h3864-python3.13-litellm-1.80.0` | **SAFE** (1.80.0, not affected) |
| How it got there | Dependency of `hermes-agent-2026.3.17` from `nix-ai-tools` flake | Transitive dep |
| litellm in pip/pip3 | Not installed | Clean |
| litellm in site-packages | Not found | Clean |
| litellm in any project files | Not found | Clean |
| litellm in NixOS config | Not declared directly | N/A |

### hermes-agent and nix-ai-tools

`hermes-agent` is installed via the `nix-ai-tools` flake in `system-common.nix` (line 402):
```nix
] ++ (builtins.attrValues (removeAttrs nix-ai-tools.packages.${pkgs.system} [
    # explicitly excluded packages...
])) ++ [
```

This installs **all** packages from `nix-ai-tools` except those explicitly excluded. `hermes-agent` is not excluded, so it gets installed. It depends on litellm as a Python dependency.

**Current version**: litellm **1.80.0** — this predates the compromised versions (1.82.7-1.82.8) by several releases and is **not affected**.

### Indicator of Compromise (IOC) Checks

| IOC | Check | Result |
|-----|-------|--------|
| `litellm_init.pth` in site-packages | `find / -name "litellm_init.pth"` | **NOT FOUND** |
| `~/.config/sysmon/sysmon.py` | `ls -la` | **NOT FOUND** |
| `~/.config/systemd/user/sysmon.service` | `ls -la` | **NOT FOUND** |
| `/tmp/pglog` | `ls -la` | **NOT FOUND** |
| `/tmp/.pg_state` | `ls -la` | **NOT FOUND** |
| `sysmon.service` running | `systemctl --user status sysmon` | **NOT FOUND** |
| litellm process running | `ps aux \| grep litellm` | **NOT FOUND** |
| pip cache litellm entries | `find ~/.cache/pip` | **No pip cache dir** |

### AI Packages Installed on System

From NixOS configuration and `nix-ai-tools` flake:

**Directly declared in system-common.nix:**
- `claude-desktop` — Claude Desktop app (Anthropic)
- `claude-monitor` — Usage tracking dashboard
- `kimi-cli` — Kimi Code AI coding agent
- `zeroclaw` — AI assistant infrastructure
- `opencode-desktop` — AI coding assistant (Tauri)
- `realvnc-server` — Remote access (not AI)

**From `nix-ai-tools` flake** (all packages minus excluded):
- `hermes-agent` — AI agent with tool calling (depends on litellm 1.80.0)
- Various other AI tools (specifics depend on flake contents)

**Python environment** (system-common.nix lines 420-451):
- Data science: pandas, numpy, matplotlib, plotly, dash, jupyter
- Web scraping: requests, beautifulsoup4, selenium, playwright
- Image processing: opencv4, pillow, pytesseract
- **No AI/LLM Python libraries** declared directly

---

## Risk Assessment

### Why We Are Safe

1. **Version mismatch**: System has litellm **1.80.0**, attack only affected **1.82.7-1.82.8**
2. **NixOS package isolation**: Packages are installed from nix store derivations built from nixpkgs/flake sources, not from PyPI at runtime. A compromised PyPI upload would not affect already-built nix store paths
3. **No pip installs**: No pip-managed litellm found anywhere on the system
4. **All IOC checks negative**: No backdoor files, no sysmon service, no staging files
5. **Nix store is immutable**: The `/nix/store/` path for litellm 1.80.0 is content-addressed and cannot be modified after build

### Residual Risk Considerations

| Risk | Level | Notes |
|------|-------|-------|
| Future `nix flake update` pulling affected version | **LOW** | Affected versions were yanked from PyPI; nixpkgs would need to package 1.82.7/1.82.8 specifically |
| `hermes-agent` updating its litellm dependency | **LOW** | NixOS builds from source/lockfile, not live PyPI |
| Other nix-ai-tools packages having litellm deps | **LOW** | Same nix store version (1.80.0) would be shared |
| TeamPCP targeting other packages in future | **MEDIUM** | They also compromised Trivy and Checkmarx (KICS); monitor for broader campaign |

### Recommendations

1. **No immediate action required** — system is clean
2. **Pin litellm version** in nix-ai-tools flake if possible, to prevent accidental upgrade to a compromised version
3. **After next `nix flake update`**, verify litellm version hasn't jumped to 1.82.7/1.82.8:
   ```bash
   find /nix/store -maxdepth 1 -name "*litellm*" 2>/dev/null
   ```
4. **Monitor TeamPCP campaign** — they targeted Trivy and Checkmarx first, litellm second; more packages may follow
5. **Consider excluding hermes-agent** from nix-ai-tools if it's not actively used (it showed auth errors when tested)

---

## References

- [Security Update: Suspected Supply Chain Incident | liteLLM](https://docs.litellm.ai/blog/security-update-march-2026)
- [TeamPCP Backdoors LiteLLM Versions 1.82.7-1.82.8 via Trivy CI/CD Compromise | The Hacker News](https://thehackernews.com/2026/03/teampcp-backdoors-litellm-versions.html)
- [Compromised litellm PyPI Package Delivers Multi-Stage Credential Stealer | Sonatype](https://www.sonatype.com/blog/compromised-litellm-pypi-package-delivers-multi-stage-credential-stealer)
- [How a Poisoned Security Scanner Became the Key to Backdooring LiteLLM | Snyk](https://snyk.io/articles/poisoned-security-scanner-backdooring-litellm/)
- [TeamPCP Supply Chain Attack Campaign | Arctic Wolf](https://arcticwolf.com/resources/blog/teampcp-supply-chain-attack-campaign-targets-trivy-checkmarx-kics-and-litellm-potential-downstream-impact-to-additional-projects/)
- [Popular LiteLLM PyPI package backdoored | BleepingComputer](https://www.bleepingcomputer.com/news/security/popular-litellm-pypi-package-compromised-in-teampcp-supply-chain-attack/)
- [LiteLLM TeamPCP Supply Chain Attack | Wiz Blog](https://www.wiz.io/blog/threes-a-crowd-teampcp-trojanizes-litellm-in-continuation-of-campaign)
- [GitHub Issue #24512: CRITICAL: Malicious litellm_init.pth](https://github.com/BerriAI/litellm/issues/24512)
- CVE-2026-33634 (CVSS 4.0 base score: 9.4)

---

## Appendix: Quick IOC Check Script

Run this periodically or after `nix flake update`:

```bash
#!/usr/bin/env bash
echo "=== LiteLLM / TeamPCP IOC Check ==="

echo -n "litellm versions in nix store: "
find /nix/store -maxdepth 1 -name "*litellm*" 2>/dev/null || echo "none"

echo -n "litellm_init.pth: "
find / -name "litellm_init.pth" 2>/dev/null | head -1 || echo "NOT FOUND (good)"

echo -n "sysmon backdoor: "
ls ~/.config/sysmon/sysmon.py 2>/dev/null && echo "FOUND!" || echo "NOT FOUND (good)"

echo -n "sysmon systemd service: "
systemctl --user is-active sysmon.service 2>/dev/null || echo "NOT FOUND (good)"

echo -n "C2 connections: "
ss -tn | grep -E "litellm\.cloud|checkmarx\.zone" 2>/dev/null && echo "FOUND!" || echo "none (good)"

echo -n "Staging files: "
ls /tmp/pglog /tmp/.pg_state 2>/dev/null && echo "FOUND!" || echo "NOT FOUND (good)"

echo "=== Check complete ==="
```
