// ============================================================
// Orb V8 — 中壳 · 主结构体（31mm）
// 材料：Soft-touch ABS / PLA+
//
// Z 范围：split_base(15) → split_mid(46)
// 三段曲率的腹部段：从底座宽度渐展至 equator，再收窄至光罩
// 4 颗麦克风拾音孔贯穿
// PCB 螺丝柱 4 点均布
// ============================================================

include <orb_config.scad>;

module orb_shell_middle() {
    difference() {
        // === 外壁 ===
        intersection() {
            rotate_extrude()
                polygon(v8_profile(120, 0));
            translate([0, 0, split_base])
                cylinder(h = mid_h + 0.1, r = orb_radius + 1);
        }

        // === 内腔 ===
        intersection() {
            rotate_extrude()
                polygon(v8_profile(120, wall));
            translate([0, 0, split_base - 0.1])
                cylinder(h = mid_h + 0.3, r = orb_radius);
        }

        // === 麦克风拾音孔（4 颗，Z = 中壳中段）===
        mic_z = split_base + mid_h * 0.4;
        for (a = mic_angles) {
            rotate([0, 0, a])
                translate([v8_r(mic_z) - wall + 1, 0, mic_z])
                    rotate([0, 90, 0])
                        cylinder(h = wall + 4, r = mic_hole_r);
        }
    }

    // === 上部卡扣槽（接收光罩凸缘）===
    r_top = v8_r(split_mid);
    translate([0, 0, split_mid - 4])
        difference() {
            cylinder(h = 4, r = r_top - wall + snap_tol + 2);
            cylinder(h = 4.1, r = r_top - wall - 1 + snap_tol);
        }

    // === 下部卡扣凸缘（嵌入底座）===
    r_bot = v8_r(split_base);
    translate([0, 0, split_base])
        difference() {
            cylinder(h = 3, r = r_bot + wall);
            cylinder(h = 3.1, r = r_bot + wall - 2);
        }

    // === PCB 螺丝柱（4 点均布）===
    for (a = pcb_angles)
        rotate([0, 0, a])
            translate([pcb_mount_r, 0, split_base])
                difference() {
                    cylinder(h = 10, r = screw_post_r);
                    cylinder(h = 10.1, r = screw_hole_r);
                }
}

orb_shell_middle();
