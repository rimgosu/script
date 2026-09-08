#!/bin/sh
# 키 리매핑 (idempotent — 몇 번 실행해도 항상 최신 매핑이 즉시 적용됨)
#  - 오른쪽 Cmd(0x7000000e7)    -> F18(0x70000006d)
#  - Application 키(0x700000065) -> fn/Globe(0xff00000003)
#  - 오른쪽 Option(0x7000000e6)  -> Del/forward delete(0x70000004c)
#      * Mac에는 물리 Del 키가 없다. fn+Backspace는 물리적으로 Backspace 키라
#        브라우저/앱이 보는 event.code가 'Backspace'로 남아서 진짜 Del로 안 간다.
#        (NanoKVM 같은 KVM에서 BIOS/타겟에 Del을 보낼 때 문제가 됨)

mkdir -p /Users/Shared/bin

# 매핑 적용 스크립트 생성
cat <<'EOF' > /Users/Shared/bin/userkeymapping
#!/bin/sh
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000e7,"HIDKeyboardModifierMappingDst":0x70000006d},{"HIDKeyboardModifierMappingSrc":0x700000065,"HIDKeyboardModifierMappingDst":0xff00000003},{"HIDKeyboardModifierMappingSrc":0x7000000e6,"HIDKeyboardModifierMappingDst":0x70000004c}]}'
EOF
chmod 755 /Users/Shared/bin/userkeymapping

# 부팅 시 자동 적용되도록 LaunchAgent 등록
cat <<'PLIST' > /tmp/userkeymapping.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>userkeymapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/Shared/bin/userkeymapping</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
sudo mv /tmp/userkeymapping.plist /Library/LaunchAgents/userkeymapping.plist
sudo chown root /Library/LaunchAgents/userkeymapping.plist

# 이미 로드돼 있으면 unload 후 다시 load (재실행 시 최신 plist 반영)
sudo launchctl unload /Library/LaunchAgents/userkeymapping.plist 2>/dev/null
sudo launchctl load /Library/LaunchAgents/userkeymapping.plist

# 재부팅 없이 즉시 적용
/Users/Shared/bin/userkeymapping
