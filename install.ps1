<#
.SYNOPSIS
    Install repository-harness binaries (harness-cli and harness-symphony) on Windows.

.DESCRIPTION
    Downloads and installs the prebuilt binaries from GitHub releases.
    Supports proxy, retry, checksum verification, and easy-mode PATH setup.

.PARAMETER Dest
    Install destination directory. Defaults to $env:USERPROFILE\.local\bin.

.PARAMETER Version
    Release tag to install. Defaults to latest.

.PARAMETER System
    Install to a system-wide location.

.PARAMETER EasyMode
    Add install directory to user PATH automatically.

.PARAMETER Verify
    Run --version after install.

.PARAMETER FromSource
    Build from source using cargo.

.PARAMETER Quiet
    Suppress non-error output.

.PARAMETER Uninstall
    Remove installed binaries.

.PARAMETER DryRun
    Preview without changes.

.PARAMETER Help
    Show help.

.EXAMPLE
    irm "https://raw.githubusercontent.com/quangdang46/repository-harness/main/install.ps1" | iex

.EXAMPLE
    irm "https://raw.githubusercontent.com/quangdang46/repository-harness/main/install.ps1" | iex
    # with args:
    irm "https://raw.githubusercontent.com/quangdang46/repository-harness/main/install.ps1" -OutFile install.ps1
    .\install.ps1 -Dest "C:\tools" -EasyMode -Verify
#>

param(
    [Alias("d")]
    [string]$Dest = "",

    [Alias("v")]
    [string]$Version = "",

    [Alias("s")]
    [switch]$System,

    [Alias("e")]
    [switch]$EasyMode,

    [Alias("ver")]
    [switch]$Verify,

    [Alias("src")]
    [switch]$FromSource,

    [Alias("q")]
    [switch]$Quiet,

    [Alias("u")]
    [switch]$Uninstall,

    [Alias("dry")]
    [switch]$DryRun,

    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Config
$Script:Owner = "quangdang46"
$Script:Repo = "repository-harness"
$Script:BinaryNames = @("harness-cli", "harness-symphony")
$Script:ApiUrl = "https://api.github.com/repos/$Script:Owner/$Script:Repo"

# Resolve destination
if ([string]::IsNullOrWhiteSpace($Dest)) {
    if ($System) {
        $Script:Dest = "$env:SystemRoot\System32"
    } else {
        $Script:Dest = "$HOME\.local\bin"
    }
} else {
    $Script:Dest = $Dest
}

# Help
if ($Help) {
    Write-Host @"
Usage: install.ps1 [options]

Install repository-harness binaries from GitHub releases.

Options:
  -Dest <path>       Install destination (default: ~\.local\bin)
  -Version <tag>     Release tag (default: latest)
  -System            Install to System32
  -EasyMode          Auto-add to user PATH
  -Verify            Run --version after install
  -FromSource        Build from source with cargo
  -Quiet             Suppress non-error output
  -Uninstall         Remove installed binaries
  -DryRun            Preview without changes
  -Help              Show this help
"@
    exit 0
}

# Logging functions
function Write-Step([string]$Message) {
    if (-not $Quiet) { Write-Host "[$Script:Repo] $Message" }
}
function Write-Warn([string]$Message) {
    Write-Host "[$Script:Repo] WARN: $Message" -ForegroundColor Yellow
}
function Write-Success([string]$Message) {
    if (-not $Quiet) { Write-Host "✓ $Message" -ForegroundColor Green }
}
function Fail([string]$Message) {
    throw "ERROR: $Message"
}

function Resolve-LatestVersion {
    if (-not [string]::IsNullOrWhiteSpace($Version)) { return $Version }

    Write-Step "Resolving latest version..."
    try {
        $release = Invoke-RestMethod -Uri "$Script:ApiUrl/releases/latest" -TimeoutSec 30 -ErrorAction Stop
        return $release.tag_name
    } catch {
        Write-Warn "GitHub API failed, trying redirect..."
        try {
            $request = [System.Net.WebRequest]::Create("https://github.com/$Script:Owner/$Script:Repo/releases/latest")
            $request.AllowAutoRedirect = $false
            $response = $request.GetResponse()
            if ($response.StatusCode -eq 302) {
                $location = $response.Headers["Location"]
                if ($location -match '/tag/(.+)$') { return $matches[1] }
            }
        } catch {}
        Fail "Could not resolve latest version. Specify with -Version."
    }
}

function Add-ToPath {
    param([string]$PathToAdd)

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath.Split(";") -contains $PathToAdd) {
        return
    }
    $newPath = "$PathToAdd;$currentPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Warn "PATH updated. Restart your terminal or run: `$env:Path = `"$PathToAdd;`$env:Path`""
}

function Merge-JsonIntoFile {
    param([string]$FilePath, [string]$Key, [hashtable]$Value)

    $data = @{}
    if (Test-Path $FilePath) {
        try {
            $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
            if (-not [string]::IsNullOrWhiteSpace($content)) {
                $data = $content | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
        } catch {
            $data = @{}
        }
    }
    if (-not $data.ContainsKey($Key)) { $data[$Key] = @{} }
    foreach ($k in $Value.Keys) { $data[$Key][$k] = $Value[$k] }
    $json = $data | ConvertTo-Json -Depth 10
    Set-Content -Path $FilePath -Value $json -Encoding UTF8 -Force
}

# Uninstall
if ($Uninstall) {
    Write-Step "Uninstalling..."
    foreach ($bin in $Script:BinaryNames) {
        $path = Join-Path $Script:Dest $bin
        if ($Script:Dest -ne "C:\Windows\System32") {
            # Also remove .exe extension on Windows
            $exePath = Join-Path $Script:Dest "$bin.exe"
            if (Test-Path $exePath) { Remove-Item -Force $exePath; Write-Step "  removed $exePath" }
        }
        if (Test-Path $path) { Remove-Item -Force $path; Write-Step "  removed $path" }
    }
    Write-Success "Uninstalled"
    exit 0
}

# Main install
function Main {
    Write-Step "Platform: Windows | Destination: $Script:Dest"

    if ($DryRun) {
        Write-Host "[DRY RUN] Would install: $($Script:BinaryNames -join ', ') to $Script:Dest"
        exit 0
    }

    # Create destination if needed
    if (-not (Test-Path $Script:Dest)) {
        New-Item -ItemType Directory -Path $Script:Dest -Force | Out-Null
    }

    $tag = Resolve-LatestVersion
    Write-Step "Release: $tag"

    foreach ($bin in $Script:BinaryNames) {
        Write-Step "Installing $bin..."

        $ext = ".exe"
        $downloadUrl = "https://github.com/$Script:Owner/$Script:Repo/releases/download/$tag/${bin}-windows-x64${ext}"
        $destPath = Join-Path $Script:Dest "${bin}${ext}"
        $tempFile = Join-Path $env:TEMP "${bin}-${tag}${ext}"

        try {
            # Download
            if ($Quiet) {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -TimeoutSec 120 -ErrorAction Stop
            } else {
                Write-Host "  Downloading $downloadUrl ..."
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -TimeoutSec 120 -ErrorAction Stop
            }

            # Verify checksum if available
            $shaUrl = "$downloadUrl.sha256"
            try {
                $shaContent = (Invoke-WebRequest -Uri $shaUrl -TimeoutSec 10 -ErrorAction Stop).Content.Trim()
                $expectedHash = ($shaContent -split '\s+')[0]
                $actualHash = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLower()
                if ($expectedHash.ToLower() -ne $actualHash) {
                    Fail "Checksum mismatch for $bin"
                }
                Write-Step "  Checksum verified for $bin"
            } catch {
                Write-Warn "Checksum unavailable, skipping verification for $bin"
            }

            # Copy to destination
            if (Test-Path $destPath) {
                Remove-Item -Force $destPath -ErrorAction Stop
            }
            Move-Item -Path $tempFile -Destination $destPath -Force -ErrorAction Stop
            Write-Success "$bin installed → $destPath"
        } catch {
            Write-Warn "Binary download failed for $bin ($($_.Exception.Message))"
            if ($FromSource) {
                Write-Step "Building $bin from source..."
                if (-not (Get-Command "cargo" -ErrorAction SilentlyContinue)) {
                    Fail "cargo not found. Install Rust: https://rustup.rs"
                }
                $srcDir = Join-Path $env:TEMP "${Script:Repo}-src"
                if (-not (Test-Path $srcDir)) {
                    git clone --depth 1 "https://github.com/$Script:Owner/$Script:Repo.git" $srcDir
                }
                $pkg = if ($bin -eq "harness-cli") { "harness-cli" } else { "harness-symphony" }
                Push-Location $srcDir
                try {
                    cargo build --release -p $pkg
                    Copy-Item "target/release/${bin}.exe" $destPath -Force
                } finally {
                    Pop-Location
                }
                Write-Success "$bin built and installed → $destPath"
            } else {
                Write-Warn "Skipping $bin. Use -FromSource to build from source."
            }
        }
    }

    # PATH setup
    if ($EasyMode) {
        Add-ToPath -PathToAdd $Script:Dest
    } else {
        Write-Warn "Add to PATH manually or re-run with -EasyMode"
        Write-Warn "  [Environment]::SetEnvironmentVariable('Path', '$Script:Dest;' + `$env:Path, 'User')"
    }

    # Verify
    if ($Verify) {
        Write-Host ""
        foreach ($bin in $Script:BinaryNames) {
            $binPath = Join-Path $Script:Dest "${bin}.exe"
            if (Test-Path $binPath) {
                try {
                    $ver = & $binPath --version 2>&1
                    Write-Host "  $ver"
                } catch {
                    Write-Host "  $bin ready"
                }
            }
        }
    }

    Write-Host ""
    Write-Success "repository-harness installed"
    Write-Host ""
    Write-Host "  Binaries:"
    foreach ($bin in $Script:BinaryNames) {
        Write-Host "    $(Join-Path $Script:Dest "${bin}.exe")"
    }
    Write-Host ""
    Write-Host "  Quick start:"
    Write-Host "    harness-cli --help"
    Write-Host "    harness-symphony --help"
}

Main
