#!/bin/bash
# ============================================================
# Orb V8 — 一键 STL 导出
# 用法: bash export_stl.sh
# ============================================================

set -e

SCAD="/opt/homebrew/bin/openscad"
SRC="$(cd "$(dirname "$0")" && pwd)/orb_assembly.scad"
OUT="$(cd "$(dirname "$0")" && pwd)/exports"

mkdir -p "$OUT"

echo "=== Orb V8 STL Export ==="
echo "Source: $SRC"
echo ""

parts=("top" "mid" "bottom" "lightguide" "led_mount" "acoustic" "halo")
labels=(
    "上壳·光扩散罩（磨砂PC/PETG）"
    "中壳·主结构体（Soft-touch ABS/PLA+）"
    "底座·光晕底座（PLA+ 硅胶包覆）"
    "光导碗（Translucent PETG）"
    "LED安装环（PLA+）"
    "声学腔（PLA+）"
    "光晕环（PLA+）"
)

for i in "${!parts[@]}"; do
    part="${parts[$i]}"
    label="${labels[$i]}"
    outfile="$OUT/${part}.stl"
    echo "[$((i+1))/${#parts[@]}] ${part}.stl — ${label}"
    "$SCAD" -o "$outfile" -D "PRINT_PART=\"$part\"" "$SRC"
    size=$(ls -lh "$outfile" | awk '{print $5}')
    echo "    ✓ $outfile ($size)"
done

echo ""
echo "=== 导出完成 ==="
echo ""
echo "Bambu Studio 打印参数："
echo "  上壳 / 光导碗   → Translucent PETG, 0.16mm, 3壁, 15%, 无支撑"
echo "  中壳 / 底座      → PLA+, 0.20mm, 3壁, 15%, 无支撑"
echo "  声学腔 / LED环   → PLA+, 0.20mm, 3壁, 20%, 无支撑"
echo "  光晕环           → PLA+, 0.20mm, 3壁, 20%, 无支撑"
echo ""
echo "颜色版本："
echo "  家庭版: 暖白  |  儿童版: 淡橙  |  科技版: 深灰"
