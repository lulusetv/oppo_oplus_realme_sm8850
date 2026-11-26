#!/bin/sh
# 强制 KSU uapi 版本 = 4，兼容管理器 APK 内置的 ksud
# 用法: sh fix_uapi4.sh <supercall.h 路径>
F="${1:-./uapi/supercall.h}"
echo "[uapi4] pwd=$(pwd)"
echo "[uapi4] target=$F"

if [ ! -f "$F" ]; then
  echo "[uapi4] ERROR: 文件不存在，列出候选:"
  find . -name supercall.h 2>/dev/null | head -10
  exit 1
fi

echo "[uapi4] 改前: $(grep 'KERNEL_SU_UAPI_VERSION' "$F" | head -1)"
sed -i 's/KERNEL_SU_UAPI_VERSION = [0-9][0-9]*/KERNEL_SU_UAPI_VERSION = 4/' "$F"
echo "[uapi4] 改后: $(grep 'KERNEL_SU_UAPI_VERSION' "$F" | head -1)"

# 铁证：打印文件 md5 和绝对路径，方便事后对比
realpath "$F" 2>/dev/null || readlink -f "$F" 2>/dev/null || echo "$F"
md5sum "$F"

if grep -q 'KERNEL_SU_UAPI_VERSION = 4' "$F"; then
  echo "[uapi4] OK"
else
  echo "[uapi4] FAIL"
  exit 1
fi
