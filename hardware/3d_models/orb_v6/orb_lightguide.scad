// ============================================================
// Orb V6 — LED 光导环（核心光学件）
// 材料：Translucent PETG（透光率更均匀，耐温更好）
//
// V6 改进：
//   - 底部 16 个 LED 入光槽（V4 是 24，V6 省成本）
//   - 顶部出光面内侧 1mm 扩口，引导光线向外散
//   - 简化布尔，确保 manifold 输出
// ============================================================

include <orb_config.scad>;

module lightguide_ring() {
    difference() {
        // 光导体主体
        cylinder(h = lightguide_h, r = lightguide_outer);

        // 中心通孔（走线 + 散热）
        translate([0, 0, -0.1])
            cylinder(h = lightguide_h + 0.2, r = lightguide_inner);

        // 顶部出光面内侧扩口（单体倒角，无非流形风险）
        translate([0, 0, lightguide_h - 1])
            cylinder(h = 1.2,
                     r1 = lightguide_inner - 0.05,
                     r2 = lightguide_inner + 1.1);

        // LED 入光槽（16 个，侧向入光）
        for (i = [0 : led_count - 1]) {
            rotate([0, 0, i * 360 / led_count])
                translate([led_ring_radius, 0, -0.1])
                    cylinder(h = 3.5, r = led_slot_r);
        }
    }
}

lightguide_ring();
