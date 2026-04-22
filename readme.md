자주 사용하는 명령어 묶음

## user 추가

```bash
sudo useradd -m rimgosu
sudo passwd rimgosu
sudo usermod -aG sudo rimgosu # docker 같이 자주 사용하는 것도 권한 추가
```

## install-docker-ubuntu

ubuntu 22.04, 24.04에서 docker 설치

- install

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-docker-ubuntu.sh | bash
```

## install-zsh

- install

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-zsh.sh | bash
```

## install-nvm

zsh 환경에서 nvm 설치 및 `.nvmrc` 자동 로드 설정

- install

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-nvm.sh | zsh
```

## install another apps

- install claude code

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

- install tailscale

```sh
curl -fsSL https://tailscale.com/install.sh | sh
```
