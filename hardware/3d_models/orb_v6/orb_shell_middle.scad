// ============================================================
// Orb V6 — 中框（结构骨架）
// 材料：PLA+
//
// V6 关键改进：
//   - 外壁用旋转扫描（rotate_extrude）产生腰线，
//     最细处（Z=waist_z）半径 waist_radius=37mm
//   - 上端与椭球底边平滑衔接，下端与底座喇叭口对齐
//   - 4 颗麦克风拾音孔均布
//   - 螺丝柱 4 点固定 PCB
// ============================================================

include <orb_config.scad>;

// ─── 腰部轮廓辅助函数 ──────────────────────────────────────
// 将 Z 坐标映射为中框外壁半径，产生"卵石腰"曲线
// 用 3 段三次贝塞尔近似：上→腰→下
function mid_profile_r(z) =
    let(
        // Z 范围：split_mid(26) ~ split_top(51)
        t = (z - split_mid) / speaker_zone_h,  // 0~1
        // 控制点: 底(base_r_top=37) → 腰(waist_r=37 已是最细处) → 顶
        // 顶端需对齐椭球底边半径
        // 椭球在 z = split_top - 10 时的横截面半径:
        //   r = top_rx * sqrt(1 - ((z - split_top)/top_rz)^2)
        //   在 z=split_top-10 处: r ≈ top_rx*sqrt(1-(10/top_rz)^2)
        r_top = top_rx * sqrt(max(0, 1 - pow(10/top_rz, 2))),
        r_bot = base_r_top,
        r_mid = waist_radius,
        // 简单二次贝塞尔: P0=r_bot, P1=r_mid, P2=r_top
        r = pow(1-t,2)*r_bot + 2*(1-t)*t*r_mid + pow(t,2)*r_top
    ) r;

module orb_shell_middle() {
    // 采用旋转扫描外轮廓，精确控制腰线曲率
    // 沿 Z 轴取 40 个截面近似曲线
    steps = 40;
    dz = speaker_zone_h / steps;

    difference() {
        // === 外壁：旋转扫描腰线轮廓 ===
        union() {
            for (i = [0 : steps - 1]) {
                z0 = split_mid + i * dz;
                z1 = split_mid + (i + 1) * dz;
                r0 = mid_profile_r(z0);
                r1 = mid_profile_r(z1);
                translate([0, 0, z0])
                    cylinder(h = dz + 0.01, r1 = r0, r2 = r1);
            }
        }

        // === 内腔 ===
        union() {
            for (i = [0 : steps - 1]) {
                z0 = split_mid + i * dz;
                z1 = split_mid + (i + 1) * dz;
                r0 = mid_profile_r(z0) - wall;
                r1 = mid_profile_r(z1) - wall;
                translate([0, 0, z0 - 0.01])
                    cylinder(h = dz + 0.02, r1 = r0, r2 = r1);
            }
        }

        // === 麦克风拾音孔（4 颗，均布）===
        for (a = mic_angles) {
            // 孔位置在中框中段高度
            rotate([0, 0, a])
                translate([waist_radius + 1, 0, waist_z])
                    rotate([0, 90, 0])
                        cylinder(h = wall + 3, r = mic_hole_r);
        }

        // === PCB 平台开口（底部）===
        translate([0, 0, split_mid - 0.1])
            cylinder(h = 4, r = pcb_r + 2);
    }

    // === 上部卡扣槽（接收上壳凸缘）===
    snap_z_top = split_top - 10;
    r_at_snap = mid_profile_r(snap_z_top);
    translate([0, 0, snap_z_top - 4])
        difference() {
            cylinder(h = 4, r = r_at_snap - wall + snap_tol + 2);
            cylinder(h = 4.1, r = r_at_snap - wall - 1 + snap_tol);
        }

    // === 下部卡扣凸缘（与底座配合）===
    translate([0, 0, split_mid])
        difference() {
            cylinder(h = 3, r = base_r_top + wall);
            cylinder(h = 3.1, r = base_r_top + wall - 2);
        }

    // === PCB 螺丝柱（4 点）===
    for (a = pcb_mount_angles) {
        rotate([0, 0, a])
            translate([pcb_mount_r, 0, split_mid])
                difference() {
                    cylinder(h = 8, r = screw_post_r);
                    cylinder(h = 8.1, r = screw_hole_r);
                }
    }
}

orb_shell_middle();
