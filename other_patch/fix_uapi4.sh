#!/bin/sh
# 把内核源码的 uapi 版本改回 4，与管理器 APK 内置的 ksud 匹配
# 幂等：已经是 4 则 SKIP
set -u

CANDIDATES="$1 ./KernelSU/uapi/supercall.h ./uapi/supercall.h ./KernelSU/kernel/uapi/supercall.h"
F=""
for c in $CANDIDATES; do
    if [ -n "$c" ] && [ -f "$c" ]; then F="$c"; break; fi
done

if [ -z "$F" ]; then
    echo "[uapi4] ERROR: 找不到 supercall.h"
    exit 1
fi

echo "[uapi4] 目标: $F"
echo "[uapi4] 改前:"
grep -n 'KERNEL_SU_UAPI_VERSION' "$F" || true

CUR=$(grep -oE 'KERNEL_SU_UAPI_VERSION = [0-9]+' "$F" | head -1 | grep -oE '[0-9]+$')
echo "[uapi4] 当前值: $CUR"

if [ "$CUR" = "4" ]; then
    echo "[uapi4] SKIP: 已经是 4"
    exit 0
fi

sed -i 's/KERNEL_SU_UAPI_VERSION = [0-9]\+/KERNEL_SU_UAPI_VERSION = 4/' "$F"

echo "[uapi4] 改后:"
grep -n 'KERNEL_SU_UAPI_VERSION' "$F" || true

# 硬校验
if grep -q 'KERNEL_SU_UAPI_VERSION = 4' "$F"; then
    echo "[uapi4] OK"
    exit 0
else
    echo "[uapi4] ERROR: 替换失败"
    exit 1
fi
