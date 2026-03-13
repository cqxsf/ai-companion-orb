// ============================================================
// Orb V9 — 装配预览
// 所有 5 个零件合体，用于视觉检查
// ============================================================
include <orb_config.scad>
use <orb_shell_top.scad>
use <orb_shell_bottom.scad>
use <orb_led_ring.scad>
use <orb_top_cap.scad>
use <orb_base.scad>

// ─── 爆炸视图开关 ─────────────────────────────────────────
explode = 0;  // 设为 1 看爆炸视图

// ─── 颜色 ─────────────────────────────────────────────────
color("WhiteSmoke", 0.85)
    translate([0, 0, explode * 30])
        top_cap();

color("Gainsboro", 0.8)
    translate([0, 0, explode * 15])
        shell_top();

color("Orange", 0.6)
    led_ring();

color("Gainsboro", 0.8)
    translate([0, 0, explode * -15])
        shell_bottom();

color("DimGray", 0.9)
    translate([0, 0, explode * -30])
        base();
