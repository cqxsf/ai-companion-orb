// ============================================================
// Orb V4 — 上壳（扩散球壳）
// Translucent PLA 打印，光导环光线通过此壳均匀散射
//
// 设计要点:
//   - 球体上半部分，底部卡扣与中框配合
//   - 壁厚 2.2mm 配合透光 PLA 实现柔光效果
//   - 内壁带光导环定位台阶
//   - 分模线在球体赤道略下方，打印时无需支撑
// ============================================================

include <orb_config.scad>;

module orb_shell_top() {
    // 分模线 Z 位置：从球心向下 cut_depth
    cut_z = -(orb_height - top_height - orb_radius);

    difference() {
        // --- 外壳球体 ---
        sphere(r = orb_radius);

        // --- 内腔 ---
        sphere(r = orb_radius - wall);

        // --- 底部平切 ---
        translate([0, 0, -orb_radius - 1])
            cylinder(h = orb_radius + 1 + cut_z, r = orb_radius + 1);

        // --- 光导环定位槽 (内壁) ---
        // 光导环从内侧嵌入上壳底部
        translate([0, 0, cut_z - 0.1])
            difference() {
                cylinder(h = lightguide_height + 1,
                         r = lightguide_outer + snap_fit_tol);
                cylinder(h = lightguide_height + 1,
                         r = lightguide_inner - 1);
            }
    }

    // --- 卡扣凸缘 (与中框配合) ---
    translate([0, 0, cut_z])
        difference() {
            cylinder(h = 4, r = orb_radius - wall);
            cylinder(h = 4.1, r = orb_radius - wall - 2);
        }
}

orb_shell_top();
