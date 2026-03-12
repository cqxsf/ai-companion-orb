// ============================================================
// Orb V4 — PCB 安装支撑柱
// 3 点 120° 均布，M2 螺丝固定
//
// 设计要点:
//   - 3 根支撑柱承载主控 PCB (Ø65mm)
//   - 顶面平台用于 PCB 定位
//   - 底部与中框一体或粘接
//   - 预留走线空间
// ============================================================

include <orb_config.scad>;

module pcb_mounts() {
    for (a = pcb_mount_angles) {
        rotate([0, 0, a])
            translate([pcb_mount_r, 0, 0])
                pcb_post();
    }
}

module pcb_post() {
    // 支撑柱
    difference() {
        union() {
            // 主柱体
            cylinder(h = 8, r = 2.2);
            // 底部加强肋
            cylinder(h = 2, r = 3.5);
        }
        // M2 螺孔
        translate([0, 0, -0.1])
            cylinder(h = 8.2, r = screw_r);
    }
}

// PCB 轮廓线（仅预览）
module pcb_outline() {
    color("navy", 0.2)
        translate([0, 0, 8])
            cylinder(h = pcb_thick, r = pcb_radius);
}

pcb_mounts();
// %pcb_outline();  // 取消注释显示 PCB 轮廓
