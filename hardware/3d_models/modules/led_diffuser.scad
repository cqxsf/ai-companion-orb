// ============================================================
// Orb V2 — LED 光学扩散腔
// 消除 LED 亮点，实现均匀柔光
// ============================================================

// --- 参数 ---
cavity_outer_r = 32;     // 腔体外径
cavity_inner_r = 30;     // 腔体内径
cavity_height  = 12;     // 腔体高度
wall_thick     = 2;      // 壁厚
led_ring_r     = 30;     // LED 环半径
led_count      = 24;     // LED 数量

module led_diffuser() {
    difference() {
        // 外壁
        cylinder(h = cavity_height, r = cavity_outer_r, $fn = 80);

        // 内腔（光混合空间）
        translate([0, 0, wall_thick])
            cylinder(h = cavity_height - wall_thick + 0.1, r = cavity_inner_r, $fn = 80);
    }
}

// LED 环位置标记（辅助对位，不打印）
module led_ring_markers() {
    color("green", 0.5)
    for (i = [0 : led_count - 1]) {
        angle = i * 360 / led_count;
        rotate([0, 0, angle])
            translate([led_ring_r, 0, 0])
                cube([2, 2, 1], center = true);
    }
}

// 二次扩散片支撑环（放在扩散腔顶部）
module diffuser_ring() {
    translate([0, 0, cavity_height])
        difference() {
            cylinder(h = 1.5, r = cavity_outer_r, $fn = 80);
            cylinder(h = 1.6, r = cavity_inner_r - 2, $fn = 80);
        }
}

led_diffuser();
diffuser_ring();
// %led_ring_markers();  // 取消注释可显示 LED 位置
