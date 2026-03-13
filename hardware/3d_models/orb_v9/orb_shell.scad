// ============================================================
// Orb V9 — 椭球壳体生成
// 连续椭球体：(x/56)² + (z/43)² = 1
// ============================================================
include <orb_config.scad>

// 椭球旋转体（外壳）
module v9_ellipsoid(rx, ry, wall=0) {
    // scale 把单位球变成椭球
    // resize 更直观但 scale 对 rotate_extrude 更稳定
    rotate_extrude(convexity=4)
        difference() {
            // 外椭圆
            scale([1, ry/rx])
                circle(r=rx);
            // 如果 wall>0，挖内椭圆
            if (wall > 0)
                scale([1, (ry-wall)/(rx-wall)])
                    circle(r=rx-wall);
            // 只保留右半（rotate_extrude 需要）
            translate([-rx*2, -ry*2])
                square([rx*2, ry*4]);
        }
}

// 完整外壳（空心椭球）
module v9_shell() {
    translate([0, 0, ry])  // 底部对齐 z=0
        v9_ellipsoid(rx, ry, wall);
}

// 实心椭球（用于切割参考）
module v9_solid() {
    translate([0, 0, ry])
        v9_ellipsoid(rx, ry, 0);
}
