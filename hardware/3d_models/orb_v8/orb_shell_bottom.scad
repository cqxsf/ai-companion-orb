// ============================================================
// Orb V8 — 底座（15mm）
// 材料：PLA+ / 量产用硅胶包覆底面
//
// Z 范围：0 → split_base(15)
// 底部幂函数曲线段，轮廓从 Ø68 渐展
// 新特性：底部光晕 LED 槽（8 颗朝下），桌面反射光
// 硅胶垫抬高 3mm，光从间隙漫出
// ============================================================

include <orb_config.scad>;

module orb_shell_bottom() {
    difference() {
        // === 外壁（轮廓曲线 Z=0..split_base 段）===
        intersection() {
            rotate_extrude()
                polygon(v8_profile(120, 0));
            cylinder(h = split_base + 0.1, r = orb_radius + 1);
        }

        // === 内腔 ===
        intersection() {
            rotate_extrude()
                polygon(v8_profile(120, wall));
            translate([0, 0, wall])
                cylinder(h = split_base + 0.2, r = orb_radius);
        }

        // === 底部声孔阵列（环形均布）===
        for (i = [0 : vent_count - 1])
            rotate([0, 0, i * 360 / vent_count])
                translate([vent_ring_r, 0, -0.1])
                    cylinder(h = wall + 0.2, r = vent_r);

        // === 倒相管出口孔 ===
        translate([bass_offset, 0, -0.1])
            cylinder(h = wall + 0.2, r = bass_r + 0.5);

        // === 底部光晕 LED 槽（8颗，朝下斜插）===
        for (i = [0 : halo_led_count - 1])
            rotate([0, 0, i * 360 / halo_led_count])
                translate([halo_ring_r, 0, wall + 1])
                    rotate([30, 0, 0])   // 向外倾斜 30°
                        cylinder(h = 5, r = halo_led_r);

        // === 硅胶垫环形槽 ===
        translate([0, 0, -0.01])
            difference() {
                cylinder(h = sil_thick + 0.01, r = sil_r_out);
                cylinder(h = sil_thick + 0.01, r = sil_r_in);
            }

        // === USB-C 侧开口（椭圆）===
        r_at_8 = v8_r(8);
        translate([0, r_at_8 - wall/2, 8])
            rotate([90, 0, 0])
                hull() {
                    translate([-(usbc_w/2 - usbc_h/2), 0, 0])
                        cylinder(h = wall + 2, r = usbc_h/2);
                    translate([ (usbc_w/2 - usbc_h/2), 0, 0])
                        cylinder(h = wall + 2, r = usbc_h/2);
                }
    }

    // === 上部卡扣槽（接中壳凸缘）===
    r_top = v8_r(split_base);
    translate([0, 0, split_base])
        difference() {
            cylinder(h = 3, r = r_top + wall + snap_tol);
            cylinder(h = 3.1, r = r_top + wall - 2 - snap_tol);
        }

    // === 电池管（中心立柱）===
    translate([0, 0, wall])
        difference() {
            cylinder(h = base_h - wall, r = batt_r + wall);
            cylinder(h = base_h - wall + 0.1, r = batt_r);
        }

    // === 倒相管（内置）===
    translate([bass_offset, 0, wall])
        difference() {
            cylinder(h = bass_len, r = bass_r + wall);
            cylinder(h = bass_len + 0.1, r = bass_r);
        }
}

orb_shell_bottom();
