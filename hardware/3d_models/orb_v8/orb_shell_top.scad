// ============================================================
// Orb V8 — 上壳 · 光扩散罩（22mm）
// 材料：磨砂 PC / Translucent PETG
//
// Z 范围：split_mid(46) → orb_height(68)
// 三段曲率的顶部椭圆弧段，自然收尖至顶点
// 底边卡扣 4 点开槽，光导环定位台阶
// ============================================================

include <orb_config.scad>;

module orb_shell_top() {
    difference() {
        // === 外壁（轮廓曲线旋转体，取 Z≥split_mid 段）===
        intersection() {
            rotate_extrude()
                polygon(v8_profile(120, 0));
            // 只保留 split_mid 以上部分
            translate([0, 0, split_mid])
                cylinder(h = top_h + 1, r = orb_radius + 1);
        }

        // === 内腔 ===
        intersection() {
            rotate_extrude()
                polygon(v8_profile(120, wall));
            translate([0, 0, split_mid - 0.1])
                cylinder(h = top_h + 1.2, r = orb_radius);
        }

        // === 光导环定位槽（内壁底部）===
        translate([0, 0, split_mid - 2])
            difference() {
                cylinder(h = lg_h + 2.1, r = lg_outer + snap_tol);
                cylinder(h = lg_h + 2.1, r = lg_inner - 2);
            }
    }

    // === 底部卡扣凸缘 ===
    r_at_split = v8_r(split_mid);
    translate([0, 0, split_mid - 4])
        difference() {
            cylinder(h = 4, r = r_at_split - wall - snap_tol);
            cylinder(h = 4.1, r = r_at_split - wall - 3 - snap_tol);
            // 4 点开槽（减少卡扣应力）
            for (a = [0, 90, 180, 270])
                rotate([0, 0, a])
                    translate([r_at_split - wall - 1.5, 0, -0.05])
                        cube([2, 2, 4.2], center = true);
        }
}

orb_shell_top();
