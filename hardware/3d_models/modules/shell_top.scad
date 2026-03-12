// ============================================================
// Orb V2 — 上壳（扩散球壳）
// 磨砂 PC / Translucent PLA 打印
// ============================================================

// --- 参数 ---
orb_radius    = 45;      // 外径 90mm → 半径 45mm
wall_thick    = 2.5;     // 壁厚
flat_cut      = 39;      // 底部平切高度（从球心算）
                         // 球心在赤道，底部切掉一部分

module shell_top() {
    difference() {
        // 外壳球体
        sphere(r = orb_radius, $fn = 120);

        // 内腔
        sphere(r = orb_radius - wall_thick, $fn = 120);

        // 底部平切（只保留上半部分 + 部分下半）
        translate([0, 0, -orb_radius])
            cube([orb_radius * 2, orb_radius * 2, orb_radius * 2 - flat_cut],
                 center = true);

        // 底部装配口（与中壳对接）
        translate([0, 0, -flat_cut + wall_thick])
            cylinder(h = wall_thick + 0.1, r = orb_radius - wall_thick - 1, $fn = 80);
    }

    // 卡扣凸缘（与中壳配合）
    difference() {
        translate([0, 0, -flat_cut])
            cylinder(h = 3, r = orb_radius - wall_thick, $fn = 80);
        translate([0, 0, -flat_cut - 0.1])
            cylinder(h = 3.2, r = orb_radius - wall_thick - 1.5, $fn = 80);
    }
}

shell_top();
