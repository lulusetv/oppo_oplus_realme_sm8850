#!/bin/sh
# 把 KSU uapi 版本改回 4，与管理器 APK 内置的 ksud 匹配
# 用法: sh fix_uapi4.sh [目标文件路径]
# 幂等：已经是 4 则跳过

F="${1:-./uapi/supercall.h}"

if [ ! -f "$F" ]; then
    echo "[uapi4] ERROR: 文件不存在 -> $F"
    echo "[uapi4] 当前目录: $(pwd)"
    echo "[uapi4] 候选文件:"
    find . -maxdepth 4 -name supercall.h 2>/dev/null | head -5
    exit 1
fi

echo "[uapi4] 目标: $F"
echo "[uapi4] 改前:"
grep -n 'KERNEL_SU_UAPI_VERSION' "$F" || true

CUR=$(sed -n 's/.*KERNEL_SU_UAPI_VERSION = \([0-9][0-9]*\).*/\1/p' "$F" | head -1)
echo "[uapi4] 当前值: ${CUR:-未找到}"

if [ "$CUR" = "4" ]; then
    echo "[uapi4] SKIP: 已经是 4"
    exit 0
fi

if [ -z "$CUR" ]; then
    echo "[uapi4] ERROR: 没匹配到版本定义，中止"
    exit 1
fi

sed -i "s/KERNEL_SU_UAPI_VERSION = [0-9][0-9]*/KERNEL_SU_UAPI_VERSION = 4/" "$F"

echo "[uapi4] 改后:"
grep -n 'KERNEL_SU_UAPI_VERSION' "$F" || true

if grep -q 'KERNEL_SU_UAPI_VERSION = 4' "$F"; then
    echo "[uapi4] OK"
    exit 0
fi
echo "[uapi4] ERROR: 替换失败"
exit 1
