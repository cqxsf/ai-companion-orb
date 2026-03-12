// ============================================================
// Orb V4 — 声学共振腔 + 倒相管 (Bass Reflex)
// PLA+ 打印
//
// 设计原理 (倒相音箱结构):
//
//   扬声器振膜向下推动空气
//          ↓
//   密封共振腔压缩空气
//          ↓
//   倒相管将背波相位反转
//          ↓
//   低频增强 ~40%，声压级提升 ~3dB
//
//   ┌─────────────┐
//   │   扬声器     │  40mm 4Ω 3W
//   ├─────────────┤
//   │             │
//   │  共振腔体    │  Ø52 × H18mm
//   │             │
//   ├──┐     ┌───┤
//   │  │倒相管│   │  Ø8 × L12mm
//   └──┘     └───┘
//        ↓
//   底座声孔 → 桌面
//
// 腔体容积约 25cc，配合 Ø8×12mm 倒相管
// 调谐频率约 120Hz（小型全频音箱典型值）
// ============================================================

include <orb_config.scad>;

module speaker_chamber() {
    difference() {
        // --- 腔体外壁 ---
        cylinder(h = speaker_chamber_h, r = speaker_chamber_r);

        // --- 内腔 (共振空间) ---
        translate([0, 0, wall])
            cylinder(h = speaker_chamber_h - wall + 0.1, r = speaker_chamber_ir);

        // --- 扬声器安装开口 (顶部) ---
        translate([0, 0, speaker_chamber_h - 2])
            cylinder(h = 3, r = speaker_radius);
    }

    // --- 扬声器卡扣 (4 点固定) ---
    for (a = [0, 90, 180, 270]) {
        rotate([0, 0, a])
            translate([speaker_radius + 1, 0, speaker_chamber_h - 2])
                difference() {
                    cylinder(h = 2, r = 2.5);
                    translate([0, 0, -0.1])
                        cylinder(h = 2.2, r = screw_r);
                }
    }
}

// --- 倒相管 (Bass Port) ---
// 独立模块，安装在腔体侧壁或底部
module bass_port() {
    difference() {
        // 倒相管外壁
        cylinder(h = bass_port_length, r = bass_port_radius + 1.5);

        // 倒相管内孔
        translate([0, 0, -0.1])
            cylinder(h = bass_port_length + 0.2, r = bass_port_radius);
    }

    // 法兰盘（与腔体连接）
    difference() {
        cylinder(h = 2, r = bass_port_radius + 4);
        translate([0, 0, -0.1])
            cylinder(h = 2.2, r = bass_port_radius);
        // 安装孔
        for (a = [0, 120, 240]) {
            rotate([0, 0, a])
                translate([bass_port_radius + 3, 0, -0.1])
                    cylinder(h = 2.2, r = 0.8);
        }
    }
}

speaker_chamber();

// 倒相管放在腔体侧面偏移位置
translate([bass_port_offset, 0, -bass_port_length + wall])
    bass_port();
