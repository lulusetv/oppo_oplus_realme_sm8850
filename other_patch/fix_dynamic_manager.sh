#!/bin/sh
# 修复 BakaSU 上游缺陷：KSU_IOCTL_DYNAMIC_MANAGER 的权限判定为 only_root，
# 导致已加冕的管理器（uid != 0）调用时被拒：
#   KernelSU: ksu ioctl: permission denied for cmd=0xc0004b67 uid=10169
# 本脚本仅把该接口改为 manager_or_root，其余 6 处 only_root 保持不变。
set -e
DISP="${1:-./KernelSU/kernel/supercall/dispatch.c}"

if [ ! -f "$DISP" ]; then
  echo "[fixdm] ERROR: 找不到 $DISP"
  exit 1
fi

echo "[fixdm] 修改前:"
grep -n "KSU_IOCTL_DYNAMIC_MANAGER" "$DISP" || true

python3 - "$DISP" <<'PYFIX'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
before = s.count('only_root')
pat = re.compile(r'(\.cmd\s*=\s*KSU_IOCTL_DYNAMIC_MANAGER\s*,[^}]*?\.perm_check\s*=\s*)only_root')
new, n = pat.subn(r'\1manager_or_root', s, count=1)
if n != 1:
    print('[fixdm] FAIL: 匹配到 %d 处，预期 1 处，终止' % n)
    sys.exit(1)
open(p, 'w', encoding='utf-8').write(new)
print('[fixdm] OK: DYNAMIC_MANAGER 已改为 manager_or_root')
print('[fixdm] only_root 计数: %d -> %d (应少 1)' % (before, new.count('only_root')))
PYFIX

echo "[fixdm] 修改后:"
grep -n -A4 "KSU_IOCTL_DYNAMIC_MANAGER" "$DISP" | head -8

if grep -q 'KSU_IOCTL_DYNAMIC_MANAGER' "$DISP"; then
  echo "[fixdm] 校验通过"
else
  echo "[fixdm] 校验失败"
  exit 1
fi
