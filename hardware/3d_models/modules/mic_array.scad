// ============================================================
// Orb V2 — 麦克风阵列孔位
// 3 MIC（INMP441），120° 均布
// ============================================================

// --- 参数 ---
mic_offset_r  = 25;      // 麦克风到中心距离
mic_hole_r    = 1;        // 麦克风孔半径 2mm → 1mm
mic_count     = 3;
mic_angles    = [0, 120, 240];
mic_pcb_w     = 14;       // INMP441 模块尺寸
mic_pcb_h     = 10;

module mic_array_holes(shell_thick = 2.5) {
    // 在壳体上打 3 个拾音孔
    for (angle = mic_angles) {
        rotate([0, 0, angle])
            translate([mic_offset_r, 0, -0.1])
                cylinder(h = shell_thick + 0.2, r = mic_hole_r, $fn = 24);
    }
}

// 麦克风 PCB 安装座
module mic_mounts() {
    for (angle = mic_angles) {
        rotate([0, 0, angle])
            translate([mic_offset_r, 0, 0])
                mic_mount_bracket();
    }
}

module mic_mount_bracket() {
    // L 型支架
    difference() {
        union() {
            cube([mic_pcb_w + 2, 3, 8], center = true);
            translate([0, -1.5, 4])
                cube([mic_pcb_w + 2, 1.5, 2], center = true);
        }
        // 螺丝孔
        for (dx = [-mic_pcb_w / 2 + 1, mic_pcb_w / 2 - 1]) {
            translate([dx, 0, -5])
                cylinder(h = 20, r = 0.6, $fn = 12);
        }
    }
}

mic_mounts();
// %mic_array_holes();  // 取消注释可显示拾音孔
