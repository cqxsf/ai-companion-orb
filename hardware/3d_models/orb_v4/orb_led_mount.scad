// ============================================================
// Orb V4 — LED PCB 安装环
// PLA+ 打印
//
// 设计要点:
//   - 环形托盘承载 LED 环形 PCB (Ø60mm)
//   - 光导环从上方嵌套，LED 从下方照射入光导体
//   - 距光导环底面 2mm 间距（最佳入光角度）
//   - 3 个定位销与主控 PCB 对齐
// ============================================================

include <orb_config.scad>;

module led_mount() {
    // LED PCB 托盘
    difference() {
        // 外环
        cylinder(h = 4, r = lightguide_outer);

        // 中心镂空（走线）
        translate([0, 0, -0.1])
            cylinder(h = 4.2, r = lightguide_inner);

        // PCB 轻卡位（方便拆装）
        for (a = [0, 120, 240]) {
            rotate([0, 0, a])
                translate([led_ring_radius, 0, 2])
                    cube([6, 1.2, 4], center = true);
        }
    }

    // 定位销（对齐光导环）
    for (a = [60, 180, 300]) {
        rotate([0, 0, a])
            translate([(lightguide_outer + lightguide_inner) / 2, 0, 4])
                cylinder(h = 2, r = 1);
    }
}

led_mount();
