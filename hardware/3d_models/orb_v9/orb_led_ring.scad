// ============================================================
// Orb V9 — LED 灯环扩散罩（LED_Ring）
// 隐藏式：4mm 高磨砂 PC 环，位于分割线处
// 材料：透明 PETG / 磨砂 PC
// ============================================================
include <orb_config.scad>

module led_ring() {
    z_bot = split_z - ring_h/2;
    r_outer = v9_r(split_z);  // 分割线处的椭球半径

    translate([0, 0, z_bot])
    difference() {
        cylinder(h=ring_h, r=r_outer);
        translate([0, 0, -0.1])
            cylinder(h=ring_h+0.2, r=r_outer - ring_t);
    }
}

led_ring();
