// ============================================================
// Orb V8 — 主装配体（苹果级产品设计）
//
// 用法:
//   F5  → 快速预览
//   F6  → 完整渲染（导出 STL 用）
//
// 控制参数:
//   PRINT_PART  → "all" | "top" | "mid" | "bottom"
//                 "lightguide" | "led_mount" | "acoustic" | "halo"
//   EXPLODE     → 0（装配）/ 15~25（爆炸图）
//   SECTION     → false / true（剖面查内部）
// ============================================================

include <orb_config.scad>;

use <orb_shell_top.scad>
use <orb_shell_middle.scad>
use <orb_shell_bottom.scad>
use <orb_lightguide.scad>
use <orb_led_mount.scad>
use <orb_acoustic.scad>
use <orb_mic_array.scad>
use <orb_halo.scad>

// ─── 控制参数 ───────────────────────────────────────────────
PRINT_PART = "all";
EXPLODE    = 0;
SECTION    = false;

// ─── 装配体 ─────────────────────────────────────────────────
module orb_v8_assembly() {
    e = EXPLODE;

    // Layer 1: 底座（Z=0）
    color("DarkSlateGray", 0.95)
        orb_shell_bottom();

    // Layer 1.5: 光晕环（底座底面内）
    color("Gold", 0.7)
        translate([0, 0, wall + e * 0.2])
            halo_ring();

    // Layer 2: 声学腔（坐落在底座上方）
    color("DimGray", 0.9)
        translate([0, 0, split_base + e * 0.5])
            speaker_chamber();

    // Layer 3: 中壳
    color("WhiteSmoke", 0.85)
        translate([0, 0, e * 1])
            orb_shell_middle();

    // Layer 4: 麦克风安装座
    color("Gray")
        translate([0, 0, split_mid - 6 + e * 1.5])
            mic_array_mount();

    // Layer 5: LED 安装环
    color("Silver")
        translate([0, 0, split_mid - lg_h - 4 + e * 2.5])
            led_mount();

    // Layer 6: 光导环
    color("Ivory", 0.7)
        translate([0, 0, split_mid - lg_h + e * 3])
            lightguide_ring();

    // Layer 7: 上壳（光扩散罩）
    color("GhostWhite", 0.5)
        translate([0, 0, e * 4])
            orb_shell_top();
}

// ─── 渲染控制 ────────────────────────────────────────────────
module render_part() {
    if (PRINT_PART == "all") {
        if (SECTION) {
            difference() {
                orb_v8_assembly();
                translate([-150, 0, -10])
                    cube([300, 300, 200]);
            }
        } else {
            orb_v8_assembly();
        }
    }
    else if (PRINT_PART == "top")        orb_shell_top();
    else if (PRINT_PART == "mid")        orb_shell_middle();
    else if (PRINT_PART == "bottom")     orb_shell_bottom();
    else if (PRINT_PART == "lightguide") lightguide_ring();
    else if (PRINT_PART == "led_mount")  led_mount();
    else if (PRINT_PART == "acoustic")   speaker_chamber();
    else if (PRINT_PART == "halo")       halo_ring();
}

render_part();
