// ============================================================
// Orb V6 — 主装配体
//
// 控制参数：
//   PRINT_PART  → "all" | "top" | "mid" | "bottom"
//                 "lightguide" | "led_mount" | "acoustic"
//   EXPLODE     → 0（装配）/ 10~25（爆炸图）
//   SECTION     → false（完整）/ true（剖面查内部）
// ============================================================

include <orb_config.scad>;

use <orb_shell_top.scad>
use <orb_shell_middle.scad>
use <orb_shell_bottom.scad>
use <orb_lightguide.scad>
use <orb_led_mount.scad>
use <orb_acoustic.scad>
use <orb_mic_array.scad>

// ─────────────── 控制参数 ───────────────────────────────────
// 打印选择: "all" | "top" | "mid" | "bottom" | "lightguide" | "led_mount" | "acoustic"
PRINT_PART = "all";

// 爆炸间距（0=装配, 15=爆炸视图）
EXPLODE = 0;

// 剖面（true=切掉 Y>0 的一半，查看内部）
SECTION = false;

// ─────────────── 层 Z 坐标 ──────────────────────────────────
z_bottom     = 0;
z_acoustic   = split_mid;
z_led_mount  = split_top - lightguide_h - led_mount_h();
z_lightguide = split_top - lightguide_h;
z_top        = 0;   // 上壳内置 split_top 绝对坐标

function led_mount_h() = 4;

// ─────────────── 装配体 ─────────────────────────────────────
module orb_v6_assembly() {
    e = EXPLODE;

    // Layer 1: 底座
    color("SlateGray", 0.95)
        translate([0, 0, z_bottom])
            orb_shell_bottom();

    // Layer 2: 声学腔（坐落在底座顶部）
    color("DimGray", 0.9)
        translate([0, 0, z_acoustic + e * 0.5])
            speaker_chamber();

    // Layer 3: 中框
    color("Gray", 0.7)
        translate([0, 0, 0 + e * 1])
            orb_shell_middle();

    // Layer 4: 麦克风安装座（随中框）
    color("DarkGray")
        translate([0, 0, split_top - 6 + e * 1])
            mic_array_mount();

    // Layer 5: LED 安装环
    color("Silver")
        translate([0, 0, z_lightguide - 4 + e * 2])
            led_mount();

    // Layer 6: 光导环
    color("Ivory", 0.75)
        translate([0, 0, z_lightguide + e * 2.5])
            lightguide_ring();

    // Layer 7: 上壳（扁椭球）
    color("WhiteSmoke", 0.55)
        translate([0, 0, e * 4])
            orb_shell_top();
}

// ─────────────── 渲染控制 ────────────────────────────────────
module render_part() {
    if (PRINT_PART == "all") {
        if (SECTION) {
            difference() {
                orb_v6_assembly();
                translate([-100, 0, -10])
                    cube([200, 200, 200]);
            }
        } else {
            orb_v6_assembly();
        }
    }
    else if (PRINT_PART == "top")        orb_shell_top();
    else if (PRINT_PART == "mid")        orb_shell_middle();
    else if (PRINT_PART == "bottom")     orb_shell_bottom();
    else if (PRINT_PART == "lightguide") lightguide_ring();
    else if (PRINT_PART == "led_mount")  led_mount();
    else if (PRINT_PART == "acoustic")   speaker_chamber();
}

render_part();
