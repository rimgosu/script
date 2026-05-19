#!/bin/bash
set -e

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew가 없어서 먼저 설치합니다..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

brew install zsh git

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh 설치 실패. 네트워크 또는 git 상태 확인."
    exit 1
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

awk '
/^plugins=\(/ {
    print "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
    if (!/\)/) {
        while (getline > 0 && !/\)/) {}
    }
    next
}
{print}
' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc

grep -q 'LC_ALL=ko_KR.UTF-8' ~/.zshrc || echo 'export LC_ALL=ko_KR.UTF-8' >> ~/.zshrc
grep -q 'GH_AUTH_TOKEN_STORE=file' ~/.zshrc || echo 'export GH_AUTH_TOKEN_STORE=file' >> ~/.zshrc
grep -q "PROMPT='%n@%m '" ~/.zshrc || cat >> ~/.zshrc << 'EOF'
PROMPT='%n@%m '$PROMPT
EOF

BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ]; then
    if ! grep -qx "$BREW_ZSH" /etc/shells; then
        echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
    fi
    if [ "$(dscl . -read /Users/$(whoami) UserShell | awk '{print $2}')" != "$BREW_ZSH" ]; then
        chsh -s "$BREW_ZSH"
    fi
fi

echo "zsh 설치 완료. 'exit' 후 다시 접속하면 zsh가 적용됩니다."
