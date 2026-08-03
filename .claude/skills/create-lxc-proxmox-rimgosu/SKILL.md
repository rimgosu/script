---
name: create-lxc-proxmox-rimgosu
description: proxmox-rimgosu 호스트에 SSH로 들어가 Ubuntu LXC를 생성한다. CPU/RAM/SSD·HDD 크기/호스트명을 입력받아 pct create로 컨테이너를 만들고, 발급된 private IP를 ~/.ssh/config에 등록한 뒤 스펙과 접속 정보를 안내한다. 사용자가 "lxc 만들어줘", "proxmox에 컨테이너 생성" 등을 요청할 때 사용.
---

# create-lxc-proxmox-rimgosu

proxmox-rimgosu(`~/.ssh/config`의 `proxmox-rimgosu`, tailscale 100.90.80.100)에
Ubuntu LXC를 생성하고 접속까지 세팅하는 스킬.

## 스토리지 구성 (전제)

| 스토리지 | 종류 | 용도 |
|---|---|---|
| `local-lvm` | lvmthin (NVMe SSD) | rootfs — OS 설치 |
| `hdd-thin` | lvmthin (HDD 1.8T) | `/data` 마운트 — 대용량 데이터 |

`pvesm status`로 두 스토리지가 active인지 먼저 확인한다.

## 1. 필수 입력값 확인 (누락 시 반드시 질문)

아래 5가지는 **필수**다. 사용자 요청에서 하나라도 빠졌으면 추측하지 말고
AskUserQuestion으로 물어본 뒤 진행한다:

1. **CPU** — 코어 수 (예: 4)
2. **RAM** — 메모리 크기 MB 또는 GB (예: 8G → `--memory 8192`)
3. **SSD / HDD 크기** — rootfs(SSD) GB + /data(HDD) GB. HDD 0이면 mp0 생략
4. **LXC host 이름** — 컨테이너 hostname (ssh config 별칭으로도 사용)
5. **root 비밀번호** — proxmox 웹 UI 콘솔 로그인용. 반드시 물어본다
   (임의로 정하지 말 것). 기존 컨테이너와 통일하고 싶어하는 경우가 많으니
   "기존과 동일하게" 같은 답도 그대로 수용한다

swap은 별도 요청 없으면 RAM의 1/4 정도로 기본 설정.

## 2. 사전 확인

```bash
ssh proxmox-rimgosu "pvesm status; pvesh get /cluster/nextid; pveam list local | grep -i ubuntu"
```

- VMID는 `nextid` 결과 사용
- Ubuntu 템플릿이 없으면 다운로드:

```bash
ssh proxmox-rimgosu "pveam update && pveam available --section system | grep -i ubuntu"
ssh proxmox-rimgosu "pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
```

(더 최신 standard 템플릿이 있으면 그것을 쓴다)

## 3. LXC 생성

로컬 SSH 공개키를 컨테이너에 주입해 비번 없이 접속되게 한다:

```bash
scp ~/.ssh/id_ed25519.pub proxmox-rimgosu:/tmp/ct<VMID>.pub
ssh proxmox-rimgosu "pct create <VMID> local:vztmpl/<TEMPLATE> \
  --hostname <HOSTNAME> \
  --rootfs local-lvm:<SSD_GB> \
  --mp0 hdd-thin:<HDD_GB>,mp=/data \
  --cores <CORES> --memory <RAM_MB> --swap <SWAP_MB> \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --nameserver "1.1.1.1 8.8.8.8" \
  --unprivileged 1 --features nesting=1 \
  --ssh-public-keys /tmp/ct<VMID>.pub \
  --start 1"
```

- HDD를 안 쓰면 `--mp0` 줄 생략
- `--nameserver`는 **생략하면 안 된다**. 빼면 컨테이너가 호스트의
  `/etc/resolv.conf`를 상속하는데, proxmox-rimgosu 호스트는 tailscale MagicDNS
  (`100.100.100.100`)를 쓴다. 컨테이너 안에는 tailscaled가 없으므로 그 DNS는
  절대 응답하지 않고 `apt update`가 죽는다 (아래 트러블슈팅 참고)

### 3-1. root 비번 설정 (필수)

템플릿 기본값은 root 비번이 **`*`(잠김)** 이라 웹 UI 콘솔에서 뭘 입력해도
로그인이 안 된다. `--ssh-public-keys`를 넣어도 콘솔은 별개이므로 반드시 설정한다.

비번을 셸 명령줄에 넣으면 `!`, `$`, `` ` `` 등이 셸에 먹히므로 **stdin으로 넘긴다**:

```bash
ssh proxmox-rimgosu "pct exec <VMID> -- chpasswd" <<< 'root:<PASSWORD>'
```

설정 후 해시 대조로 검증한다 (오타·이스케이프 사고 방지, `True`면 성공):

```bash
ssh proxmox-rimgosu "pct exec <VMID> -- python3 -c \"import crypt,spwd,sys;h=spwd.getspnam('root').sp_pwdp;print(crypt.crypt(sys.stdin.read().strip(),h)==h)\"" <<< '<PASSWORD>'
```

(Ubuntu 24.04 = python 3.12 기준. `crypt`/`spwd`는 3.13에서 제거되므로
그보다 최신 템플릿에서는 `chpasswd` 종료코드로만 확인)

기존 컨테이너 비번을 한 번에 통일하려면 `pct list`의 VMID를 순회하며 같은 명령을 돌린다.

## 4. private IP 확인 및 ~/.ssh/config 갱신

```bash
ssh proxmox-rimgosu "sleep 5; pct exec <VMID> -- ip -br a | grep eth0"
```

DHCP로 받은 IP(예: 192.168.200.141)를 `~/.ssh/config`에 등록한다.
**같은 Host 별칭이 이미 있으면 새로 추가하지 말고 그 블록의 HostName만 갱신**한다:

```
Host <HOSTNAME>
  HostName <PRIVATE_IP>
  User root
  ProxyJump proxmox-rimgosu
```

- ProxyJump를 넣는 이유: 192.168.200.x는 proxmox LAN 대역이라 원격(tailscale)에서
  proxmox를 점프호스트로 거쳐야 함. tailscale 서브넷 라우터(192.168.200.0/24 광고)가
  승인돼 있으면 직접 접속도 되지만, ProxyJump는 어느 경우든 동작하므로 기본으로 넣는다.
- 접속 검증 (known_hosts 재사용 충돌 나면 `ssh-keygen -R <IP>` 후 재시도):

```bash
ssh -o StrictHostKeyChecking=accept-new <HOSTNAME> "hostname; df -h / /data"
```

## 5. 최종 안내 (필수 출력)

작업을 마치면 아래 3가지를 반드시 사용자에게 정리해 보여준다:

1. **LXC 스펙** — VMID, hostname, CPU/RAM/swap, SSD·HDD 크기, unprivileged/nesting 여부
2. **~/.ssh/config 변경 사항** — 추가/수정된 Host 블록 내용 그대로
3. **접속 정보** — `ssh <HOSTNAME>` (점프 경유), 직접 IP(`ssh root@<PRIVATE_IP>`,
   tailscale 서브넷 라우터 승인 시), root 비번

## 트러블슈팅

- unprivileged LXC에서 docker/runc가 `open sysctl ... reopen fd: permission denied`로
  실패하면 `/etc/pve/lxc/<VMID>.conf`에 두 줄 추가 후 `pct reboot <VMID>`:
  ```
  lxc.apparmor.profile: unconfined
  lxc.mount.entry: tmpfs sys/kernel/security tmpfs ro,nosuid,nodev,noexec,create=dir 0 0
  ```
  (두 번째 줄은 unconfined 후 노출되는 securityfs를 가려 dockerd의 AppArmor 2차 에러를 스킵)
- `pct exec`에서 IP가 아직 없으면 DHCP 대기 — 몇 초 후 재시도
- **`apt update`가 `Temporary failure in name resolution`으로 실패** (단
  `ping 8.8.8.8`은 정상 → 라우팅은 살아있고 DNS만 죽은 것):
  컨테이너 `/etc/resolv.conf`에 `nameserver 100.100.100.100`(tailscale MagicDNS)만
  들어있는 경우다. `pct config <VMID>`에 `nameserver`가 없어서 호스트 설정을
  상속한 것이고, 컨테이너에는 tailscaled가 없으니 응답할 수 없다.
  호스트 `/etc/resolv.conf`는 건드리지 말고(호스트는 tailscaled가 있어 정상 동작)
  컨테이너 쪽만 고친다:
  ```bash
  # 영구 (재부팅 후에도 유지)
  ssh proxmox-rimgosu "pct set <VMID> --nameserver '1.1.1.1 8.8.8.8'"
  # 재부팅 없이 즉시 반영
  ssh <HOSTNAME> "printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' | sudo tee /etc/resolv.conf"
  ```
  DNS 실패로 매달려 있던 이전 `apt update`가 `/var/lib/apt/lists/lock`을 잡고 있으면
  (`E: Could not get lock ... held by process <PID>`) 그 PID를 kill 후 재시도한다.
