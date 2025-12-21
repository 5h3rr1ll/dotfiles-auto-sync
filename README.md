# Dotfiles Auto Sync

**macOS-only** automated dotfiles synchronization system using LaunchAgent and yadm.

## Overview

**Platform**: macOS only (uses LaunchAgent for background automation)
**Git Platform**: Works with any git platform (GitHub, GitLab, Gitea, Bitbucket, self-hosted)

**The key advantage**: Your dotfiles are automatically backed up to your git repository **without any manual intervention**. Every time you modify your shell configuration, the changes are instantly committed and pushed.

This system uses macOS LaunchAgent to watch your dotfiles and automatically commit/push them to a git repository managed by [yadm](https://yadm.io/) (Yet Another Dotfiles Manager).

**No more forgetting to commit your dotfiles!** Changes are automatically backed up when files are modified, plus daily as a safety net.

## Why Use This?

✅ **Truly Automatic** - Set it and forget it. Your dotfiles are continuously backed up
✅ **Never Lose Configuration** - Every change is versioned in git
✅ **Instant Sync** - File changes trigger immediate backup
✅ **Safety Net** - Daily backups even if file watch misses something
✅ **Zero Maintenance** - Runs silently in the background via LaunchAgent

## Quick Start

```bash
# Install the auto-sync system
./dotfiles-auto-sync install

# That's it! Your dotfiles are now automatically synced.

# Optional: Check status
./dotfiles-auto-sync status

# Optional: View logs
./dotfiles-auto-sync logs

# Optional: Manually trigger a sync
./dotfiles-auto-sync sync

# Optional: Uninstall
./dotfiles-auto-sync uninstall
```

## Project Structure

```
dotfiles-auto-sync/
├── dotfiles-auto-sync       # Main entry point (executable)
├── lib/                      # Internal libraries (sourced, not executed)
│   ├── logger.sh            # Colored logging functions
│   ├── deps.sh              # Dependency checking
│   ├── backup-core.sh       # Backup logic
│   ├── install-core.sh      # Installation logic
│   └── uninstall-core.sh    # Uninstallation logic
├── config/                   # Configuration files
│   └── de.sherrill.dotfiles-auto-sync.plist.template  # LaunchAgent template
└── README.md
```

This structure follows [CLI best practices](../CLI-BEST-PRACTICES.md) with a single entry point and hidden implementation complexity.

**Note:** The LaunchAgent plist is a template with placeholders (`{{HOME}}`, `{{DOTFILES_BACKUP_PATH}}`) that are dynamically replaced during installation to create `de.sherrill.dotfiles-auto-sync.plist`. This makes the project portable - anyone can clone and use it regardless of their username or installation path.

## What Gets Backed Up

- `~/.zshrc` - Zsh configuration
- `~/.zprofile` - Zsh profile
- `~/.config/starship.toml` - Starship prompt configuration

## How It Works

The LaunchAgent (`de.sherrill.dotfiles-auto-sync.plist`) triggers the sync in two ways:

1. **File watching**: Automatically runs when any watched file changes
2. **Scheduled**: Runs daily at 12:00 PM (noon) as a safety net

When triggered, the backup script:
1. Syncs with remote repository (fetch + pull --rebase)
2. Stashes any uncommitted changes if needed
3. Adds the dotfiles to yadm
4. Creates a commit with timestamp
5. Pushes changes to the remote repository
6. Logs all operations to `~/Library/Logs/de.sherrill.dotfiles-auto-sync.log`

## Requirements

**Operating System**: macOS (uses LaunchAgent - not compatible with Linux/Windows)

**Dependencies** (automatically installed):
- **Homebrew** - macOS package manager (installer can install this)
- **yadm** - Yet Another Dotfiles Manager (installer can install this)

**Prerequisites**:
- Git repository initialized with yadm
- Remote repository configured for push access (any git platform)
- SSH keys configured for your git platform (installer verifies this)

## Installation

### Automated Installation (Recommended)

The install script will:
- ✓ Check and install Homebrew (if needed)
- ✓ Check and install yadm (if needed)
- ✓ Verify yadm is initialized and configured
- ✓ Check SSH keys and GitHub connectivity
- ✓ Install and load the LaunchAgent
- ✓ Provide helpful guidance for any missing configuration

```bash
cd dotfiles-auto-sync
./dotfiles-auto-sync install
```

The installer will guide you through the setup process and verify all requirements.

### Manual yadm Setup (If Not Already Configured)

If you haven't set up yadm yet:

```bash
# Initialize yadm repository
yadm init

# Add your remote repository (choose your platform)
# GitHub:
yadm remote add origin git@github.com:yourusername/dotfiles.git
# GitLab:
yadm remote add origin git@gitlab.com:yourusername/dotfiles.git
# Gitea/self-hosted:
yadm remote add origin git@your-server:yourusername/dotfiles.git

# Add files
yadm add ~/.zshrc ~/.zprofile ~/.config/starship.toml

# Initial commit
yadm commit -m "Initial dotfiles backup"

# Push to remote
yadm push -u origin main
```

### SSH Key Setup (If Not Already Configured)

If you don't have SSH keys set up:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub | pbcopy

# Then add to your git platform:
# GitHub:     https://github.com/settings/keys
# GitLab:     https://gitlab.com/-/profile/keys
# Gitea:      https://your-server/user/settings/keys
# Bitbucket:  https://bitbucket.org/account/settings/ssh-keys/
```

## Usage

### Commands

```bash
dotfiles-auto-sync install    # Install and configure the auto-sync system
dotfiles-auto-sync sync       # Run sync now (manual trigger)
dotfiles-auto-sync uninstall  # Remove the auto-sync system
dotfiles-auto-sync status     # Check sync status
dotfiles-auto-sync logs       # View sync logs
dotfiles-auto-sync help       # Show help message
dotfiles-auto-sync version    # Show version
```

### Options

```bash
-h, --help                    # Show help
-v, --version                 # Show version
```

## Uninstallation

### Automated Uninstallation (Recommended)

```bash
./dotfiles-auto-sync uninstall
```

The uninstaller will:
- Unload and remove the LaunchAgent
- Optionally remove log files
- Preserve your yadm repository and dotfiles

## Monitoring

### Check LaunchAgent Status

```bash
./dotfiles-auto-sync status

# Or manually:
launchctl list | grep de.sherrill.dotfiles-auto-sync
```

### View Logs

```bash
# Using the tool
./dotfiles-auto-sync logs

# Or manually:
tail -f ~/Library/Logs/de.sherrill.dotfiles-auto-sync.log
```

### Test Sync Manually

```bash
./dotfiles-auto-sync sync
```

## Troubleshooting

### Common Issues

**"yadm not found"**
- Install yadm: `brew install yadm`
- Verify installation: `which yadm`
  - Intel Mac: `/usr/local/bin/yadm`
  - Apple Silicon: `/opt/homebrew/bin/yadm`

**"Failed to push to remote repository"**
- Verify yadm remote is configured: `yadm remote -v`
- Test manual push: `yadm push`
- Check SSH keys or authentication

**LaunchAgent not triggering**
- Check if loaded: `./dotfiles-auto-sync status`
- Verify file permissions: `ls -l dotfiles-auto-sync` (should be executable)
- Check system logs: `log show --predicate 'subsystem == "com.apple.launchd"' --last 1h`

**Merge conflicts after remote changes**
- The sync script automatically stashes local changes before pulling
- If conflicts occur, they'll be logged and you can resolve manually with `yadm`

### Reload LaunchAgent After Changes

```bash
launchctl unload ~/Library/LaunchAgents/de.sherrill.dotfiles-auto-sync.plist
launchctl load ~/Library/LaunchAgents/de.sherrill.dotfiles-auto-sync.plist
```

## Exit Codes

The backup script uses the following exit codes:

- `0` - Success (changes backed up and pushed)
- `1` - Error (backup failed)
- `2` - No changes (nothing to commit, not considered a failure)

## Customization

### Changing Watched Files

To add or remove files from automatic syncing:

1. Edit `~/Library/LaunchAgents/de.sherrill.dotfiles-auto-sync.plist`
2. Modify the `WatchPaths` section:

```xml
<key>WatchPaths</key>
<array>
    <string>/Users/yourname/.zshrc</string>
    <string>/Users/yourname/.zprofile</string>
    <string>/Users/yourname/.config/starship.toml</string>
    <!-- Add more paths here -->
</array>
```

3. Update the config file at `dotfiles-auto-sync/config/files.conf` to match
4. Reload the LaunchAgent (see schedule customization above)

### Changing Sync Schedule

The default schedule is **daily at 12:00 PM (noon)**. To customize:

1. Edit `~/Library/LaunchAgents/de.sherrill.dotfiles-auto-sync.plist`
2. Modify the `StartCalendarInterval` section:

```xml
<!-- Default: Daily at 12:00 PM (noon) -->
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>12</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

**Common schedule examples:**

```xml
<!-- Every 6 hours -->
<key>StartInterval</key>
<integer>21600</integer>

<!-- Daily at 9 AM -->
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>

<!-- Multiple times per day (8 AM, 12 PM, 6 PM) -->
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Hour</key>
        <integer>8</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Hour</key>
        <integer>12</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Hour</key>
        <integer>18</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

3. Reload the LaunchAgent:
```bash
launchctl unload ~/Library/LaunchAgents/de.sherrill.dotfiles-auto-sync.plist
launchctl load ~/Library/LaunchAgents/de.sherrill.dotfiles-auto-sync.plist
```

**Note:** File watching (WatchPaths) triggers syncs immediately on changes, so scheduled syncs are just a safety net.

## Architecture

This tool follows CLI best practices:

1. **Single entry point** - `dotfiles-auto-sync` (no extension)
2. **Subcommand pattern** - `dotfiles-auto-sync <command>` for clear intent
3. **Hidden complexity** - Implementation in `lib/` directory
4. **Clear permissions** - Only entry point is executable
5. **Dependency checking** - Verifies requirements at startup
6. **User-friendly output** - Colored logs with symbols

See [CLI-BEST-PRACTICES.md](../CLI-BEST-PRACTICES.md) for more details on the design principles.

## Links

- [yadm documentation](https://yadm.io/)
- [LaunchAgent documentation](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [LaunchControl app](https://www.soma-zone.com/LaunchControl/) - GUI for managing LaunchAgents
- [CLI Best Practices](../CLI-BEST-PRACTICES.md) - Design principles guide
