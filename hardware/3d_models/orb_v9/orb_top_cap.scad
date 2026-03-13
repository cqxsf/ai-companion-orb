// ============================================================
// Orb V9 — 浮岛式顶盖（Top_Cap）
// Ø92mm × 6mm，0.6mm 缝隙兼做麦克风孔 + 灯光溢出口
// ============================================================
include <orb_config.scad>

module top_cap() {
    z_base = orb_height - cap_h;

    difference() {
        // 主体圆柱 + 球顶
        translate([0, 0, z_base])
        hull() {
            // 底部圆柱
            cylinder(h=0.1, d=cap_d);
            // 顶部圆角
            translate([0, 0, cap_h - cap_fillet])
                resize([cap_d, cap_d, cap_fillet*2])
                    sphere(d=cap_d);
        }

        // 麦克风孔（4 孔 90° 排列在缝隙区域，贯穿顶盖）
        for (i = [0:mic_count-1]) {
            angle = i * 360/mic_count;
            translate([
                mic_ring_r * cos(angle),
                mic_ring_r * sin(angle),
                z_base - 1
            ])
            cylinder(h=cap_h+2, d=mic_hole_d);
        }
    }
}

top_cap();
