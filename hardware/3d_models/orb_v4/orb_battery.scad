// ============================================================
// Orb V4 — 18650 电池槽
//
// 设计要点:
//   - 适配标准 18650 锂电池 (Ø18 × 65mm)
//   - 圆弧底面贴合电池形状
//   - 两端预留弹簧触片空间
//   - 侧面导线槽
//   - 底部与底座腔体适配
// ============================================================

include <orb_config.scad>;

module battery_slot() {
    slot_w = battery_diameter + battery_padding * 2 + 3;   // ~23mm
    slot_l = battery_length + battery_padding * 2 + 3;     // ~71mm
    slot_h = battery_diameter / 2 + battery_padding + 2;   // ~13mm

    difference() {
        // 外壳
        translate([-slot_w/2, -slot_l/2, 0])
            cube([slot_w, slot_l, slot_h]);

        // 电池腔（上半圆柱）
        translate([0, 0, slot_h])
            rotate([90, 0, 0])
                translate([0, 0, -battery_length/2 - battery_padding])
                    cylinder(h = battery_length + battery_padding * 2,
                             r = battery_diameter/2 + battery_padding);

        // 正极导线槽
        translate([0, slot_l/2 - 1, slot_h/2])
            cube([4, 3, slot_h + 1], center = true);

        // 负极导线槽
        translate([0, -(slot_l/2 - 1), slot_h/2])
            cube([4, 3, slot_h + 1], center = true);
    }

    // 弹簧触片凸台（负极端）
    translate([0, -slot_l/2 + 2, 0])
        cylinder(h = slot_h * 0.6, r = 3);
}

battery_slot();
