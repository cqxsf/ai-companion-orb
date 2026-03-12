// ============================================================
// Orb V2 — 电池槽（18650 单节）
// ============================================================

// --- 参数 ---
bat_diameter  = 18;      // 18650 直径
bat_length    = 65;      // 18650 长度
slot_padding  = 1;       // 槽壁间隙
slot_wall     = 1.5;     // 槽壁厚度

slot_w = bat_diameter + slot_padding * 2 + slot_wall * 2;   // ~22mm
slot_l = bat_length + slot_padding * 2 + slot_wall * 2;     // ~71mm
slot_h = bat_diameter / 2 + slot_padding + slot_wall;        // ~12.5mm

module battery_slot() {
    difference() {
        // 外壳
        translate([-slot_w / 2, -slot_l / 2, 0])
            cube([slot_w, slot_l, slot_h]);

        // 电池腔（圆柱形底部）
        translate([0, 0, slot_h])
            rotate([90, 0, 0])
                translate([0, 0, -bat_length / 2 - slot_padding])
                    cylinder(h = bat_length + slot_padding * 2,
                             r = bat_diameter / 2 + slot_padding, $fn = 40);

        // 导线槽
        translate([0, slot_l / 2 - slot_wall, slot_h / 2])
            cube([4, slot_wall * 2 + 0.2, slot_h], center = true);
        translate([0, -(slot_l / 2 - slot_wall), slot_h / 2])
            cube([4, slot_wall * 2 + 0.2, slot_h], center = true);
    }

    // 弹簧触片凸台
    translate([0, -slot_l / 2 + slot_wall, 0])
        cylinder(h = slot_h - bat_diameter / 4, r = 3, $fn = 16);
}

battery_slot();
