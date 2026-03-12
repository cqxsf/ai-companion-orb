// ============================================================
// Orb V2 — PCB 安装支撑柱
// 3 点 120° 均布，M2 螺丝固定
// ============================================================

// --- 参数 ---
pcb_r          = 32.5;   // PCB 半径 65mm → 32.5mm
mount_offset_r = 28;     // 支撑柱到中心距离
mount_height   = 8;      // 支撑柱高度
mount_outer_r  = 2;      // 柱外径 4mm → 2mm
mount_hole_r   = 1.1;    // 螺孔半径 2.2mm → 1.1mm（M2 螺丝）
mount_angles   = [0, 120, 240]; // 3 点均布

module pcb_mounts() {
    for (angle = mount_angles) {
        rotate([0, 0, angle])
            translate([mount_offset_r, 0, 0])
                pcb_mount_post();
    }
}

module pcb_mount_post() {
    difference() {
        // 支撑柱
        cylinder(h = mount_height, r = mount_outer_r, $fn = 24);

        // 螺丝孔
        translate([0, 0, -0.1])
            cylinder(h = mount_height + 0.2, r = mount_hole_r, $fn = 16);
    }
}

// PCB 轮廓线（辅助可视化，不打印）
module pcb_outline() {
    color("blue", 0.3)
        translate([0, 0, mount_height])
            cylinder(h = 1.6, r = pcb_r, $fn = 80);
}

pcb_mounts();
// %pcb_outline();  // 取消注释可显示 PCB 轮廓
