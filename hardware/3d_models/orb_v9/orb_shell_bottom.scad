// ============================================================
// Orb V9 — 下壳（Shell_Bottom）
// 从底盖上沿到灯环下沿
// ============================================================
include <orb_config.scad>
use <orb_shell.scad>

module shell_bottom() {
    z_top = split_z - ring_h/2;

    difference() {
        v9_shell();

        // 切掉上半部分
        translate([0, 0, z_top])
            cylinder(h=orb_height - z_top + 1, r=rx+1);

        // 切掉底盖区域
        translate([0, 0, -1])
            cylinder(h=base_h+1, r=rx+1);
    }

    // 螺丝柱
    for (i = [0:n_screws-1]) {
        angle = i * 360/n_screws + 45;  // 偏移45°
        translate([
            screw_ring_r * cos(angle),
            screw_ring_r * sin(angle),
            base_h
        ])
        difference() {
            cylinder(h=z_top-base_h, d=screw_boss_d);
            translate([0, 0, -0.5])
                cylinder(h=z_top-base_h+1, d=screw_d);
        }
    }
}

shell_bottom();
