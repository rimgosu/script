#!/bin/bash

# install-claude-command-template.sh
# Installs the 'cct' (Claude Command Template) command

set -e

# Reconnect stdin to terminal (required for curl | bash)
exec < /dev/tty

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="cct"

echo "=== Claude Command Template (cct) Installer ==="
echo ""
echo "Select your timezone offset:"
echo ""

# Build timezone list: UTC+00 ~ UTC+14, UTC-01 ~ UTC-12
TIMEZONES=()
for i in $(seq 0 14); do
    TIMEZONES+=("UTC+$(printf '%02d' $i)")
done
for i in $(seq 1 12); do
    TIMEZONES+=("UTC-$(printf '%02d' $i)")
done

for i in "${!TIMEZONES[@]}"; do
    printf "  [%2d] %s\n" "$i" "${TIMEZONES[$i]}"
done

echo ""
TOTAL=${#TIMEZONES[@]}
read -rp "Enter number [0-$((TOTAL - 1))]: " selection

# Validate input
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 0 ] || [ "$selection" -ge "$TOTAL" ]; then
    echo "Error: Invalid selection '$selection'"
    exit 1
fi

SELECTED_TZ="${TIMEZONES[$selection]}"
echo ""
echo "Selected timezone: $SELECTED_TZ"

# Parse sign and hours from selected timezone (e.g. "UTC+09" or "UTC-05")
SIGN=$(echo "$SELECTED_TZ" | grep -oE '[+-]')
HOURS_STR=$(echo "$SELECTED_TZ" | grep -oE '[0-9]+$')
HOURS_INT=$((10#$HOURS_STR))  # strip leading zero

if [ "$SIGN" = "+" ]; then
    OFFSET_SECONDS=$((HOURS_INT * 3600))
    OFFSET_DISPLAY="+$(printf '%02d' $HOURS_INT)"
else
    OFFSET_SECONDS=$((-HOURS_INT * 3600))
    OFFSET_DISPLAY="-$(printf '%02d' $HOURS_INT)"
fi

# Create install directory
mkdir -p "$INSTALL_DIR"

# Write the cct script
cat > "$INSTALL_DIR/$SCRIPT_NAME" << SCRIPT_EOF
#!/bin/bash

# cct - Claude Command Template creator
# Installed timezone offset: ${OFFSET_DISPLAY}

OFFSET_SECONDS=${OFFSET_SECONDS}
OFFSET_DISPLAY="${OFFSET_DISPLAY}"

# Use "command" as default description if no arguments given
if [ \$# -eq 0 ]; then
    DESCRIPTION="command"
else
    DESCRIPTION="\$(echo "\$*" | tr ' ' '_')"
fi

# Get current UTC epoch and apply offset
UTC_SECONDS=\$(date -u +%s)
LOCAL_SECONDS=\$((UTC_SECONDS + OFFSET_SECONDS))

# Format timestamp (macOS vs Linux)
if [[ "\$(uname)" == "Darwin" ]]; then
    TIMESTAMP="\$(date -r \$LOCAL_SECONDS '+%Y-%m-%dT%H:%M:%S')\${OFFSET_DISPLAY}"
else
    TIMESTAMP="\$(date -d "@\$LOCAL_SECONDS" '+%Y-%m-%dT%H:%M:%S')\${OFFSET_DISPLAY}"
fi

# Create .claude/commands directory if it doesn't exist
COMMANDS_DIR=".claude/commands"
if [ ! -d "\$COMMANDS_DIR" ]; then
    mkdir -p "\$COMMANDS_DIR"
    echo "Created directory: \$COMMANDS_DIR"
fi

# Create the markdown file
FILENAME="\${TIMESTAMP}_\${DESCRIPTION}.md"
FILEPATH="\${COMMANDS_DIR}/\${FILENAME}"

touch "\$FILEPATH"
echo "Created: \$FILEPATH"
SCRIPT_EOF

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo ""
echo "Installed: $INSTALL_DIR/$SCRIPT_NAME"

# Add INSTALL_DIR to PATH if not already there
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "$INSTALL_DIR is not in your PATH. Adding it now..."

    SHELL_CONFIG=""
    if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ "$(basename "$SHELL")" = "bash" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi

    if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Added by cct installer" >> "$SHELL_CONFIG"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
        echo "Added PATH entry to $SHELL_CONFIG"
        echo ""
        echo "Run the following to activate in the current session:"
        echo "  source $SHELL_CONFIG"
    else
        echo "Could not detect shell config. Please add the following to your shell profile manually:"
        echo ""
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
else
    echo "$INSTALL_DIR is already in PATH."
fi

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Usage:"
echo "  cct <description>"
echo "  cct create session    -> .claude/commands/$(TZ= date '+%Y-%m-%dT%H:%M:%S')${OFFSET_DISPLAY}_create_session.md"
echo ""
echo "Timezone: UTC${OFFSET_DISPLAY}"
