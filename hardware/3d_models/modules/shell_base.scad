// ============================================================
// Orb V2 — 底座（声孔 + 防滑垫位）
// PLA+ 打印
// ============================================================

// --- 参数 ---
base_top_r     = 42;      // 顶部半径（与中壳对接）
base_bottom_r  = 30;      // 底面半径 60mm → 半径 30mm
base_height    = 18;      // 底座高度
wall_thick     = 2.5;
sound_hole_r   = 1.5;     // 声孔半径 3mm → 1.5mm
sound_hole_n   = 8;       // 声孔数量
silicone_depth = 1;       // 硅胶垫槽深度

module shell_base() {
    difference() {
        // 底座外壳（截锥体）
        cylinder(h = base_height, r1 = base_bottom_r, r2 = base_top_r, $fn = 80);

        // 内腔
        translate([0, 0, wall_thick])
            cylinder(h = base_height, r1 = base_bottom_r - wall_thick,
                     r2 = base_top_r - wall_thick, $fn = 80);

        // 底部声孔阵列（2行4列）
        for (row = [-1, 1]) {
            for (col = [-1.5, -0.5, 0.5, 1.5]) {
                translate([col * 7, row * 5, -0.1])
                    cylinder(h = wall_thick + 0.2, r = sound_hole_r, $fn = 24);
            }
        }

        // 底面硅胶垫槽（环形）
        translate([0, 0, -0.01])
            difference() {
                cylinder(h = silicone_depth, r = base_bottom_r - 2, $fn = 80);
                cylinder(h = silicone_depth, r = base_bottom_r - 6, $fn = 80);
            }
    }

    // USB-C 充电口开口
    translate([0, base_bottom_r - wall_thick, wall_thick + 3])
        rotate([90, 0, 0])
            hull() {
                translate([-4.5, 0, 0]) cylinder(h = wall_thick + 1, r = 1.5, $fn = 16);
                translate([ 4.5, 0, 0]) cylinder(h = wall_thick + 1, r = 1.5, $fn = 16);
            }
}

shell_base();
