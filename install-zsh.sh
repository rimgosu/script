#!/bin/bash
sudo apt update
sudo apt install -y zsh curl git

RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

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

if [ -n "$SUDO_USER" ]; then
    chown $SUDO_USER ~/.zshrc
fi

echo 'export LC_ALL=ko_KR.UTF-8' >> ~/.zshrc
cat >> ~/.zshrc << 'EOF'
PROMPT='%n@ '$PROMPT
EOF

source ~/.zshrc
echo "기본 셸을 zsh로 변경하려면 다음 명령어를 실행하세요:"
echo "  chsh -s \$(which zsh)"