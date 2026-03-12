// ============================================================
// Orb V4 — 全局参数配置
// AI Companion Orb 量产级结构设计
//
// 所有模块 include 此文件获取统一尺寸
// 修改这里的参数即可全局调整整机比例
// ============================================================

// --- 工业设计比例 ---
// 消费电子黄金比例: 高度 = 直径 × 0.82
orb_diameter    = 92;                       // 外径 92mm
orb_radius      = orb_diameter / 2;         // 46mm
orb_height      = 75;                       // 总高度 75mm (0.82 比例)
wall            = 2.2;                      // 壁厚 (注塑级)

// --- 三件式分模 ---
top_height      = 38;                       // 上壳高度 (球顶到分模线)
mid_height      = 20;                       // 中框高度
bottom_height   = 17;                       // 底座高度
// 合计: 38 + 20 + 17 = 75mm

// --- LED 光学 ---
led_ring_diameter   = 60;                   // LED 环直径
led_ring_radius     = led_ring_diameter / 2;
led_count           = 24;                   // WS2812B 数量
led_spacing         = 3.14159 * led_ring_diameter / led_count; // ~7.85mm

// --- 光导环 ---
lightguide_outer    = 34;                   // 光导环外径
lightguide_inner    = 28;                   // 光导环内径 (壁厚 6mm)
lightguide_height   = 12;                   // 光导环高度
lightguide_wall     = lightguide_outer - lightguide_inner; // 6mm

// --- PCB ---
pcb_diameter        = 65;                   // 主控 PCB 直径
pcb_radius          = pcb_diameter / 2;
pcb_thick           = 1.6;                  // PCB 板厚
pcb_mount_r         = 28;                   // 安装柱到中心距离
pcb_mount_angles    = [0, 120, 240];        // 3 点均布

// --- 扬声器 ---
speaker_diameter    = 40;                   // 扬声器直径
speaker_radius      = speaker_diameter / 2;
speaker_chamber_h   = 18;                   // 共振腔高度
speaker_chamber_r   = 26;                   // 共振腔外径
speaker_chamber_ir  = 22;                   // 共振腔内径
speaker_wall        = speaker_chamber_r - speaker_chamber_ir; // 4mm

// --- 倒相管 (Bass Reflex) ---
bass_port_diameter  = 8;                    // 倒相管直径
bass_port_radius    = bass_port_diameter / 2;
bass_port_length    = 12;                   // 倒相管长度
bass_port_offset    = 18;                   // 倒相管到中心距离

// --- 麦克风阵列 ---
mic_count           = 3;                    // INMP441 × 3
mic_radius          = 25;                   // 麦克风到中心距离
mic_hole_r          = 1;                    // 拾音孔半径 Ø2mm
mic_angles          = [0, 120, 240];        // 120° 均布

// --- 电池 ---
battery_diameter    = 18;                   // 18650 直径
battery_length      = 65;                   // 18650 长度
battery_padding     = 1;                    // 电池槽间隙

// --- 底座 ---
base_diameter       = 62;                   // 底面直径
base_radius         = base_diameter / 2;
silicone_pad_thick  = 1;                    // 硅胶垫厚度

// --- 声孔 ---
sound_hole_r        = 1.5;                  // Ø3mm 声孔
sound_hole_count    = 8;

// --- 装配 ---
snap_fit_tol        = 0.15;                 // 卡扣配合间隙
screw_r             = 1.1;                  // M2 螺孔半径
screw_head_r        = 2;                    // M2 螺帽半径

// --- 渲染精度 ---
$fn = 200;                                  // 全局精度 (渲染用)
$fn_preview = 60;                           // 预览精度 (F5 用)
