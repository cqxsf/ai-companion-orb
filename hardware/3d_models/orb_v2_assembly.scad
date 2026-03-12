// ============================================================
// Orb V2 — 完整装配体
// AI Companion Orb 工程级结构设计
//
// 用法:
//   F5 预览 → F6 渲染 → 导出 STL
//   修改下方参数自定义尺寸
//   设置 PRINT_PART 可单独导出某个部件
// ============================================================

// --- 全局参数 ---
ORB_RADIUS       = 45;     // 球体外径 90mm
ORB_HEIGHT       = 78;     // 总高度
WALL_THICK       = 2.5;    // 壁厚
BASE_BOTTOM_R    = 30;     // 底面半径 60mm

// --- 打印选择 ---
// 设为 "all" 显示装配体，或设为零件名单独导出
// 可选: "all", "top", "mid", "base"
PRINT_PART = "all";

// --- 爆炸视图 ---
// 设为 0 查看装配状态，>0 查看爆炸视图
EXPLODE = 0;  // 建议值: 0 或 15

// --- 模块引用 ---
use <modules/shell_top.scad>
use <modules/shell_mid.scad>
use <modules/shell_base.scad>
use <modules/led_diffuser.scad>
use <modules/speaker_chamber.scad>
use <modules/pcb_mounts.scad>
use <modules/battery_slot.scad>
use <modules/mic_array.scad>

// ============================================================
// 装配
// ============================================================

module orb_assembly() {
    e = EXPLODE;

    // Layer 1: 上壳（扩散球壳）
    color("White", 0.6)
        translate([0, 0, 55 + e * 4])
            shell_top();

    // Layer 2: LED 扩散腔
    color("Ivory", 0.8)
        translate([0, 0, 40 + e * 3])
            led_diffuser();

    // Layer 3: 主控 PCB 支撑柱
    color("DarkGray")
        translate([0, 0, 30 + e * 2])
            pcb_mounts();

    // Layer 3.5: 麦克风安装座
    color("DimGray")
        translate([0, 0, 30 + e * 2])
            mic_mounts();

    // Layer 4: 中壳
    color("SlateGray", 0.7)
        translate([0, 0, 18 + e * 1])
            shell_mid();

    // Layer 5: 声学共振腔
    color("Gray")
        translate([0, 0, 10 + e * 0.5])
            speaker_chamber();

    // Layer 6: 电池槽
    color("DarkOliveGreen")
        translate([0, 0, 5])
            battery_slot();

    // Layer 7: 底座
    color("DarkSlateGray", 0.9)
        shell_base();
}

// ============================================================
// 渲染控制
// ============================================================

if (PRINT_PART == "all") {
    orb_assembly();
} else if (PRINT_PART == "top") {
    shell_top();
} else if (PRINT_PART == "mid") {
    shell_mid();
} else if (PRINT_PART == "base") {
    shell_base();
}
