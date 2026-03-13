// ============================================================
// Orb V8 — LED 光导碗
// 材料：Translucent PETG
//
// 与 V6 相比：增加底部 LED 入光槽，顶部出光微扩口
// ============================================================

include <orb_config.scad>;

module lightguide_ring() {
    difference() {
        // 光导体主体（实心环）
        cylinder(h = lg_h, r = lg_outer);

        // 中心通孔
        translate([0, 0, -0.1])
            cylinder(h = lg_h + 0.2, r = lg_inner);

        // 顶部出光面内侧扩口
        translate([0, 0, lg_h - 1])
            cylinder(h = 1.2,
                     r1 = lg_inner - 0.05,
                     r2 = lg_inner + 1.1);

        // LED 入光槽（16 个）
        for (i = [0 : led_count - 1])
            rotate([0, 0, i * 360 / led_count])
                translate([led_ring_r, 0, -0.1])
                    cylinder(h = 3.5, r = led_slot_r);
    }
}

lightguide_ring();
