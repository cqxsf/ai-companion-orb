// ============================================================
// Orb V8 — 声学腔 + 倒相管
// 40mm 扬声器 + ~22cc 共振腔 + Ø8×14mm 倒相管
// 调谐频率 ~110Hz
// ============================================================

include <orb_config.scad>;

module speaker_chamber() {
    difference() {
        // 腔体外壁
        cylinder(h = chamber_h, r = chamber_r);

        // 内部共振空间
        translate([0, 0, wall])
            cylinder(h = chamber_h, r = spk_r + 1);

        // 扬声器安装面开口
        translate([0, 0, -0.1])
            cylinder(h = wall + 0.2, r = spk_r - 1);
    }

    // 扬声器 4 点卡扣
    for (a = [45, 135, 225, 315])
        rotate([0, 0, a])
            translate([spk_r + 1, 0, wall])
                difference() {
                    cylinder(h = 4, r = 2);
                    cylinder(h = 4.1, r = 1);
                }
}

speaker_chamber();
