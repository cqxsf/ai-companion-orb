// ============================================================
// Orb V6 — 上壳（光扩散罩）
// 材料：Translucent PLA / PETG（透光率 ~60%）
//
// V6 关键改进：
//   - 使用扁椭球（scale([1,1,top_rz/top_rx])）而非正球
//   - 分模线在椭球腰部以上，底部自然收窄，无"灯泡肚"
//   - 内壁光导环定位台阶精确对位
//   - 底部卡扣凸缘厚度 3mm，4 点均布开槽防止应力集中
// ============================================================

include <orb_config.scad>;

module orb_shell_top() {
    // 分模线 Z（相对椭球中心）
    // 椭球中心置于 Z=split_top
    ellipsoid_center_z = split_top;

    // 分模线在椭球中心以下 10mm，产生腰线内收效果
    cut_z_local = -10;  // 相对椭球中心

    difference() {
        // === 外壁：扁椭球 ===
        translate([0, 0, ellipsoid_center_z])
            scale([1, 1, top_rz/top_rx])
                sphere(r = top_rx);

        // === 内腔：略小的扁椭球 ===
        translate([0, 0, ellipsoid_center_z])
            scale([1, 1, top_rz/top_rx])
                sphere(r = top_rx - wall);

        // === 切除椭球下半部分（分模线以下） ===
        translate([0, 0, ellipsoid_center_z + cut_z_local - orb_height])
            cube([orb_diameter * 2, orb_diameter * 2, orb_height],
                 center = false);
        translate([-(orb_diameter), -(orb_diameter),
                   ellipsoid_center_z + cut_z_local - orb_height])
            cube([orb_diameter * 2, orb_diameter * 2, orb_height]);

        // === 光导环定位槽（内壁底部）===
        // 光导环从内侧嵌入，定位台阶深 2mm
        translate([0, 0, split_top + cut_z_local - lightguide_h - 2])
            difference() {
                cylinder(h = lightguide_h + 2.1,
                         r = lightguide_outer + snap_tol);
                cylinder(h = lightguide_h + 2.1,
                         r = lightguide_inner - 2);
            }
    }

    // === 底部卡扣凸缘 ===
    // 4 点开槽减少卡扣应力
    snap_z = ellipsoid_center_z + cut_z_local;
    translate([0, 0, snap_z - 4])
        difference() {
            cylinder(h = 4, r = top_rx - wall - snap_tol);
            cylinder(h = 4.1, r = top_rx - wall - 3 - snap_tol);
            // 4 点开槽
            for (a = [0, 90, 180, 270])
                rotate([0, 0, a])
                    translate([top_rx - wall - 1.5, 0, -0.05])
                        cube([2, 2, 4.2], center = true);
        }
}

orb_shell_top();
