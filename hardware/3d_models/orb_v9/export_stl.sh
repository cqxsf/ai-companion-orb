#!/bin/bash
# Orb V9 — 一键 STL 导出
# 用法: cd hardware/3d_models/orb_v9 && bash export_stl.sh

set -e

OPENSCAD=$(which openscad 2>/dev/null || echo "/opt/homebrew/bin/openscad")
if [ ! -x "$OPENSCAD" ]; then
    OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
fi

if [ ! -x "$OPENSCAD" ]; then
    echo "错误: 找不到 OpenSCAD，请先安装"
    exit 1
fi

OUTDIR="exports"
mkdir -p "$OUTDIR"

echo "═══ Orb V9 STL 导出 ═══"
echo "OpenSCAD: $OPENSCAD"
echo ""

PARTS=(
    "orb_shell_top:Shell_Top:上壳"
    "orb_shell_bottom:Shell_Bottom:下壳"
    "orb_led_ring:LED_Ring:灯环扩散罩"
    "orb_top_cap:Top_Cap:浮岛顶盖"
    "orb_base:Base:底盖"
)

PASS=0
FAIL=0

for part in "${PARTS[@]}"; do
    IFS=':' read -r scad name desc <<< "$part"
    OUT="$OUTDIR/orb_v9_${name}.stl"
    echo -n "  $desc ($name)... "

    if "$OPENSCAD" -o "$OUT" "${scad}.scad" 2>/dev/null; then
        # 验证 manifold
        SIMPLE=$("$OPENSCAD" -o /dev/null "$OUT" 2>&1 | grep -c "Simple: yes" || true)
        echo "✓ → $OUT"
        PASS=$((PASS + 1))
    else
        echo "✗ 失败"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "完成: $PASS 成功 / $FAIL 失败"
echo "导出目录: $OUTDIR/"
