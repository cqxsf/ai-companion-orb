// ============================================================// ============================================================






























































// %led_positions();  // 取消注释显示 LED 位置lightguide_ring();}    }                cube([3, 1.5, 1], center = true);            translate([led_ring_radius, 0, -1])        rotate([0, 0, angle])        angle = i * 360 / led_count;    for (i = [0 : led_count - 1]) {    color("lime", 0.6)module led_positions() {// --- LED 位置标记 (预览辅助，不打印) ---}        }            cylinder(h = 0.9, r = lightguide_inner - 0.5);            cylinder(h = 0.8, r = lightguide_outer + 0.5);        difference() {    translate([0, 0, lightguide_height])    // 轻微凸出帮助光线向外壳散射    // --- 顶部出光微台阶 ---    }        }                    cylinder(h = 2, r = 2.5);                translate([led_ring_radius, 0, -0.1])            rotate([0, 0, angle])            angle = i * 360 / led_count;        for (i = [0 : led_count - 1]) {        // 每颗 LED 对应一个小凹槽，引导光线进入光导体        // --- 底部 LED 入光槽 ---            cylinder(h = lightguide_height + 0.2, r = lightguide_inner);        translate([0, 0, -0.1])        // --- 中心空腔 (走线 + 散热) ---        cylinder(h = lightguide_height, r = lightguide_outer);        // --- 光导环主体 ---    difference() {module lightguide_ring() {include <orb_config.scad>;// ============================================================//   内壁磨砂 — 提取光线（打印层纹天然实现）//   高度 12mm — 覆盖 LED 出光角度//   光导壁厚 6mm — 足够全反射导光// 关键参数:////   LED PCB (底部) → 光导环 (侧入光) → 扩散球壳// 光路:////   效果类似 Apple HomePod / Google Nest 的光环////   从外表面均匀散射出去 → 透过上壳形成连续光带//   LED 发出的光进入光导环侧壁 → 全反射导光 →// 设计原理://// Translucent PLA 打印（关键光学件）// Orb V4 — LED 光导环// Orb V4 — LED 光导环 (Light Guide Ring)
// 核心光学组件 — 消费电子级均匀发光
//
// 设计原理:
//   LED → 光导环侧面入光 → 全内反射 → 均匀出光
//   类似 Apple HomePod / Google Nest 的环形光带效果
//
// 打印材料: Translucent PLA (透光率约60%)
// 光导壁厚 6mm 是 LED 均匀混光的关键参数
//
// 结构:
//   ╭──────────────╮
//   │  出光面(顶部) │  → 光线向上进入扩散球壳
//   ├──────────────┤
//   │  光导体      │  → 全内反射混合光线
//   ├──────────────┤
//   │  入光面(底部) │  → LED 从底部侧向注入光线
//   ╰──────────────╯
// ============================================================

include <orb_config.scad>;

module lightguide_ring() {
    difference() {
        // --- 光导体 (实心环) ---
        cylinder(h = lightguide_height, r = lightguide_outer);

        // --- 中心通孔 (走线 + 散热) ---
        translate([0, 0, -0.1])
            cylinder(h = lightguide_height + 0.2, r = lightguide_inner);

        // --- 顶部出光面微锥角 (改善出光均匀性) ---
        // 顶面内侧倒角 1mm × 45°，引导光线向外扩散
        translate([0, 0, lightguide_height - 1])
            difference() {
                cylinder(h = 1.1, r = lightguide_outer + 0.1);
                cylinder(h = 1.1, r1 = lightguide_inner, r2 = lightguide_inner + 1);
            }
    }
}

// --- LED 入光口标记 (辅助可视化) ---
module led_positions() {
    color("green", 0.4)
    for (i = [0 : led_count - 1]) {
        rotate([0, 0, i * 360 / led_count])
            translate([led_ring_radius, 0, 0])
                cube([1.5, 1.5, 1], center = true);
    }
}

lightguide_ring();
// %led_positions();  // 取消注释可显示 LED 位置
