// ============================================================
// Orb V2 — 声学共振腔
// 提升 40mm 扬声器低频响应
// ============================================================

// --- 参数 ---
chamber_outer_r = 25;    // 腔体外径 50mm → 半径 25mm
chamber_inner_r = 22;    // 腔体内径
chamber_height  = 16;    // 腔体高度
wall_thick      = 3;     // 壁厚（声学需要较厚壁）
speaker_r       = 20;    // 扬声器安装孔半径 40mm → 20mm
speaker_mount_r = 21;    // 扬声器卡位半径

module speaker_chamber() {
    difference() {
        // 腔体外壁
        cylinder(h = chamber_height, r = chamber_outer_r, $fn = 80);

        // 内腔（共振空间）
        translate([0, 0, wall_thick])
            cylinder(h = chamber_height - wall_thick + 0.1, r = chamber_inner_r, $fn = 80);

        // 扬声器安装孔（顶部）
        translate([0, 0, chamber_height - 2])
            cylinder(h = 3, r = speaker_r, $fn = 80);
    }

    // 扬声器卡扣凸台（4 点固定）
    for (i = [0 : 90 : 270]) {
        rotate([0, 0, i])
            translate([speaker_mount_r, 0, chamber_height - 2])
                difference() {
                    cylinder(h = 2, r = 2, $fn = 16);
                    cylinder(h = 2.1, r = 0.8, $fn = 16);
                }
    }
}

speaker_chamber();
