// ============================================================
// Orb V9 — 底盖（Base）
// Ø62mm × 3mm，R8 圆角，硅胶防滑垫平面
// ============================================================
include <orb_config.scad>

module base() {
    // 用 hull 做圆角底盖
    hull() {
        // 底面主体
        cylinder(h=0.1, d=base_d);
        // 顶面缩进（模拟圆角过渡）
        translate([0, 0, base_h])
            cylinder(h=0.1, d=base_d);
    }

    // 硅胶垫定位槽（浅环形凹槽）
    difference() {
        cylinder(h=0.5, d=base_d - 4);
        translate([0, 0, -0.1])
            cylinder(h=0.7, d=base_d - 8);
    }
}

base();
