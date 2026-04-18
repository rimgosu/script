#!/bin/bash

# 1. nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# 2. ~/.zshrc에 nvmrc 자동 로드 설정 추가 (중복 방지)
if ! grep -q "load-nvmrc" ~/.zshrc; then
  cat >> ~/.zshrc << 'EOF'

# nvm auto-switch
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path=".nvmrc"
  if [[ -f "$nvmrc_path" ]]; then
    nvm use
  elif [[ $commands[nvm] ]]; then
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
EOF
fi

echo "nvm 설치 완료. 터미널을 재시작하거나 'source ~/.zshrc' 를 실행하면 적용됩니다."
