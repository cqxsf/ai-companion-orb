// ============================================================
// Orb V8 — LED PCB 安装环
// ============================================================

include <orb_config.scad>;

module led_mount() {
    difference() {
        cylinder(h = 4, r = lg_outer + 2);

        // 中心镂空
        translate([0, 0, -0.1])
            cylinder(h = 4.2, r = lg_inner - 2);

        // LED 焊盘孔
        for (i = [0 : led_count - 1])
            rotate([0, 0, i * 360 / led_count])
                translate([led_ring_r, 0, -0.1])
                    cylinder(h = 4.2, r = 3);

        // 走线槽（4 条，Z 偏移避免共面非流形）
        for (a = [0, 90, 180, 270])
            rotate([0, 0, a])
                translate([0, 0, -0.1])
                    cube([1.2, lg_inner * 2 + 0.2, 4.4], center = true);
    }
}

led_mount();
