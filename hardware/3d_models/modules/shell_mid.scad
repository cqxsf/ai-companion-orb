// ============================================================
// Orb V2 — 中壳（PCB + LED 腔体）
// PLA+ 打印，不透光
// ============================================================

// --- 参数 ---
outer_r       = 42;      // 中壳外径（略小于上壳内径，用于嵌套）
inner_r       = 39;      // 内径
height        = 35;      // 中壳总高度
wall_thick    = 2.5;

module shell_mid() {
    difference() {
        // 外壁
        cylinder(h = height, r = outer_r, $fn = 80);

        // 内腔
        translate([0, 0, wall_thick])
            cylinder(h = height, r = inner_r, $fn = 80);

        // LED 光窗（上部环形开口，让光透到上壳）
        translate([0, 0, height - 5])
            difference() {
                cylinder(h = 6, r = outer_r + 1, $fn = 80);
                cylinder(h = 6, r = 25, $fn = 80);
            }
    }

    // 上部卡扣槽（接收上壳凸缘）
    difference() {
        translate([0, 0, height - 3])
            cylinder(h = 3, r = outer_r + 1.5, $fn = 80);
        translate([0, 0, height - 3.1])
            cylinder(h = 3.2, r = outer_r, $fn = 80);
    }
}

shell_mid();
