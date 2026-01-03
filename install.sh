#!/bin/sh
set -e

# Janus installer script
# Usage: curl -sSL https://get-janus.affylabs.com | sh

REPO="Affylabs/homebrew-janus"
BINARY_NAME="janus"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

info() {
    printf "${BLUE}==>${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}==>${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}warning:${NC} %s\n" "$1"
}

error() {
    printf "${RED}error:${NC} %s\n" "$1" >&2
    exit 1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "darwin" ;;
        Linux) echo "linux" ;;
        *) error "Unsupported operating system: $(uname -s)" ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        arm64|aarch64) echo "arm64" ;;
        *) error "Unsupported architecture: $(uname -m)" ;;
    esac
}

# Validate platform support
validate_platform() {
    local os="$1"
    local arch="$2"

    if [ "$os" = "darwin" ] && [ "$arch" = "amd64" ]; then
        error "macOS Intel (x86_64) is not supported. Janus requires Apple Silicon (ARM64)."
    fi
}

# Get install directory based on platform
get_install_dir() {
    local os="$1"

    if [ "$os" = "darwin" ]; then
        # macOS: prefer /usr/local/bin
        if [ -w "/usr/local/bin" ]; then
            echo "/usr/local/bin"
        elif [ -n "$SUDO_USER" ] || [ "$(id -u)" = "0" ]; then
            echo "/usr/local/bin"
        else
            echo "$HOME/.local/bin"
        fi
    else
        # Linux: prefer ~/.local/bin
        echo "$HOME/.local/bin"
    fi
}

# Check if directory is in PATH
is_in_path() {
    case ":$PATH:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Detect shell config file
detect_shell_config() {
    case "$SHELL" in
        */zsh) echo "$HOME/.zshrc" ;;
        */bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        */fish) echo "$HOME/.config/fish/config.fish" ;;
        *) echo "$HOME/.profile" ;;
    esac
}

# Download file with curl or wget
download() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Verify checksum
verify_checksum() {
    local file="$1"
    local expected="$2"

    local actual
    if command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        warn "No checksum tool found, skipping verification"
        return 0
    fi

    if [ "$actual" != "$expected" ]; then
        error "Checksum verification failed.\nExpected: $expected\nActual: $actual"
    fi
}

main() {
    info "Installing Janus..."

    # Detect platform
    local os=$(detect_os)
    local arch=$(detect_arch)
    validate_platform "$os" "$arch"

    info "Detected platform: ${os}-${arch}"

    # Determine artifact name
    local artifact="janus-${os}-${arch}"
    local tarball="${artifact}.tar.gz"

    # Create temp directory
    local tmpdir=$(mktemp -d)
    trap "rm -rf '$tmpdir'" EXIT

    # Download URLs
    local base_url="https://github.com/${REPO}/releases/latest/download"
    local tarball_url="${base_url}/${tarball}"
    local checksums_url="${base_url}/checksums.txt"

    # Download tarball
    info "Downloading ${tarball}..."
    download "$tarball_url" "$tmpdir/$tarball"

    # Download and verify checksum
    info "Verifying checksum..."
    download "$checksums_url" "$tmpdir/checksums.txt"
    local expected_checksum=$(grep "$tarball" "$tmpdir/checksums.txt" | cut -d' ' -f1)
    if [ -z "$expected_checksum" ]; then
        error "Checksum not found for $tarball"
    fi
    verify_checksum "$tmpdir/$tarball" "$expected_checksum"

    # Extract
    info "Extracting..."
    tar -xzf "$tmpdir/$tarball" -C "$tmpdir"

    # Determine install location
    local install_dir=$(get_install_dir "$os")
    local install_path="${install_dir}/${BINARY_NAME}"

    # Create install directory if needed
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir"
    fi

    # Install binary
    info "Installing to ${install_path}..."
    if [ -w "$install_dir" ]; then
        mv "$tmpdir/$BINARY_NAME" "$install_path"
        chmod +x "$install_path"
    else
        sudo mv "$tmpdir/$BINARY_NAME" "$install_path"
        sudo chmod +x "$install_path"
    fi

    # Verify installation
    if ! "$install_path" version >/dev/null 2>&1; then
        error "Installation verification failed"
    fi

    success "Janus installed successfully!"
    echo ""

    # PATH instructions if needed
    if ! is_in_path "$install_dir"; then
        local shell_config=$(detect_shell_config)
        warn "${install_dir} is not in your PATH"
        echo ""
        echo "Add it to your PATH by running:"
        echo ""
        if [ "$SHELL" = "*/fish" ]; then
            echo "  fish_add_path ${install_dir}"
        else
            echo "  echo 'export PATH=\"${install_dir}:\$PATH\"' >> ${shell_config}"
        fi
        echo ""
        echo "Then restart your shell or run:"
        echo ""
        echo "  source ${shell_config}"
        echo ""
    fi

    echo "Get started:"
    echo ""
    echo "  janus init      # Create your encrypted vault"
    echo "  janus import    # Import from ~/.ssh/config"
    echo "  janus web       # Start the web interface"
    echo ""
}

main "$@"
