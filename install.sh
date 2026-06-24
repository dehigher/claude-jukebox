#!/bin/bash
# install.sh - Install claude-jukebox skill and scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing claude-jukebox..."

# Copy control scripts
mkdir -p ~/.claude/bin
cp "$SCRIPT_DIR/bin/musicctl.sh" ~/.claude/bin/
cp "$SCRIPT_DIR/bin/music-status.sh" ~/.claude/bin/
chmod +x ~/.claude/bin/musicctl.sh ~/.claude/bin/music-status.sh
echo "  ✓ Scripts installed to ~/.claude/bin/"

# Install skill
mkdir -p ~/.claude/skills/claude-jukebox
cp "$SCRIPT_DIR/skills/SKILL.md" ~/.claude/skills/claude-jukebox/
echo "  ✓ Skill installed to ~/.claude/skills/claude-jukebox/"

# Create music directory
mkdir -p ~/Music/driving
echo "  ✓ Music directory: ~/Music/driving/"

# Check settings.json for statusLine
if [ -f ~/.claude/settings.json ]; then
    if grep -q "statusLine" ~/.claude/settings.json; then
        echo "  ✓ statusLine already configured in settings.json"
    else
        echo ""
        echo "  ⚠ Add the following to ~/.claude/settings.json:"
        echo ""
        echo '  "statusLine": {'
        echo '    "type": "command",'
        echo '    "command": "~/.claude/bin/music-status.sh",'
        echo '    "refreshInterval": 1'
        echo '  }'
        echo ""
    fi
else
    echo "  ⚠ ~/.claude/settings.json not found. Create it with statusLine config."
fi

# Check dependencies
echo ""
if command -v mpv &>/dev/null; then
    echo "  ✓ mpv found: $(mpv --version | head -1)"
else
    echo "  ✗ mpv not found — install with: brew install mpv"
fi

if command -v python3 &>/dev/null; then
    echo "  ✓ python3 found"
else
    echo "  ✗ python3 not found"
fi

echo ""
echo "Done! Restart Claude Code, then use /jukebox play to start."
