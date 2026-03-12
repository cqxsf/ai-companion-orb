// ============================================================
// Orb V4 — 底座
// PLA+ 打印，免支撑
//
// 设计要点:
//   - 截锥体造型，底面 Ø62mm 保证桌面稳定
//   - 底部声孔阵列（声学出口）
//   - 倒相管出口集成在底部
//   - USB-C 充电口开口
//   - 硅胶垫槽（防滑）
//   - 上接中框卡扣
// ============================================================

include <orb_config.scad>;

module orb_shell_bottom() {
    difference() {
        // --- 外壁 (截锥) ---
        cylinder(h = bottom_height, r1 = base_radius, r2 = base_radius + wall * 2);

        // --- 内腔 ---
        translate([0, 0, wall])
            cylinder(h = bottom_height, r1 = base_radius - wall,
                     r2 = base_radius + wall);

        // --- 底部声孔阵列 (2行4列) ---
        for (row = [-1, 1]) {
            for (col = [-1.5, -0.5, 0.5, 1.5]) {
                translate([col * 7, row * 5, -0.1])
                    cylinder(h = wall + 0.2, r = sound_hole_r);
            }
        }

        // --- 倒相管出口孔 ---
        translate([bass_port_offset, 0, -0.1])
            cylinder(h = wall + 0.2, r = bass_port_radius + 0.5);

        // --- 硅胶垫环形槽 (底面) ---
        translate([0, 0, -0.01])
            difference() {
                cylinder(h = silicone_pad_thick, r = base_radius - 3);
                cylinder(h = silicone_pad_thick, r = base_radius - 7);
            }

        // --- USB-C 充电口 (侧面) ---
        translate([0, base_radius - wall/2, wall + 4])
            rotate([90, 0, 0])
                hull() {
                    translate([-4.5, 0, 0]) cylinder(h = wall + 1, r = 1.5);
                    translate([ 4.5, 0, 0]) cylinder(h = wall + 1, r = 1.5);
                }
    }

    // --- 上部卡扣槽 (接收中框凸缘) ---
    translate([0, 0, bottom_height])
        difference() {
            cylinder(h = 3, r = base_radius + wall + snap_fit_tol);
            cylinder(h = 3.1, r = base_radius + wall - 2 - snap_fit_tol);
        }
}

orb_shell_bottom();
