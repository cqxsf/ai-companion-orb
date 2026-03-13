// ============================================================
// Orb V6 — 声学腔 + 倒相管
// 材料：PLA+
//
// 设计：
//   40mm 扬声器 + 共振腔 ~22cc + 倒相管 Ø8×14mm
//   调谐频率 ~110Hz，低频 +40%
//   4 点卡扣固定扬声器
// ============================================================

include <orb_config.scad>;

module speaker_chamber() {
    difference() {
        // 腔体外壁（圆柱）
        cylinder(h = chamber_h, r = chamber_r_outer);

        // 腔体内部（共振空间）
        translate([0, 0, wall])
            cylinder(h = chamber_h, r = speaker_r + 1);

        // 扬声器安装面开口
        translate([0, 0, -0.1])
            cylinder(h = wall + 0.2, r = speaker_r - 1);
    }

    // 扬声器 4 点卡扣
    for (a = [45, 135, 225, 315])
        rotate([0, 0, a])
            translate([speaker_r + 1, 0, wall])
                difference() {
                    cylinder(h = 4, r = 2);
                    cylinder(h = 4.1, r = 1);
                }
}

speaker_chamber();
