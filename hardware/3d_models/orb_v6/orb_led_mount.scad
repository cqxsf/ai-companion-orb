// ============================================================
// Orb V6 — LED PCB 安装环
// 材料：PLA+
//
// 固定 16 颗 WS2812B 的环形 PCB，卡扣安装在中框顶部
// ============================================================

include <orb_config.scad>;

module led_mount() {
    difference() {
        // 安装环主体
        cylinder(h = 4, r = lightguide_outer + 2);

        // 中心镂空
        translate([0, 0, -0.1])
            cylinder(h = 4.2, r = lightguide_inner - 2);

        // LED 位置孔（精确对位 PCB 焊盘）
        for (i = [0 : led_count - 1]) {
            rotate([0, 0, i * 360 / led_count])
                translate([led_ring_radius, 0, -0.1])
                    cylinder(h = 4.2, r = 3);
        }

        // 走线槽（4 条）
        for (a = [0, 90, 180, 270])
            rotate([0, 0, a])
                translate([0, 0, -0.1])
                    cube([1.2, lightguide_inner * 2, 4.2], center = true);
    }
}

led_mount();
