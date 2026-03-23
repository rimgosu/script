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

sudo locale-gen ko_KR.UTF-8
grep -q 'LC_ALL=ko_KR.UTF-8' ~/.zshrc || echo 'export LC_ALL=ko_KR.UTF-8' >> ~/.zshrc
grep -q "PROMPT='%n@%m '" ~/.zshrc || cat >> ~/.zshrc << 'EOF'
PROMPT='%n@%m '$PROMPT
EOF

zsh -c "source ~/.zshrc"
sudo chsh -s $(which zsh) $(whoami)
echo "zsh 설치 완료. 'exit' 후 다시 접속하면 zsh가 적용됩니다."