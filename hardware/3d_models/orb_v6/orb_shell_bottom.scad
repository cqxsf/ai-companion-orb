// ============================================================
// Orb V6 — 底座
// 材料：PLA+
//
// V6 关键改进：
//   - 外壁用 hull() 做底边倒圆角，产生"鹅卵石"底部
//   - 上端半径 base_r_top（37mm）与中框平滑对接
//   - 底面半径 base_r_bot（32mm）保证桌面稳定
//   - 底部环形声孔阵列 + 倒相管出口
//   - USB-C 侧开口（椭圆形过孔）
//   - 硅胶垫环形槽（防滑）
// ============================================================

include <orb_config.scad>;

module orb_shell_bottom() {
    difference() {
        // === 外壁：带底边倒圆角的锥筒 ===
        hull() {
            // 顶圆（接中框）
            translate([0, 0, pcb_zone_h - 0.1])
                cylinder(h = 0.1, r = base_r_top);
            // 底圆（桌面接触圈，稍内缩）
            translate([0, 0, base_fillet])
                cylinder(h = 0.1, r = base_r_bot);
            // 底边倒圆角用小环
            translate([0, 0, base_fillet])
                rotate_extrude()
                    translate([base_r_bot - base_fillet, 0])
                        circle(r = base_fillet);
        }

        // === 内腔 ===
        translate([0, 0, wall])
            hull() {
                translate([0, 0, pcb_zone_h - wall - 0.1])
                    cylinder(h = 0.1, r = base_r_top - wall);
                translate([0, 0, base_fillet])
                    cylinder(h = 0.1, r = base_r_bot - wall - 1);
            }

        // === 底部声孔阵列（环形均布）===
        for (i = [0 : vent_count - 1]) {
            angle = i * 360 / vent_count;
            rotate([0, 0, angle])
                translate([vent_ring_r, 0, -0.1])
                    cylinder(h = wall + 0.2, r = vent_r);
        }

        // === 倒相管出口孔 ===
        translate([bass_port_offset, 0, -0.1])
            cylinder(h = wall + 0.2, r = bass_port_r + 0.5);

        // === 硅胶垫环形槽（底面防滑）===
        translate([0, 0, -0.01])
            difference() {
                cylinder(h = silicone_thick + 0.01, r = silicone_r_out);
                cylinder(h = silicone_thick + 0.01, r = silicone_r_in);
            }

        // === USB-C 侧开口（椭圆形）===
        // 位置：底座侧面，距底部 8mm
        translate([0, base_r_bot - wall/2, 8])
            rotate([90, 0, 0])
                hull() {
                    translate([-(usbc_w/2 - usbc_h_cutout/2), 0, 0])
                        cylinder(h = wall + 1, r = usbc_h_cutout/2);
                    translate([ (usbc_w/2 - usbc_h_cutout/2), 0, 0])
                        cylinder(h = wall + 1, r = usbc_h_cutout/2);
                }
    }

    // === 上部卡扣槽（接收中框凸缘）===
    translate([0, 0, pcb_zone_h])
        difference() {
            cylinder(h = 3, r = base_r_top + wall + snap_tol);
            cylinder(h = 3.1, r = base_r_top + wall - 2 - snap_tol);
        }

    // === 电池管（中心立柱）===
    translate([0, 0, wall])
        difference() {
            cylinder(h = batt_h + 3, r = batt_r + wall);
            cylinder(h = batt_h + 3.1, r = batt_r);
        }

    // === 倒相管（内置）===
    translate([bass_port_offset, 0, wall])
        difference() {
            cylinder(h = bass_port_len, r = bass_port_r + wall);
            cylinder(h = bass_port_len + 0.1, r = bass_port_r);
        }
}

orb_shell_bottom();
