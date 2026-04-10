명령어 묶음
## user 추가

```bash
sudo useradd -m rimgosu
sudo passwd rimgosu
sudo usermod -aG sudo rimgosu
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
