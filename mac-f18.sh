mkdir -p /Users/Shared/bin

# 키 리매핑 스크립트 생성
#  - 오른쪽 Cmd(0x7000000e7) -> F18(0x70000006d)
#  - Application 키(0x700000065) -> fn/Globe(0xff00000003)
cat <<'EOF' > /Users/Shared/bin/userkeymapping
#!/bin/sh
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000e7,"HIDKeyboardModifierMappingDst":0x70000006d},{"HIDKeyboardModifierMappingSrc":0x700000065,"HIDKeyboardModifierMappingDst":0xff00000003}]}'
EOF
chmod 755 /Users/Shared/bin/userkeymapping

# 부팅 시 자동 적용되도록 LaunchAgent 등록
sudo cat <<: >/Users/Shared/bin/userkeymapping.plist
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
:
sudo mv /Users/Shared/bin/userkeymapping.plist /Library/LaunchAgents/userkeymapping.plist
sudo chown root /Library/LaunchAgents/userkeymapping.plist
sudo launchctl load /Library/LaunchAgents/userkeymapping.plist
