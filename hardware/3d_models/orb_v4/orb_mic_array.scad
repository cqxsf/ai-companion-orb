// ============================================================
// Orb V4 — 麦克风阵列
// 3× INMP441，120° 均布
//
// 设计要点:
//   - 拾音孔 Ø2mm 贯穿壳壁
//   - L 型安装支架固定 INMP441 模块
//   - 25mm 离中心距离满足波束成形需求
//   - 支持语音定位 + AEC 降噪
// ============================================================

include <orb_config.scad>;

// 拾音孔（用于从外壳上减去）
module mic_holes(shell_thick = wall) {
    for (a = mic_angles) {
        rotate([0, 0, a])
            translate([mic_radius, 0, -0.1])
                cylinder(h = shell_thick + 0.2, r = mic_hole_r);
    }
}

// 麦克风 PCB 安装座
module mic_mounts() {
    for (a = mic_angles) {
        rotate([0, 0, a])
            translate([mic_radius, 0, 0])
                mic_bracket();
    }
}

module mic_bracket() {
    inmp_w = 14;   // INMP441 模块宽度
    inmp_h = 10;   // INMP441 模块高度

    difference() {
        union() {
            // 底座
            cube([inmp_w + 2, 3, 3], center = true);
            // L 型竖板
            translate([0, -1, 3])
                cube([inmp_w + 2, 1.5, 5], center = true);
        }
        // 螺丝孔 ×2
        for (dx = [-inmp_w/2 + 1.5, inmp_w/2 - 1.5]) {
            translate([dx, 0, -5])
                cylinder(h = 15, r = 0.6);
        }
    }
}

mic_mounts();
