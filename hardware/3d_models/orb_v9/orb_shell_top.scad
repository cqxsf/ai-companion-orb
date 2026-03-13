// ============================================================
// Orb V9 — 上壳（Shell_Top）
// 从灯环上沿到顶盖缝隙下沿
// ============================================================
include <orb_config.scad>
use <orb_shell.scad>

module shell_top() {
    z_bot = split_z + ring_h/2;
    z_top = orb_height;
    cap_zone_h = cap_h + cap_gap;

    difference() {
        v9_shell();

        // 切掉下半部分
        translate([0, 0, -1])
            cylinder(h=z_bot+1, r=rx+1);

        // 切掉顶盖区域
        translate([0, 0, z_top - cap_zone_h])
            cylinder(h=cap_zone_h+1, r=rx+1);
    }
}

shell_top();
