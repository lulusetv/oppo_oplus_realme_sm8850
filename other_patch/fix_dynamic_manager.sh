#!/bin/sh
# 修复 BakaSU 上游缺陷：KSU_IOCTL_DYNAMIC_MANAGER 的 perm_check 为 only_root，
# 导致已加冕的管理器（uid != 0）调用时被拒：
#   KernelSU: ksu ioctl: permission denied for cmd=0xc0004b67 uid=10169
# 将该接口改为 manager_or_root，其余 only_root 保持不变。幂等：已修复则跳过。
set -e

CANDIDATES="$1 ./kernel/supercall/dispatch.c ./KernelSU/kernel/supercall/dispatch.c ./common/drivers/kernelsu/supercall/dispatch.c"

DISP=""
for c in $CANDIDATES; do
  if [ -n "$c" ] && [ -f "$c" ]; then
    DISP="$c"
    break
  fi
done

if [ -z "$DISP" ]; then
  echo "[fixdm] ERROR: 未找到 dispatch.c，当前目录: $(pwd)"
  ls -la ./kernel/supercall/dispatch.c ./KernelSU/kernel/supercall/dispatch.c 2>&1 || true
  exit 1
fi

echo "[fixdm] 目标文件: $DISP"

python3 - "$DISP" <<'PYFIX'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
before = s.count('only_root')

# 先在 DYNAMIC_MANAGER 块内判断当前值
blk = re.search(r'\.cmd\s*=\s*KSU_IOCTL_DYNAMIC_MANAGER\s*,[^}]*\}', s)
if not blk:
    print('[fixdm] FAIL: 找不到 KSU_IOCTL_DYNAMIC_MANAGER 条目')
    sys.exit(1)
block = blk.group(0)

if 'manager_or_root' in block:
    print('[fixdm] SKIP: 该接口已是 manager_or_root，无需修改')
    sys.exit(0)

pat = re.compile(r'(\.cmd\s*=\s*KSU_IOCTL_DYNAMIC_MANAGER\s*,[^}]*?\.perm_check\s*=\s*)only_root')
new, n = pat.subn(r'\1manager_or_root', s, count=1)
if n != 1:
    print('[fixdm] FAIL: 匹配 %d 处（预期 1 处）' % n)
    sys.exit(1)
open(p, 'w', encoding='utf-8').write(new)
print('[fixdm] only_root 计数: %d -> %d' % (before, new.count('only_root')))
PYFIX

echo "[fixdm] 结果:"
grep -n -A4 "KSU_IOCTL_DYNAMIC_MANAGER" "$DISP" | head -8

if grep -A4 "KSU_IOCTL_DYNAMIC_MANAGER" "$DISP" | grep -q 'manager_or_root'; then
  echo "[fixdm] OK 校验通过"
else
  echo "[fixdm] FAIL 校验失败"
  exit 1
fi
