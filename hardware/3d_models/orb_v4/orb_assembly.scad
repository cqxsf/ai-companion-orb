// ============================================================
// Orb V4 — 完整装配体
// AI Companion Orb 量产级结构设计
//
// 用法:
//   F5  → 快速预览（低精度）
//   F6  → 完整渲染（高精度，导出 STL 用）
//
// 控制参数:
//   PRINT_PART  → 选择单件导出或查看装配
//   EXPLODE     → 爆炸视图间距
//   SECTION     → 剖面视图开关
//
// 文件结构:
//   orb_config.scad       → 全局参数（改这里调整所有尺寸）
//   orb_shell_top.scad    → 上壳（Translucent PLA）
//   orb_shell_middle.scad → 中框（PLA+）
//   orb_shell_bottom.scad → 底座（PLA+）
//   orb_lightguide.scad   → 光导环（Translucent PLA）
//   orb_led_mount.scad    → LED PCB 安装环
//   orb_acoustic.scad     → 声学腔 + 倒相管
//   orb_pcb_mount.scad    → PCB 支撑柱
//   orb_mic_array.scad    → 麦克风安装座
//   orb_battery.scad      → 电池槽
// ============================================================

include <orb_config.scad>;

// --- 控制参数 ---

// 打印选择: "all" | "top" | "mid" | "bottom" | "lightguide" | "led_mount" | "acoustic"
PRINT_PART = "all";

// 爆炸视图间距 (0 = 装配状态, 10~20 = 爆炸)
EXPLODE = 0;

// 剖面视图 (true = 剖半查看内部)
SECTION = false;

// --- 引用模块 ---
use <orb_shell_top.scad>
use <orb_shell_middle.scad>
use <orb_shell_bottom.scad>
use <orb_lightguide.scad>
use <orb_led_mount.scad>
use <orb_acoustic.scad>
use <orb_pcb_mount.scad>
use <orb_mic_array.scad>
use <orb_battery.scad>

// ============================================================
// 装配定义
// ============================================================

// 各层 Z 坐标（从底座 Z=0 向上堆叠）
z_bottom     = 0;
z_acoustic   = bottom_height;
z_battery    = bottom_height + 2;
z_pcb        = bottom_height + speaker_chamber_h - 2;
z_mic        = z_pcb;
z_mid        = bottom_height - 3;
z_led_mount  = bottom_height + speaker_chamber_h + 6;
z_lightguide = z_led_mount + 6;
z_top        = orb_height - top_height;

module orb_v4_assembly() {
    e = EXPLODE;

    // === Layer 1: 底座 ===
    color("DimGray", 0.9)
        translate([0, 0, z_bottom])
            orb_shell_bottom();

    // === Layer 2: 声学腔 + 倒相管 ===
    color("SlateGray", 0.85)
        translate([0, 0, z_acoustic + e])
            speaker_chamber();

    // === Layer 2.5: 电池槽 ===
    color("DarkOliveGreen", 0.8)
        translate([0, 0, z_battery + e * 0.5])
            battery_slot();

    // === Layer 3: 中框 ===
    color("Gray", 0.6)
        translate([0, 0, z_mid + e * 1.5])
            orb_shell_middle();

    // === Layer 4: PCB 支撑柱 ===
    color("DarkGray")
        translate([0, 0, z_pcb + e * 2])
            pcb_mounts();

    // === Layer 4.5: 麦克风安装座 ===
    color("DarkSlateGray")
        translate([0, 0, z_mic + e * 2])
            mic_mounts();

    // === Layer 5: LED 安装环 ===
    color("Silver")
        translate([0, 0, z_led_mount + e * 3])
            led_mount();

    // === Layer 6: 光导环 ===
    color("Ivory", 0.7)
        translate([0, 0, z_lightguide + e * 3.5])
            lightguide_ring();

    // === Layer 7: 上壳 (扩散球壳) ===
    color("White", 0.5)
        translate([0, 0, z_top + e * 4])
            orb_shell_top();
}

// ============================================================
// 渲染控制
// ============================================================

module render_part() {
    if (PRINT_PART == "all") {
        if (SECTION) {
            difference() {
                orb_v4_assembly();
                // 剖面切割（切掉 Y>0 的一半）
                translate([-100, 0, -10])
                    cube([200, 200, 200]);
            }
        } else {
            orb_v4_assembly();
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

// ============================================================
// 尺寸标注（预览用）
// ============================================================

module dimension_labels() {
    color("red", 0.6) {
        // 总直径标注线
        translate([orb_radius + 5, 0, orb_height/2])
            rotate([0, 90, 0])
                cylinder(h = 0.5, r = orb_height/2);

        // 总高度标注线
        translate([orb_radius + 8, 0, 0])
            cylinder(h = orb_height, r = 0.3);
    }
}

// %dimension_labels();  // 取消注释显示尺寸标注
