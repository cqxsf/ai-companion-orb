#!/bin/bash
# ============================================================
# Orb V6 — 一键 STL 导出脚本
# 用法：bash export_stl.sh
# 需要：OpenSCAD 2025.05.16（/opt/homebrew/bin/openscad）
# ============================================================

set -e

SCAD="/opt/homebrew/bin/openscad"
SRC="$(dirname "$0")/orb_assembly.scad"
OUT="$(dirname "$0")/exports"

mkdir -p "$OUT"

echo "=== Orb V6 STL 导出开始 ==="
echo "源文件: $SRC"
echo "输出目录: $OUT"
echo ""

parts=("top" "mid" "bottom" "lightguide" "led_mount" "acoustic")
labels=("上壳（扁椭球·Translucent PLA）" "中框·腰线卵石（PLA+）" "底座·喇叭口（PLA+）" "光导环（Translucent PETG）" "LED安装环（PLA+）" "声学腔（PLA+）")

for i in "${!parts[@]}"; do
    part="${parts[$i]}"
    label="${labels[$i]}"
    outfile="$OUT/${part}.stl"
    echo "[$((i+1))/${#parts[@]}] 导出 ${part}.stl — ${label}"
    "$SCAD" -o "$outfile" -D "PRINT_PART=\"$part\"" "$SRC"
    size=$(ls -lh "$outfile" | awk '{print $5}')
    echo "    ✓ $outfile ($size)"
done

echo ""
echo "=== 导出完成 ==="
echo ""
echo "拓竹打印参数："
echo "  上壳 / 光导环  → Translucent PETG，层高 0.16，3 壁，15% 填充，无支撑"
echo "  中框 / 底座     → PLA+，层高 0.20，3 壁，15% 填充，无支撑"
echo "  LED环 / 声学腔  → PLA+，层高 0.20，3 壁，20% 填充，无支撑"
