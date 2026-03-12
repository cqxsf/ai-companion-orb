// ============================================================
// Orb V4 — 中框（结构骨架）
// PLA+ 打印，不透光
//
// 设计要点:
//   - 承载 PCB、LED 环、光导环的核心结构件
//   - 上接上壳（卡扣），下接底座（卡扣）
//   - 内壁集成 PCB 支撑柱和 LED 环定位
//   - 中框外壁与球面曲率匹配（视觉连续）
//   - 麦克风拾音孔贯穿中框壁面
// ============================================================

include <orb_config.scad>;

module orb_shell_middle() {
    // 中框的 Z 范围在球体下半部分
    // 外壁跟随球面曲率，保持整机圆润

    difference() {
        // --- 外壁 (跟随球面曲率) ---
        intersection() {
            sphere(r = orb_radius);
            translate([0, 0, -orb_radius])
                cylinder(h = mid_height + (orb_radius - orb_height + top_height),
                         r = orb_radius);
        }

        // --- 内腔 ---
        intersection() {
            sphere(r = orb_radius - wall);
            translate([0, 0, -orb_radius])
                cylinder(h = mid_height + (orb_radius - orb_height + top_height) + 0.1,
                         r = orb_radius);
        }

        // --- 切掉上壳区域 ---
        cut_z = -(orb_height - top_height - orb_radius);
        translate([0, 0, cut_z])
            cylinder(h = orb_radius * 2, r = orb_radius + 1);

        // --- 切掉底座区域 ---
        translate([0, 0, -orb_radius - 1])
            cylinder(h = orb_radius - orb_height + top_height + mid_height + 1 - 0.01,
                     r = orb_radius + 1);

        // --- 麦克风拾音孔 ---
        for (a = mic_angles) {
            rotate([0, 0, a])
                translate([orb_radius - wall - 1, 0, -(orb_height - top_height - mid_height/2 - orb_radius)])
                    rotate([0, 90, 0])
                        cylinder(h = wall + 2, r = mic_hole_r);
        }
    }

    // --- 上部卡扣槽 (接收上壳凸缘) ---
    cut_z_top = -(orb_height - top_height - orb_radius);
    translate([0, 0, cut_z_top - 4])
        difference() {
            cylinder(h = 4, r = orb_radius - wall + snap_fit_tol);
            cylinder(h = 4.1, r = orb_radius - wall - 2 - snap_fit_tol);
        }

    // --- 下部卡扣凸缘 (与底座配合) ---
    cut_z_bot = -(orb_height - top_height - orb_radius) - mid_height;
    translate([0, 0, cut_z_bot])
        difference() {
            cylinder(h = 3, r = base_radius + wall);
            cylinder(h = 3.1, r = base_radius + wall - 2);
        }
}

orb_shell_middle();
