#!/bin/bash

# install-claude-command-template.sh
# Installs the 'cct' (Claude Command Template) command

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="cct"

echo "=== Claude Command Template (cct) Installer ==="
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"

# Write the cct script
cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'SCRIPT_EOF'
#!/bin/bash

# cct - Claude Command Template creator

# Use "command" as default description if no arguments given
if [ $# -eq 0 ]; then
    DESCRIPTION="command"
else
    DESCRIPTION="$(echo "$*" | tr ' ' '_')"
fi

# Get current UTC timestamp in Z format
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Create .claude/commands directory if it doesn't exist
COMMANDS_DIR=".claude/commands"
if [ ! -d "$COMMANDS_DIR" ]; then
    mkdir -p "$COMMANDS_DIR"
    echo "Created directory: $COMMANDS_DIR"
fi

# Create the markdown file
FILENAME="${TIMESTAMP}_${DESCRIPTION}.md"
FILEPATH="${COMMANDS_DIR}/${FILENAME}"

touch "$FILEPATH"
echo "Created: $FILEPATH"
SCRIPT_EOF

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

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
        echo "Please add the following to your shell profile manually:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
else
    echo "$INSTALL_DIR is already in PATH."
fi

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Usage:"
echo "  cct                -> .claude/commands/2026-02-02T10:00:00Z_command.md"
echo "  cct create session -> .claude/commands/2026-02-02T10:00:00Z_create_session.md"
