# Tailscale VPN Setup on NixOS

## Overview

Tailscale is a mesh VPN built on WireGuard that creates a private network (tailnet) between your devices. Unlike traditional VPNs that route ALL traffic through a tunnel (which can break internet access), Tailscale is an **overlay network** — it only handles traffic between your tailnet devices. Normal internet traffic is completely unaffected.

**Primary use case**: VNC into the home NixOS beelink from an Android tablet (bVNC) — whether at home, at work, or anywhere else — without exposing any ports to the public internet.

---

## Networking Theory — Understanding What's Happening

### IP Addresses: Public vs Private vs Tailscale

Every device on the internet has an **IP address** — a number that identifies it on a network. There are three types relevant here:

**Public IP** (e.g., `72.45.120.88`): Assigned by your ISP. This is how the internet sees your home network. Your router has one public IP, and all devices behind it share it via NAT (Network Address Translation). This IP can be scanned, attacked, and reveals your approximate location.

**Private/LAN IP** (e.g., `192.168.1.100`): Used inside your home/work network. Devices on the same LAN can reach each other via these IPs, but they're NOT reachable from the internet. Common ranges: `192.168.x.x`, `10.x.x.x`, `172.16-31.x.x`.

**Tailscale CGNAT IP** (e.g., `100.64.1.5`): A special private IP range (`100.64.0.0/10`) that Tailscale assigns to each device. These IPs are:
- Stable (they never change, even if you switch WiFi networks)
- Not routable on the public internet (nobody can reach them from outside)
- Only reachable by other devices authenticated to your tailnet

### How Devices Find Each Other Across Networks (NAT Traversal)

The fundamental problem: Your beelink is behind your home router's NAT. Your tablet at work is behind the work router's NAT. Neither knows the other's LAN IP, and neither is directly reachable from the internet.

**Traditional solution**: Port forwarding — you configure your home router to forward port 5901 to the beelink. This WORKS but **exposes VNC to the entire internet**. Anyone who finds your public IP can try to connect. Very dangerous.

**Tailscale's solution**: NAT traversal (hole-punching) + DERP relay fallback:

```
Step 1: Both devices register with Tailscale's coordination server
        ┌─── Beelink tells server: "My public IP is 72.45.120.88, NAT port 41641"
        └─── Tablet tells server:  "My public IP is 98.22.55.30, NAT port 41641"

Step 2: Coordination server tells each device where the other is

Step 3: Both devices simultaneously send UDP packets to each other's public IP:port
        This "punches a hole" in both NATs — the routers think it's a reply to
        outgoing traffic, so they allow it through

Step 4: Direct peer-to-peer WireGuard tunnel is established
        ┌────────────────────────────────────────────────┐
        │ Beelink ←──── encrypted WireGuard ────→ Tablet │
        │ 100.64.1.5                         100.64.1.6  │
        └────────────────────────────────────────────────┘
```

If NAT traversal fails (some corporate firewalls block UDP entirely), Tailscale falls back to **DERP relay servers**:

```
Beelink ──HTTPS──→ DERP relay server ──HTTPS──→ Tablet
                   (port 443, same as
                    regular web traffic)
```

DERP relays:
- Use HTTPS (port 443) — almost never blocked by firewalls
- Are end-to-end encrypted — the relay cannot see your traffic
- Add latency (30-150ms typically) but are functional for VNC
- Are used automatically as a fallback; you don't configure anything

### WireGuard: The Encryption Layer

WireGuard is a modern VPN protocol that Tailscale uses underneath. Key properties:
- **Curve25519** key exchange — establishes shared secret between two devices
- **ChaCha20-Poly1305** encryption — encrypts all traffic (military-grade)
- **Minimal attack surface** — ~4,000 lines of code (OpenVPN has ~100,000)
- **Stealth**: WireGuard does not respond to packets from unknown sources — port scans show nothing

Your VNC data flow:
```
bVNC app → VNC protocol (unencrypted) → WireGuard encrypts →
  UDP packet sent → Router NAT → Internet → Router NAT →
  WireGuard decrypts → VNC protocol → x11vnc server
```

Even though VNC itself may not use strong encryption, the WireGuard tunnel encrypts everything in transit.

### Routing Tables: Why Internet Still Works

Your Linux kernel maintains a **routing table** — a list of rules that decide where to send network packets:

```
Destination        Gateway         Interface
100.64.0.0/10      (tailscale)     tailscale0     ← Tailscale IPs go through tunnel
192.168.1.0/24     (direct)        eth0/wlan0     ← Local LAN stays local
0.0.0.0/0          192.168.1.1     eth0/wlan0     ← Everything else → default gateway → internet
```

Tailscale ONLY adds a route for `100.64.0.0/10` (the CGNAT range). The default route (`0.0.0.0/0`) pointing to your router is left completely untouched. That's why internet keeps working — web traffic, YouTube, email all go through the default route, never touching Tailscale.

**Traditional VPNs** replace the default route with `0.0.0.0/0 → VPN tunnel`, capturing ALL traffic. If the tunnel drops, there's no route to the internet anymore. Tailscale never does this unless you explicitly enable exit node mode.

### Firewalls: What We're Configuring and Why

A firewall inspects incoming network packets and decides to **accept** or **drop** them based on rules. NixOS uses `nftables` (modern) or `iptables` (legacy) for this.

```
Incoming packet → Which interface? → Check rules → Accept or Drop

Physical interface (eth0, wlan0):
  ├── TCP 5901 (VNC) → ACCEPT (beelink only, for LAN access)
  ├── UDP 41641 (WireGuard) → ACCEPT (for direct peer connections)
  └── Everything else → DROP (firewall blocks it)

Tailscale interface (tailscale0):
  ├── TCP 5901 (VNC) → ACCEPT (our rule)
  └── Everything else → DROP (our rule — defense in depth)
```

Without `--netfilter-mode=nodivert`, Tailscale injects its own iptables chain (`ts-input`) that says "ACCEPT everything on tailscale0" — bypassing our carefully configured rules. That's why we disable it and manage rules ourselves.

### DNS: How Hostnames Resolve

DNS translates hostnames to IP addresses. Multiple DNS systems can coexist:

```
Your system's DNS resolution stack:
  ├── systemd-resolved (local resolver, port 53)
  │   ├── Tailscale MagicDNS: "beelink-ser8-desktop" → 100.64.1.5
  │   ├── Router/ISP DNS: "google.com" → 142.250.80.46
  │   └── Split DNS: queries routed to correct upstream based on domain
  └── /etc/resolv.conf → points to systemd-resolved (127.0.0.53)
```

MagicDNS adds your tailnet device names as resolvable hostnames. It does NOT replace your normal DNS — it adds to it. `google.com` still resolves normally; `beelink-ser8-desktop` additionally resolves to the Tailscale IP.

---

## How It Works (vs Traditional VPNs)

### Why This Won't Break Your Internet

Traditional VPNs (like what broke internet on Ubuntu) capture ALL network traffic and route it through a tunnel. If the tunnel drops or misconfigures DNS, internet access is lost.

Tailscale does NOT do this by default:

| Aspect | Traditional VPN | Tailscale (default mode) |
|--------|----------------|--------------------------|
| Internet traffic | Routed through tunnel | Goes directly, untouched |
| DNS | Hijacked by VPN server | Only tailnet hostnames added |
| If tunnel drops | Internet breaks | Internet unaffected |
| Routing | Full tunnel (0.0.0.0/0) | Only 100.x.y.z tailnet IPs |
| Public IP visibility | Hidden behind VPN | Unchanged (not masked) |

Both the NixOS machine AND the Android tablet maintain full normal internet access when Tailscale is running.

### Network Architecture

```
                     ┌──────────────────────────────┐
                     │     Tailscale Coordination    │
                     │     Server (key exchange)     │
                     └──────────┬───────────────────┘
                                │ HTTPS (setup only)
                    ┌───────────┴───────────┐
                    │                       │
        ┌───────────┴──────┐     ┌──────────┴───────────┐
        │ NixOS Beelink    │     │ Android Tablet       │
        │ 100.x.y.z        │◄───►│ 100.a.b.c            │
        │ (home network)   │     │ (any network)         │
        │                  │     │                       │
        │ x11vnc :5901     │     │ bVNC connects to      │
        │ RealVNC :5902    │     │ 100.x.y.z:5901        │
        └──────────────────┘     └───────────────────────┘
              ▲                           │
              │   WireGuard encrypted     │
              │   peer-to-peer tunnel     │
              └───────────────────────────┘
```

---

## Your Multi-Site Use Case

### One IP, One bVNC Profile, Works Everywhere

**Use the Tailscale IP (`100.x.y.z:5901`) for your home beelink — always.** You only need a single bVNC connection profile. Tailscale is smart enough to optimize the route automatically:

- **At home**: Both devices are on the same LAN. Tailscale detects this and routes the connection **directly over the local network** — it does NOT send your traffic out to the internet and back. The WireGuard encryption adds negligible overhead (a few microseconds per packet). Performance is identical to using the LAN IP.
- **At work**: Tailscale establishes a direct UDP tunnel through both NATs. If the corporate firewall blocks UDP, it falls back to DERP relay over **HTTPS port 443** (same port as regular web browsing — virtually never blocked). All traffic is end-to-end encrypted regardless of path.
- **Anywhere else** (coffee shop, phone hotspot, etc.): Same Tailscale IP, same connection, same encryption. It just works.

There is no reason to maintain two profiles (LAN IP + Tailscale IP). The Tailscale IP is stable (never changes), works from any network, and Tailscale automatically picks the fastest path.

### Work Computers Are Unaffected

Your work machines do NOT have Tailscale and do NOT need it. bVNC connections to work machines via their local LAN IP (`192.168.x.y`) continue to work exactly as before — Tailscale only handles traffic to `100.x.y.z` addresses and never touches local LAN routing.

### Summary Table

| You Are | Target | Connect Via | What Happens |
|---------|--------|-------------|--------------|
| Home | Home beelink | Tailscale IP `100.x.y.z:5901` | Direct over LAN (auto-detected) |
| Work | Home beelink | Tailscale IP `100.x.y.z:5901` | WireGuard tunnel or DERP relay |
| Anywhere | Home beelink | Tailscale IP `100.x.y.z:5901` | WireGuard tunnel or DERP relay |
| Work | Work machines | Work LAN IP `192.168.x.y` | Direct LAN, Tailscale not involved |

---

## Android Tablet Setup (bVNC)

### Important: Android VPN Slot

Android allows only **one active VPN** at a time. Tailscale uses this slot. Implications:
- **Local LAN access is preserved** — Tailscale only routes 100.x.y.z traffic, not local traffic
- **Do NOT enable "Block connections without VPN"** in Android system VPN settings — there's a known bug that breaks local LAN access even with "Allow LAN access" enabled
- **If you use a corporate VPN at work**: You cannot run both simultaneously. You'd need to disconnect the corporate VPN to use Tailscale (and vice versa)

### Step-by-Step Android Setup

1. **Install Tailscale** from Google Play Store (requires Android 8.0+)
2. **Open the app** and tap "Sign in"
3. **Authenticate** with your identity provider (Google, Microsoft, GitHub, etc.)
4. The tablet gets a Tailscale IP (e.g., `100.a.b.c`)
5. **Verify**: Tap the three-dot menu > check that "Use exit node" is OFF (should be off by default)

### Connecting with bVNC

1. Open bVNC on the tablet
2. Create a **new connection**:
   - **Address**: The beelink's Tailscale IP (e.g., `100.64.1.5`)
   - **Port**: `5901`
   - **Password**: Your x11vnc VNC password
3. Connect — bVNC treats the Tailscale IP like any other IP address, no special configuration needed

bVNC is fully compatible with Tailscale. The WireGuard tunnel is transparent to VNC — bVNC just sees a normal TCP connection.

Once this is working, you can **replace your existing home beelink LAN IP profile** in bVNC with the Tailscale IP profile. One profile, works from everywhere. Your work machine LAN IP profiles remain unchanged (those machines aren't on Tailscale).

---

## NixOS Configuration

### What Was Added (`system-common.nix`)

```nix
# Tailscale VPN — mesh networking for remote access (VNC, SSH, etc.)
services.tailscale.enable = true;

# Prevent Tailscale from injecting permissive iptables rules that bypass NixOS firewall.
# Without this, Tailscale auto-adds a ts-input chain accepting ALL traffic on tailscale0.
# With nodivert, we control exactly which ports are reachable via NixOS firewall rules.
services.tailscale.extraSetFlags = [ "--netfilter-mode=nodivert" ];

# Loose reverse path filtering — required for Tailscale.
# Strict mode drops legitimate WireGuard packets due to asymmetric routing.
networking.firewall.checkReversePath = "loose";

# Firewall: enabled, selective port exposure on tailscale0
networking.firewall.enable = true;
networking.firewall.allowedUDPPorts = [ 41641 ];  # Direct WireGuard peer connections

# Only allow specific services over Tailscale (defense in depth alongside Tailscale ACLs)
networking.firewall.interfaces.tailscale0 = {
  allowedTCPPorts = [ 5901 ];  # VNC (x11vnc)
};

# Disable upstream debug logging for privacy
services.tailscale.extraDaemonFlags = [ "--no-logs-no-support" ];

# systemd-resolved for MagicDNS (hostname-based access between tailnet devices)
services.resolved.enable = true;
```

### Deep Dive: Why Each Setting Is Required

#### `services.tailscale.enable = true`
**What it does**: Installs the `tailscale` package, creates the `tailscaled` systemd service, and starts it at boot.

**Theory**: Tailscale runs as a daemon (`tailscaled`) that maintains the WireGuard tunnel, handles key exchange with the coordination server, and manages the `tailscale0` virtual network interface. Without this, none of the Tailscale infrastructure exists on the machine.

#### `services.tailscale.extraSetFlags = ["--netfilter-mode=nodivert"]`
**What it does**: Tells Tailscale NOT to inject its own firewall rules.

**Theory**: By default, Tailscale modifies your system's iptables/nftables rules to ensure its traffic works. It adds a chain called `ts-input` that **accepts ALL incoming traffic on the tailscale0 interface** — effectively making every port on your machine reachable by any tailnet device. While Tailscale's own ACLs provide a layer of protection, this bypasses the NixOS firewall entirely.

With `nodivert`, Tailscale still handles NAT traversal and routing but does NOT touch the firewall. We then control exactly which ports are open using NixOS's `networking.firewall.interfaces.tailscale0` rules. This gives us **defense in depth**: even if Tailscale's ACLs have a misconfiguration, the local firewall still blocks unauthorized ports.

There are three netfilter modes:
- `on` (default): Tailscale manages firewall rules. Convenient but permissive.
- `nodivert`: Tailscale handles routing but doesn't modify firewall rules. We manage access ourselves. **This is what we use.**
- `off`: Tailscale doesn't touch networking at all. Requires manual route setup. Too complex for our needs.

#### `networking.firewall.checkReversePath = "loose"`
**What it does**: Changes the kernel's reverse path filtering from strict to loose mode.

**Theory**: Reverse path filtering is a Linux kernel security feature (RFC 3704). When a packet arrives on an interface, the kernel checks: "If I were to send a reply to the source address, would it go out the SAME interface?" If not, strict mode drops the packet as potentially spoofed.

WireGuard creates a problem: a packet from your tablet arrives on `eth0` (encrypted), gets decrypted by WireGuard, and appears on `tailscale0` with a source address of `100.x.y.z`. The kernel checks: "Would a reply to `100.x.y.z` go out `tailscale0`?" Yes. But the original encrypted packet came in on `eth0`, not `tailscale0`. Strict mode sees this as suspicious and drops it.

**Loose mode** only checks that the source address is routable via ANY interface, not specifically the one it arrived on. This allows WireGuard's asymmetric routing to work while still dropping packets with completely unroutable source addresses (basic anti-spoofing).

This is explicitly recommended by the NixOS Wiki for Tailscale and is required if you ever use exit node functionality.

#### `networking.firewall.enable = true`
**What it does**: Ensures the NixOS firewall (nftables/iptables) is active.

**Theory**: NixOS enables the firewall by default, but we state it explicitly for two reasons:
1. Documentation — makes it clear this is intentional, not just a default
2. Safety — if any other module sets `enable = false`, our explicit `true` creates a clear conflict rather than silently disabling the firewall

The NixOS firewall defaults to **deny all incoming, allow all outgoing**. We then punch specific holes for services we want to expose.

#### `networking.firewall.allowedUDPPorts = [ 41641 ]`
**What it does**: Opens UDP port 41641 on ALL interfaces (including physical ones like eth0/wlan0).

**Theory**: This is Tailscale's WireGuard port. When two Tailscale devices try to establish a direct peer-to-peer connection, they send UDP packets to each other's public IP on this port. If the port is blocked, NAT traversal (hole-punching) fails and traffic falls back to DERP relay servers.

Opening this port does NOT create a security risk because:
- WireGuard only responds to packets from devices that know the correct cryptographic key
- Port scans against 41641 receive NO response (WireGuard is silent to unknown senders)
- An attacker would need your private WireGuard key to establish a connection

Without this port open, Tailscale still works but all traffic goes through DERP relays, adding 30-150ms latency. For VNC, direct connections are noticeably smoother.

#### `networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5901 ]`
**What it does**: Allows TCP connections to port 5901 (VNC) ONLY on the tailscale0 interface.

**Theory**: This is the core of our per-interface firewall strategy. Instead of adding 5901 to the global `allowedTCPPorts` (which would open it on ALL interfaces including physical ones), we restrict it to just `tailscale0`.

What this means in practice:
- A device on your tailnet (authenticated tablet) CAN reach VNC at `100.x.y.z:5901` ✓
- A random device on the internet CANNOT reach VNC on your public IP ✗
- Note: The beelink also has `allowedTCPPorts = [ 5901 ]` globally (in `desktop-beelink.nix`) for LAN access. This is separate — it opens 5901 on all interfaces on the beelink specifically.

This works in conjunction with `--netfilter-mode=nodivert`. Without nodivert, Tailscale would override this rule and allow ALL ports on tailscale0.

#### `services.tailscale.extraDaemonFlags = ["--no-logs-no-support"]`
**What it does**: Disables Tailscale's upstream debug log collection.

**Theory**: By default, the `tailscaled` daemon sends anonymized debug/diagnostic logs to Tailscale Inc.'s servers. This helps them debug issues but means some metadata about your system leaves your network. The `--no-logs-no-support` flag disables this entirely.

Trade-off: If you need Tailscale's support team to help debug an issue, they won't have access to your logs. For a personal setup, this is a good privacy trade-off.

#### `services.resolved.enable = true`
**What it does**: Enables `systemd-resolved`, a local DNS resolver daemon.

**Theory**: Tailscale's MagicDNS feature lets you reach tailnet devices by hostname (e.g., `beelink-ser8-desktop` instead of `100.64.1.5`). On Linux, MagicDNS requires `systemd-resolved` because it uses the `resolvectl` API to configure split DNS — routing `.ts.net` queries to Tailscale's DNS while routing everything else to your normal DNS servers.

Without systemd-resolved, MagicDNS won't work and you'll have to use raw Tailscale IPs. Regular internet DNS is unaffected either way.

`systemd-resolved` also integrates with NetworkManager (which we use), so WiFi DNS settings are properly managed through a single resolver rather than competing `/etc/resolv.conf` writes.

---

## Security Architecture

### Defense in Depth (3 Layers)

```
Layer 1: Tailscale Authentication
  └── Only devices authenticated to YOUR tailnet can communicate
  └── Uses your identity provider (Google/GitHub/etc.) with MFA
  └── Unauthorized devices cannot even see your machine exists

Layer 2: Tailscale ACLs (configured in admin console)
  └── Controls which tailnet devices can reach which ports
  └── Default-deny: if not explicitly permitted, connection drops
  └── Enforced at destination device

Layer 3: NixOS Firewall (local)
  └── --netfilter-mode=nodivert prevents Tailscale from bypassing it
  └── Only port 5901 (VNC) allowed on tailscale0 interface
  └── All other ports blocked even for authenticated tailnet devices
```

### What Is NOT Exposed to the Internet

| Service | Public Internet | Home LAN | Tailnet (100.x.y.z) |
|---------|-----------------|----------|----------------------|
| VNC (5901) | BLOCKED | OPEN (beelink only) | OPEN |
| RealVNC (5902) | BLOCKED (cloud relay only) | BLOCKED | BLOCKED (use 5901) |
| SSH (22) | BLOCKED | BLOCKED | BLOCKED (not configured) |
| All other ports | BLOCKED | BLOCKED | BLOCKED |

- **No ports are open to the public internet** for Tailscale
- UDP 41641 accepts only authenticated WireGuard handshakes — port scanning reveals nothing
- The beelink's public IP is not discoverable through Tailscale
- The Tailscale coordination server knows your IP (for NAT traversal) but does not expose it

### What Tailscale (the Company) Can See

| Can See | Cannot See |
|---------|------------|
| Device public IPs (for NAT traversal) | Your traffic content (end-to-end encrypted) |
| Which devices are online | VNC session contents |
| Device metadata (OS, hostname) | Files, passwords, screen contents |
| When devices connect/disconnect | Local network topology |

To minimize even this: `--no-logs-no-support` disables debug telemetry (already configured).

### IP Privacy

- **Your public IP is NOT exposed** to the internet through Tailscale
- **Other tailnet devices** see only the Tailscale 100.x.y.z IP, not your real IP
- **Tailscale's coordination server** sees your public IP (unavoidable for NAT traversal)
- **Tailscale is NOT an anonymity tool** — it does not mask your IP from websites you visit. For that, you'd need Tor or a commercial VPN with exit nodes.

### Why Tailscale's Design Is Theoretically Secure

Tailscale makes several architectural decisions that are fundamentally more secure than traditional VPN or port-forwarding approaches. Understanding the theory behind these choices explains why we can trust it.

#### 1. Zero Trust Networking (vs Perimeter Security)

**Traditional model (perimeter security)**: Your home router acts as a wall. Everything inside the LAN is trusted, everything outside is untrusted. If someone gets past the wall (e.g., by connecting to your WiFi or compromising your router), they can access everything on your network. Port forwarding punches permanent holes in this wall.

**Tailscale model (zero trust)**: There is no trusted perimeter. Every connection between every device must be individually authenticated and authorized. Even if someone is on your home WiFi, they cannot reach Tailscale services because they don't have the cryptographic keys. The "wall" is around each device, not around the network.

```
Perimeter Security:              Zero Trust (Tailscale):
┌──────────────────────┐         ┌──────────────────────┐
│ Router (firewall)    │         │ Network (untrusted)  │
│ ┌──────────────────┐ │         │  ┌─────┐   ┌─────┐  │
│ │ All devices      │ │         │  │ 🔒A │   │ 🔒B │  │
│ │ trust each other │ │         │  │     │◄─►│     │  │
│ │ (flat network)   │ │         │  └─────┘   └─────┘  │
│ └──────────────────┘ │         │  Each device has its │
│ Port forward = hole  │         │  own crypto identity │
└──────────────────────┘         └──────────────────────┘
One breach = full access         One breach = one device
```

**Why this matters for you**: Even if someone at your workplace is sniffing WiFi traffic or your home router gets compromised, they cannot access your VNC session. They would need the WireGuard private key stored on your tablet.

#### 2. Cryptographic Identity (vs Password/IP-Based Trust)

Traditional VPNs and VNC authenticate using passwords or IP address restrictions. These have well-known weaknesses:
- Passwords can be guessed, leaked, reused, or intercepted
- IP addresses can be spoofed
- Network location is not identity — being on the right WiFi doesn't mean you're authorized

Tailscale uses **public-key cryptography** for device identity:
- Each device generates a **Curve25519 key pair** (public + private key) at setup
- The private key never leaves the device — not even Tailscale's servers know it
- To communicate, two devices must know each other's public key (exchanged via the coordination server)
- An attacker who intercepts traffic sees only encrypted data — they cannot forge a valid device identity without the private key

**The math**: Curve25519 provides 128-bit security. Breaking it would require approximately 2^128 operations — more than all the computers on Earth could perform in billions of years. This is the same standard used by Signal, WhatsApp, and SSH.

#### 3. End-to-End Encryption (vs Transport Encryption)

**Transport encryption** (like HTTPS): Your traffic is encrypted between you and a server, but the server can read it. If the server is compromised, your data is exposed.

**End-to-end encryption** (WireGuard/Tailscale): Traffic is encrypted on your tablet and can ONLY be decrypted by your beelink. Nobody in between can read it — not your ISP, not the WiFi operator, not the DERP relay servers, not even Tailscale Inc.

```
Transport encryption:
Tablet ──encrypted──→ Server ──encrypted──→ Beelink
                      ↑ Server can read
                        your data here

End-to-end encryption (Tailscale):
Tablet ══════════════encrypted═══════════════ Beelink
         ↑ Nobody in between can read this
         Not ISP, not WiFi, not DERP, not Tailscale
```

The encryption used is **ChaCha20-Poly1305**:
- **ChaCha20**: Stream cipher for data confidentiality (256-bit key)
- **Poly1305**: Message authentication code — detects any tampering
- This combination is used by Google (QUIC protocol), Cloudflare, and the Linux kernel

#### 4. Silent by Design (vs Responsive Services)

Traditional VPN servers and VNC servers **respond to any incoming connection attempt**. An attacker can:
- Port scan to discover they exist
- Attempt brute-force attacks against login screens
- Probe for known vulnerabilities

WireGuard is **cryptographically silent**: it does not respond to packets from unknown senders. Here's what happens when different entities send packets to your open UDP 41641 port:

```
Random attacker sends packet to port 41641:
  → WireGuard checks: "Do I know this public key?" → No → DISCARD (no reply sent)
  → Attacker sees: nothing. Port appears closed/filtered. No information leaked.

Your authenticated tablet sends packet:
  → WireGuard checks: "Do I know this public key?" → Yes → DECRYPT → Process
```

This is called **"non-responsive to unauthenticated traffic"** and it means:
- Port scans reveal nothing — scanners cannot tell WireGuard is running
- No brute-force attack is possible — there is no login prompt to attack
- No DoS amplification — invalid packets produce no response
- The attack surface is essentially zero for unauthenticated adversaries

#### 5. Minimal Attack Surface (vs Feature-Rich VPN Software)

WireGuard's codebase is approximately **4,000 lines of code**. For comparison:
- OpenVPN: ~100,000 lines
- IPsec (strongSwan): ~400,000 lines
- Traditional VPN solutions: often hundreds of thousands of lines

**Why smaller is more secure**: Every line of code is a potential vulnerability. Fewer lines mean:
- Easier to audit (WireGuard has been formally verified and audited multiple times)
- Fewer bugs — less code, fewer places for mistakes
- Smaller attack surface — fewer features that could be exploited
- Part of the Linux kernel since v5.6 — reviewed by the kernel security team

WireGuard was designed by cryptographer **Jason Donenfeld** with the explicit goal of being simple enough to audit in an afternoon. This is a fundamental security advantage over complex legacy VPN protocols.

#### 6. Separation of Concerns: Control Plane vs Data Plane

Tailscale separates the system into two parts with different trust levels:

**Control plane** (Tailscale's coordination server):
- Handles key exchange, device registration, ACL distribution
- Knows your public keys and public IPs
- Does NOT handle any of your actual data traffic
- If compromised: attacker could potentially add a rogue device to your tailnet (mitigated by Tailnet Lock — see hardening section)

**Data plane** (your devices, peer-to-peer):
- Handles all actual traffic (VNC, SSH, file transfers)
- Fully end-to-end encrypted — only your devices have private keys
- If the coordination server goes down: existing connections continue to work (keys are cached locally)
- Tailscale (the company) never touches your data traffic

```
Control plane (key exchange):     Data plane (your traffic):
Tailscale servers ← HTTPS →      Tablet ←── WireGuard ──→ Beelink
  "Here are each other's          (direct, peer-to-peer,
   public keys"                    Tailscale servers not involved)
```

**Why this matters**: Even in a worst-case scenario where Tailscale's servers are fully compromised, the attacker:
- Cannot decrypt any of your past or present traffic (they never had the private keys)
- Could potentially add a new device to your tailnet (but Tailnet Lock prevents even this)
- Cannot perform a man-in-the-middle attack (WireGuard verifies both endpoints cryptographically)

#### 7. Tailnet Lock: Trust No One (Not Even Tailscale)

Tailnet Lock is Tailscale's answer to the question: "What if Tailscale itself is compromised?"

Without Tailnet Lock, the coordination server controls which devices can join your tailnet. A compromised server could add an attacker's device.

With Tailnet Lock enabled:
- New devices must be **cryptographically signed** by an existing trusted device
- The signing keys are stored ONLY on your devices — Tailscale's servers never see them
- Even with full control of the coordination server, an attacker cannot add a rogue node

This is a rare property in VPN services — most VPN providers ask you to trust their infrastructure completely. Tailscale's architecture lets you verify trustworthiness even if you assume their servers are compromised.

#### 8. Why Port Forwarding Would Be Dangerous (What We're Avoiding)

Without Tailscale, the alternative for remote VNC access would be port forwarding:

```
DANGEROUS — Port forwarding:
Internet ──→ Router (port 5901 forwarded) ──→ Beelink VNC
  ↑ Anyone on the internet can attempt connections
  ↑ Your public IP is exposed
  ↑ Brute-force attacks against VNC password
  ↑ Known VNC vulnerabilities exploitable
  ↑ VNC traffic may be unencrypted

SAFE — Tailscale:
Internet ──→ Router (no forwarded ports) ──→ Nothing accessible
             Tailscale ──→ Beelink VNC (only from authenticated devices)
  ↑ No public ports open
  ↑ No discoverable services
  ↑ All traffic WireGuard-encrypted
  ↑ Only your devices can connect
```

VNC protocol itself has known security weaknesses (weak authentication, some implementations lack encryption). By wrapping VNC inside a WireGuard tunnel, these weaknesses become irrelevant — an attacker would need to break WireGuard encryption first, which is computationally infeasible.

---

## Security Hardening Checklist (Post-Install)

### Immediate (Do After First `tailscale up`)

- [ ] **Enable Tailnet Lock** in the admin console — prevents rogue devices from joining even if Tailscale's servers are compromised. This is the single most important security measure.
  - Admin Console > Settings > Tailnet Lock > Enable
  - Sign your first device as a trusted node
- [ ] **Enable MFA** on your identity provider (Google, GitHub, etc.) — Tailscale inherits your IdP's auth, so MFA protects your tailnet
- [ ] **Review device list** — remove any old/unknown devices from your tailnet

### Configure ACLs (Admin Console)

Replace the default "allow everything" ACL with a restrictive policy:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:owner"],
      "dst": ["autogroup:self:5901"]
    }
  ]
}
```

This allows only YOUR devices to reach VNC (port 5901) on YOUR devices. Everything else is denied.

### After Verifying Tailscale VNC Works

- [ ] **Consider closing LAN VNC port** — remove `networking.firewall.allowedTCPPorts = [ 5901 ]` from `desktop-beelink.nix` if you no longer need LAN VNC access. This eliminates VNC exposure on the physical network entirely.
- [ ] **Consider disabling RealVNC cloud relay** — if Tailscale handles all remote access, the cloud relay is redundant attack surface

### Optional Further Hardening

- [ ] **Key expiry**: Set device key expiry in admin console (default 180 days — device must re-authenticate periodically)
- [ ] **Tailscale SSH**: `sudo tailscale up --ssh` — replaces OpenSSH with Tailscale-managed SSH. Automatic key management, audit logging, no passwords.
- [ ] **Device approval**: Require admin approval for new devices joining the tailnet

---

## Deployment Steps

### 1. Test the NixOS configuration
```bash
bash ~/.local/share/chezmoi/system_scripts/test-deploy-nixos.sh
```

### 2. Deploy to the system
```bash
bash ~/.local/share/chezmoi/system_scripts/deploy-nixos.sh
```

### 3. Authenticate Tailscale (one-time)
```bash
sudo tailscale up
```
This prints a URL — open it in a browser and sign in with your identity provider.

### 4. Note your Tailscale IP
```bash
tailscale ip -4
# Example output: 100.64.1.5
```
Write this down — you'll enter it in bVNC on the tablet.

### 5. Install Tailscale on Android tablet
- Google Play Store > search "Tailscale" > Install > Sign in with same account

### 6. Test VNC over Tailscale
- Open bVNC on tablet
- New connection: address = `100.x.y.z`, port = `5901`
- Enter your VNC password
- You should see your desktop

### 7. Post-deployment security verification
```bash
# Confirm firewall is active
sudo iptables -L -n | head -20

# Verify only VNC is open on tailscale0
sudo iptables -L -n | grep 5901

# Confirm no unexpected listening ports
sudo ss -tlnp

# Check Tailscale connection type (direct vs relay)
tailscale ping <android-device-name>

# Verify netfilter mode is nodivert
tailscale debug netfilter
```

---

## Useful Commands

```bash
# Service status
systemctl status tailscaled

# Show all tailnet devices and their IPs
tailscale status

# Get this machine's Tailscale IP
tailscale ip -4

# Check connection type to another device (direct vs DERP relay)
tailscale ping <device-name>

# Network diagnostics (firewall, NAT type, DERP latency)
tailscale netcheck

# Disconnect temporarily (internet unaffected)
sudo tailscale down

# Reconnect
sudo tailscale up

# Force re-authentication
sudo tailscale up --force-reauth

# Send a file to another device
tailscale file cp myfile.txt <device-name>:

# Check for available updates
tailscale version
```

---

## Troubleshooting

### Tailscale won't connect
```bash
systemctl status tailscaled            # Is the daemon running?
sudo tailscale netcheck                # Firewall/NAT diagnostics
journalctl -u tailscaled --since today # Daemon logs
sudo tailscale up --force-reauth       # Force fresh authentication
```

### VNC not reachable over Tailscale
```bash
# Is VNC listening?
sudo ss -tlnp | grep 5901

# Is the Tailscale IP correct?
tailscale ip -4

# Is the firewall allowing VNC on tailscale0?
sudo iptables -L -n | grep 5901

# Can the tablet reach the machine at all?
# On Android: Tailscale app > three-dot menu > "Network" shows connectivity
```

### Slow VNC (using DERP relay instead of direct)
```bash
# Check connection type
tailscale ping <tablet-name>
# If it says "via DERP(xxx)", your corporate firewall is blocking direct UDP.
# This still works but with higher latency (typically 50-150ms added).
# DERP relay over HTTPS is the fallback — traffic remains encrypted.
```

### Internet not working (should not happen, but if it does)
```bash
# Check if exit node is accidentally enabled
tailscale status
# If "offers exit node" appears, disable it:
sudo tailscale up --exit-node=

# Check DNS resolution
resolvectl status
nslookup google.com

# Nuclear option: disconnect Tailscale entirely
sudo tailscale down
# Internet should immediately work. If it does, the issue is Tailscale config.
```

### MagicDNS not resolving hostnames
```bash
# Check if systemd-resolved is running
systemctl status systemd-resolved

# Check DNS configuration
resolvectl status

# Test hostname resolution
ping beelink-ser8-desktop  # Should resolve to 100.x.y.z
```

---

## Features to Enable Later

| Feature | Command / Config | Use Case |
|---------|-----------------|----------|
| **MagicDNS** | Enable in admin console | Use `beelink-ser8-desktop` instead of `100.x.y.z` |
| **Tailscale SSH** | `sudo tailscale up --ssh` | SSH without managing keys |
| **Taildrop** | `tailscale file cp file.txt peer:` | Transfer files between devices |
| **Exit node** | `sudo tailscale up --advertise-exit-node` | Route ALL traffic through home (use cautiously — this IS a full VPN) |
| **Subnet router** | `sudo tailscale up --advertise-routes=192.168.1.0/24` | Expose home LAN to tailnet |

**Warning about exit nodes**: Enabling exit node mode turns Tailscale into a traditional full-tunnel VPN. This is the mode that CAN break internet access if misconfigured — the same problem you experienced on Ubuntu. **Do NOT enable exit node unless you specifically need it.** Default mode (overlay network) is what keeps internet working normally.

---

## Files Modified

| File | Change |
|------|--------|
| `system_nixos/machines/shared/system-common.nix` | Added Tailscale service, firewall hardening, systemd-resolved |
| `docs/system/Tailscale_Setup.md` | This documentation |

## Known CVEs to Monitor

| CVE | Severity | Impact | Fixed In |
|-----|----------|--------|----------|
| Pre-1.66.0 exit node LAN leak | High | Exit nodes could allow LAN inbound to tailnet | v1.66.0+ |
| TS-2025-008 | Medium | Tailnet Lock bypass without --statedir | 2025 patch |
| GHSA-vqp6-rc3h-83cp | Critical | Windows-only RCE via CSRF | v1.32.3+ |

Ensure your Tailscale version is current: `tailscale version`

## Status Checklist
- [x] NixOS configuration added to `system-common.nix`
- [x] Security hardening: `--netfilter-mode=nodivert`, selective port exposure, privacy flags
- [x] Firewall rules: only VNC (5901) on tailscale0, base firewall enabled
- [x] systemd-resolved enabled for MagicDNS
- [x] Documentation complete
- [ ] Test deployment (`test-deploy-nixos.sh`)
- [ ] Deploy to system (`deploy-nixos.sh`)
- [ ] Authenticate with `sudo tailscale up`
- [ ] Install Tailscale on Android tablet
- [ ] Test bVNC connection via Tailscale IP
- [ ] Enable Tailnet Lock in admin console
- [ ] Configure ACLs in admin console
- [ ] Verify internet works on both devices after setup
