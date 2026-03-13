// ============================================================
// Orb V8 — 底部光晕模块（Halo Ring）
// V8 新特性：底座底面 8 颗 WS2812B 朝下发光
// 硅胶垫把底座抬高 3mm，光从间隙漫射到桌面
// 夜间效果：底部一圈柔光，像悬浮发光石
// ============================================================

include <orb_config.scad>;

module halo_ring() {
    // 光晕 LED PCB 安装环（嵌入底座底面）
    difference() {
        // 安装环主体
        cylinder(h = 2, r = halo_ring_r + 4);
        translate([0, 0, -0.1])
            cylinder(h = 2.2, r = halo_ring_r - 4);

        // 8 个 LED 槽（向外倾斜 30°，光线洒向桌面）
        for (i = [0 : halo_led_count - 1])
            rotate([0, 0, i * 360 / halo_led_count])
                translate([halo_ring_r, 0, -0.1])
                    cylinder(h = 2.2, r = halo_led_r);
    }
}

halo_ring();
