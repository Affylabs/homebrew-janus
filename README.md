# Janus

The server management tool you'd build yourself—if you had the time.

One encrypted binary. SSH, Docker, Kubernetes, and reverse proxies—all from your terminal or browser.

## Install

### Shell script (macOS and Linux)

```bash
curl -sSL https://get-janus.affylabs.com | sh
```

### Homebrew (macOS and Linux)

```bash
brew tap affylabs/janus
brew install janus
```

## Supported Platforms

| OS | Architecture | Supported |
|----|--------------|-----------|
| macOS | ARM64 (Apple Silicon) | Yes |
| macOS | x86_64 (Intel) | No |
| Linux | x86_64 | Yes |
| Linux | ARM64 | Yes |

## Getting Started

```bash
janus init      # Create your encrypted vault
janus import    # Import from ~/.ssh/config
janus web       # Start the web interface
```

## Links

- [Documentation](https://affylabs.com/apps/janus/docs)
- [Report an Issue](https://github.com/Affylabs/homebrew-janus/issues)
