// ============================================================
// Orb V6 — 麦克风阵列安装座
// 4 颗 INMP441，90° 均布，安装在中框顶部内侧
// ============================================================

include <orb_config.scad>;

module mic_array_mount() {
    for (a = mic_angles) {
        rotate([0, 0, a])
            translate([mic_ring_r - 4, 0, 0]) {
                difference() {
                    // 安装底座
                    cube([8, 5, 3], center = true);
                    // 麦克风孔
                    cylinder(h = 3.1, r = mic_hole_r + 0.3, center = true);
                }
            }
    }
}

mic_array_mount();
