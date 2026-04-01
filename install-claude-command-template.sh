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

MODE="requirement"
ARGS=()

# Parse flags
for arg in "$@"; do
    if [ "$arg" = "--plan" ]; then
        MODE="plan"
    else
        ARGS+=("$arg")
    fi
done

# Use "command" as default description if no arguments given
if [ ${#ARGS[@]} -eq 0 ]; then
    DESCRIPTION="command"
else
    DESCRIPTION="$(echo "${ARGS[*]}" | tr ' ' '_')"
fi

# Get current UTC timestamp in Z format
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

if [ "$MODE" = "plan" ]; then
    # Create docs/plans directory
    PLANS_DIR="docs/plans"
    REQ_DIR="docs/requirements"
    mkdir -p "$PLANS_DIR"

    REQ_FILENAME="r_${TIMESTAMP}_${DESCRIPTION}.md"
    REQ_FILEPATH="${REQ_DIR}/${REQ_FILENAME}"
    PLAN_FILENAME="p_${TIMESTAMP}_${DESCRIPTION}.md"
    PLAN_FILEPATH="${PLANS_DIR}/${PLAN_FILENAME}"

    # Create requirement file with plan link
    mkdir -p "$REQ_DIR"
    cat > "$REQ_FILEPATH" << REQ_EOF
## Plan

The implementation plan for this requirement will be written in the following document:

- [\`${PLAN_FILENAME}\`](../plans/${PLAN_FILENAME})
REQ_EOF
    echo "Created: $REQ_FILEPATH"

    cat > "$PLAN_FILEPATH" << PLAN_EOF
## Source Requirement

This plan is based on the following requirement document:

- [\`${REQ_FILENAME}\`](../requirements/${REQ_FILENAME})
PLAN_EOF

    echo "Created: $PLAN_FILEPATH"
else
    # Create docs/requirements directory
    REQ_DIR="docs/requirements"
    mkdir -p "$REQ_DIR"

    FILENAME="r_${TIMESTAMP}_${DESCRIPTION}.md"
    FILEPATH="${REQ_DIR}/${FILENAME}"

    touch "$FILEPATH"
    echo "Created: $FILEPATH"
fi
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
echo "  cct                     -> docs/requirements/r_2026-04-01T10:00:00Z_command.md"
echo "  cct create session      -> docs/requirements/r_2026-04-01T10:00:00Z_create_session.md"
echo "  cct --plan create session -> docs/requirements/r_...md + docs/plans/p_...md"
