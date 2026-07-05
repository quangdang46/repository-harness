#!/usr/bin/env bash
set -euo pipefail
umask 022

# ============================================================
# repository-harness installer — curl | bash
#
# Downloads and installs the prebuilt harness-cli and
# harness-symphony binaries for your platform.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/quangdang46/repository-harness/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/quangdang46/repository-harness/main/install.sh | bash -s -- --dest ~/.local/bin
#   curl -fsSL https://raw.githubusercontent.com/quangdang46/repository-harness/main/install.sh | bash -s -- --version v0.1.0
# ============================================================

# === Config ===
BINARY_NAMES=("harness-cli" "harness-symphony")
OWNER="quangdang46"
REPO="repository-harness"
DEST="${DEST:-$HOME/.local/bin}"
VERSION="${VERSION:-}"
QUIET=0
EASY=0
VERIFY=0
FROM_SOURCE=0
UNINSTALL=0
NO_MCP=0
NO_HOOKS=0
DRY_RUN=0
MAX_RETRIES=3
DOWNLOAD_TIMEOUT=120
LOCK_DIR="/tmp/${REPO}-install.lock.d"
TMP=""

# === Logging ===
log_info()    { [ "$QUIET" -eq 1 ] && return; echo "[${REPO}] $*" >&2; }
log_warn()    { echo "[${REPO}] WARN: $*" >&2; }
log_success() { [ "$QUIET" -eq 1 ] && return; echo "✓ $*" >&2; }
die()         { echo "ERROR: $*" >&2; exit 1; }

# === Cleanup & lock ===
cleanup() { rm -rf "$TMP" "$LOCK_DIR" 2>/dev/null || true; }
trap cleanup EXIT

acquire_lock() {
    mkdir "$LOCK_DIR" 2>/dev/null || die "Another install is running. If stuck: rm -rf $LOCK_DIR"
    echo $$ > "$LOCK_DIR/pid"
}

# === Usage ===
usage() {
    cat <<EOF
Usage: install.sh [options]

Install ${BINARY_NAMES[*]} from GitHub releases.

Options:
  --dest <path>       Install destination (default: \$HOME/.local/bin)
  --version <tag>     Release tag (default: latest)
  --system            Install to /usr/local/bin
  --easy-mode         Auto-add to PATH in shell rc files
  --verify            Run --version after install
  --from-source       Build from source instead of downloading
  --no-mcp            Skip MCP provider configuration
  --no-hooks          Skip hook configuration
  --quiet, -q         Quiet mode
  --uninstall         Remove installed binaries
  --dry-run           Preview without changes
  -h, --help          Show this help
EOF
    exit 0
}

# === Args ===
while [ $# -gt 0 ]; do
    case "$1" in
        --dest)        DEST="$2";        shift 2 ;;
        --dest=*)      DEST="${1#*=}";   shift ;;
        --version)     VERSION="$2";      shift 2 ;;
        --version=*)   VERSION="${1#*=}"; shift ;;
        --system)      DEST="/usr/local/bin"; shift ;;
        --easy-mode)   EASY=1;           shift ;;
        --verify)      VERIFY=1;         shift ;;
        --from-source) FROM_SOURCE=1;    shift ;;
        --no-mcp)      NO_MCP=1;         shift ;;
        --no-hooks)    NO_HOOKS=1;       shift ;;
        --quiet|-q)    QUIET=1;          shift ;;
        --uninstall)   UNINSTALL=1;      shift ;;
        --dry-run)     DRY_RUN=1;        shift ;;
        -h|--help)     usage ;;
        *) shift ;;
    esac
done

# === Uninstall ===
if [ "$UNINSTALL" -eq 1 ]; then
    echo "[${REPO}] Uninstalling..."
    for bin in "${BINARY_NAMES[@]}"; do
        rm -f "$DEST/$bin"
        echo "  removed $DEST/$bin"
    done
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] && sed -i "/${REPO} installer/d" "$rc" 2>/dev/null || true
    done
    echo "✓ Uninstalled ${BINARY_NAMES[*]}"
    exit 0
fi

# === Platform detection ===
detect_platform() {
    local os arch
    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="macos" ;;
        MINGW*|MSYS*|CYGWIN*) os="windows" ;;
        *) die "Unsupported OS: $(uname -s)" ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64)   arch="x86_64" ;;
        aarch64|arm64)  arch="arm64" ;;
        *) die "Unsupported architecture: $(uname -m)" ;;
    esac
    echo "${os}-${arch}"
}

target_to_release_suffix() {
    case "$1" in
        macos-arm64)  echo "macos-arm64" ;;
        macos-x86_64) echo "macos-x64" ;;
        linux-x86_64) echo "linux-x64" ;;
        linux-arm64)  echo "linux-arm64" ;;
        windows-x86_64) echo "windows-x64" ;;
        *) die "Unsupported platform: $1" ;;
    esac
}

# === Version resolution ===
resolve_version() {
    [ -n "$VERSION" ] && return 0
    log_info "Resolving latest version..."
    VERSION=$(curl -fsSL --connect-timeout 10 --max-time 30 \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" \
        2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') || true
    if [ -z "$VERSION" ]; then
        VERSION=$(curl -fsSL -o /dev/null -w '%{url_effective}' \
            "https://github.com/${OWNER}/${REPO}/releases/latest" \
            2>/dev/null | sed -E 's|.*/tag/||') || true
    fi
    [[ "$VERSION" =~ ^v[0-9] ]] || die "Could not resolve latest version from GitHub"
    log_info "Latest release: $VERSION"
}

# === Download with retry ===
download_file() {
    local url="$1" dest="$2"
    local partial="${dest}.part"
    local attempt=0
    while [ $attempt -lt $MAX_RETRIES ]; do
        attempt=$((attempt + 1))
        curl -fL \
            --connect-timeout 30 \
            --max-time "$DOWNLOAD_TIMEOUT" \
            --retry 2 \
            $( [ -s "$partial" ] && echo "--continue-at -" ) \
            $( [ "$QUIET" -eq 0 ] && [ -t 2 ] && echo "--progress-bar" || echo "-sS" ) \
            -o "$partial" "$url" \
        && mv -f "$partial" "$dest" && return 0
        [ $attempt -lt $MAX_RETRIES ] && { log_warn "Download failed, retrying in 3s (attempt $attempt/$MAX_RETRIES)..."; sleep 3; }
    done
    return 1
}

# === Atomic binary install ===
install_binary_atomic() {
    local src="$1" dest="$2"
    local tmp="${dest}.tmp.$$"
    install -m 0755 "$src" "$tmp" || { rm -f "$tmp"; die "Failed to stage binary"; }
    mv -f "$tmp" "$dest" || { rm -f "$tmp"; die "Failed to install binary to $dest"; }
}

# === PATH ===
maybe_add_path() {
    case ":$PATH:" in *":$DEST:"*) return 0;; esac
    if [ "$EASY" -eq 1 ]; then
        for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
            [ -f "$rc" ] && [ -w "$rc" ] || continue
            grep -qF "$DEST" "$rc" && continue
            printf '\nexport PATH="%s:$PATH"  # %s installer\n' "$DEST" "$REPO" >> "$rc"
        done
        log_warn "PATH updated — restart shell or: export PATH=\"$DEST:\$PATH\""
    else
        log_warn "Add to PATH: export PATH=\"$DEST:\$PATH\""
    fi
}

# === Build from source (fallback) ===
build_from_source() {
    local bin_name="$1"
    command -v cargo >/dev/null || die "Rust/cargo not found. Install: https://rustup.rs"
    local pkg
    case "$bin_name" in
        harness-cli)      pkg="harness-cli" ;;
        harness-symphony) pkg="harness-symphony" ;;
        *) die "Unknown binary: $bin_name" ;;
    esac
    local src_dir="$TMP/src"
    if [ ! -d "$src_dir/.git" ]; then
        git clone --depth 1 "https://github.com/${OWNER}/${REPO}.git" "$src_dir"
    fi
    (cd "$src_dir" && cargo build --release -p "$pkg")
    install_binary_atomic "$src_dir/target/release/$bin_name" "$DEST/$bin_name"
}

# === JSON merge helper ===
_json_merge() {
    local file="$1" key="$2" value="$3"
    mkdir -p "$(dirname "$file")"
    if [ ! -f "$file" ]; then
        echo "{ \"${key}\": ${value} }" > "$file"
        return 0
    fi
    if command -v jq &>/dev/null; then
        local tmpf; tmpf="$(mktemp)"
        jq --argjson val "$value" ".${key} += \$val // .${key} = \$val" "$file" > "$tmpf" && mv "$tmpf" "$file"
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, os
f='$file'; k='$key'; v=$value
d=json.load(open(f)) if os.path.exists(f) and os.path.getsize(f)>0 else {}
d.setdefault(k,{}).update(v)
json.dump(d,open(f,'w'),indent=2)
"
    else
        log_warn "No JSON tool (jq/python3) — skipping $file"; return 1
    fi
}

# === Main ===
main() {
    acquire_lock
    TMP="$(mktemp -d)"
    mkdir -p "$DEST"

    local platform; platform="$(detect_platform)"
    local suffix; suffix="$(target_to_release_suffix "$platform")"
    local ext="tar.gz"
    [[ "$platform" == windows-* ]] && ext="zip"

    log_info "Platform: $platform | Destination: $DEST"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY RUN] Would install: ${BINARY_NAMES[*]} to $DEST"
        echo "[DRY RUN] Would download: https://github.com/${OWNER}/${REPO}/releases"
        exit 0
    fi

    if [ "$FROM_SOURCE" -eq 0 ]; then
        resolve_version
    fi

    for bin_name in "${BINARY_NAMES[@]}"; do
        log_info "Installing $bin_name..."

        if [ "$FROM_SOURCE" -eq 1 ]; then
            build_from_source "$bin_name"
        else
            # Determine the correct archive name from the release
            # Release artifacts follow: harness-cli-<platform> (no archive wrapper)
            local release_suffix="$suffix"
            [[ "$release_suffix" == windows-* ]] && release_suffix="${release_suffix}.exe" || true

            local url="https://github.com/${OWNER}/${REPO}/releases/download/${VERSION}/${bin_name}-${release_suffix}"

            # Release artifacts are binary files, not archives
            if download_file "$url" "$TMP/$bin_name"; then
                # Verify checksum if sidecar exists
                local sidecar_url="${url}.sha256"
                if download_file "$sidecar_url" "$TMP/${bin_name}.sha256" 2>/dev/null; then
                    local expected actual
                    expected=$(awk '{print $1}' "$TMP/${bin_name}.sha256")
                    actual=$(sha256sum "$TMP/$bin_name" 2>/dev/null | awk '{print $1}') || \
                    actual=$(shasum -a 256 "$TMP/$bin_name" | awk '{print $1}') || true
                    if [ -n "$expected" ] && [ -n "$actual" ]; then
                        [ "$expected" = "$actual" ] || die "Checksum mismatch for $bin_name"
                        log_info "Checksum verified for $bin_name"
                    fi
                fi
                install_binary_atomic "$TMP/$bin_name" "$DEST/$bin_name"
            else
                log_warn "Binary download failed for $bin_name — building from source..."
                build_from_source "$bin_name"
            fi
        fi

        log_success "$bin_name installed → $DEST/$bin_name"
    done

    maybe_add_path

    if [ "$VERIFY" -eq 1 ]; then
        echo ""
        for bin_name in "${BINARY_NAMES[@]}"; do
            if [ -x "$DEST/$bin_name" ]; then
                echo "  $("$DEST/$bin_name" --version 2>/dev/null || echo "$bin_name ready")"
            fi
        done
    fi

    echo ""
    echo "✓ repository-harness installed"
    echo ""
    echo "  Binaries:"
    for bin_name in "${BINARY_NAMES[@]}"; do
        echo "    $DEST/$bin_name"
    done
    echo ""
    echo "  Quick start:"
    echo "    harness-cli --help"
    echo "    harness-symphony --help"
}

# curl|bash safety: buffer entire script before executing
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    { main "$@"; }
fi
