"""
Orb V9 — FreeCAD 参数化建模脚本

用法：
  1. 打开 FreeCAD
  2. 菜单 → Macro → Execute Macro → 选择此文件
  3. 自动生成 5 个零件 + 装配体

零件清单：
  1. Top_Cap     — 浮岛式顶盖（Ø92mm × 6mm）
  2. Shell_Top   — 上壳（椭球上半 + 灯环槽）
  3. LED_Ring    — 隐藏式灯环扩散罩（4mm 高磨砂 PC）
  4. Shell_Bot   — 下壳（椭球下半）
  5. Base        — 底盖（Ø62mm × 3mm + R8 圆角）

椭球方程：(x/56)² + (y/43)² = 1，绕 Z 轴旋转
"""

import math

try:
    import FreeCAD
    import Part
    from FreeCAD import Base
    HAS_FREECAD = True
except ImportError:
    HAS_FREECAD = False
    print("[WARN] FreeCAD 未安装，仅验证参数。")
    print("       请在 FreeCAD 环境中运行此脚本。")

# ─── 参数 ──────────────────────────────────────────────────
# 整机
D = 112.0           # 直径
RX = 56.0           # 椭球 X 半径
RY = 43.0           # 椭球 Y 半径（高度方向）
H = 86.0            # 总高
WALL = 2.2          # 壁厚

# 分割
SPLIT_Z = 44.0      # 上下壳分割高度
RING_H = 4.0        # 灯环高度
RING_T = 1.5        # 灯环壁厚

# 顶盖
CAP_D = 92.0        # 顶盖直径
CAP_H = 6.0         # 顶盖厚度
CAP_GAP = 0.6       # 浮岛缝隙
CAP_R = 4.0         # 顶盖圆角

# 底盖
BASE_D = 62.0       # 底部平面直径
BASE_H = 3.0        # 底盖厚度
BASE_R = 8.0        # 底部圆角

# 装配
SCREW_D = 2.2       # 螺丝孔直径 (M2)
SCREW_BOSS_D = 5.0  # 螺丝柱直径
N_SCREWS = 4
SCREW_RING_R = 24.0 # 螺丝柱环半径

# 麦克风
MIC_COUNT = 4
MIC_HOLE_D = 1.0
MIC_RING_R = 21.0   # 麦克风孔环半径（在顶盖缝隙处）

# ─── 椭球轮廓点生成 ───────────────────────────────────────
def ellipse_profile_points(rx, ry, n_pts=120):
    """生成右侧椭圆轮廓点（用于旋转体）。
    椭球中心在原点，Z 轴为旋转轴。
    返回 [(x, z), ...] 从底部到顶部。
    """
    pts = []
    for i in range(n_pts + 1):
        theta = -math.pi / 2 + math.pi * i / n_pts  # -π/2 到 π/2
        x = rx * math.cos(theta)
        z = ry * math.sin(theta) + ry  # 平移使底部 z=0
        pts.append((x, z))
    return pts


def ellipse_r_at_z(z, rx, ry):
    """给定高度 z，返回椭球半径 r。
    椭球中心在 z=ry，方程: (r/rx)² + ((z-ry)/ry)² = 1
    """
    t = (z - ry) / ry
    if abs(t) > 1.0:
        return 0.0
    return rx * math.sqrt(1.0 - t * t)


# ─── FreeCAD 建模函数 ─────────────────────────────────────

def make_ellipsoid_shell():
    """创建椭球壳体（外壳 - 内壳）"""
    # 外椭球轮廓线
    pts_outer = []
    for x, z in ellipse_profile_points(RX, RY):
        pts_outer.append(Base.Vector(x, 0, z))

    # 闭合轮廓（加入旋转轴上的点）
    pts_outer.insert(0, Base.Vector(0, 0, 0))
    pts_outer.append(Base.Vector(0, 0, H))

    wire_outer = Part.makePolygon(pts_outer)
    face_outer = Part.Face(wire_outer)
    solid_outer = face_outer.revolve(Base.Vector(0, 0, 0), Base.Vector(0, 0, 1), 360)

    # 内椭球
    inner_rx = RX - WALL
    inner_ry = RY - WALL
    pts_inner = []
    for x, z in ellipse_profile_points(inner_rx, inner_ry):
        pts_inner.append(Base.Vector(x, 0, z + WALL))

    pts_inner.insert(0, Base.Vector(0, 0, WALL))
    pts_inner.append(Base.Vector(0, 0, H - WALL))

    wire_inner = Part.makePolygon(pts_inner)
    face_inner = Part.Face(wire_inner)
    solid_inner = face_inner.revolve(Base.Vector(0, 0, 0), Base.Vector(0, 0, 1), 360)

    shell = solid_outer.cut(solid_inner)
    return shell, solid_outer


def make_shell_top(full_shell, solid_outer):
    """上壳：从 SPLIT_Z + RING_H/2 到 H - CAP_H - CAP_GAP"""
    z_bot = SPLIT_Z + RING_H / 2
    z_top = H

    # 切割块
    cut_bot = Part.makeBox(D * 2, D * 2, z_bot,
                           Base.Vector(-D, -D, 0))
    cut_top_cap_zone = Part.makeBox(D * 2, D * 2, CAP_H + CAP_GAP,
                                     Base.Vector(-D, -D, H - CAP_H - CAP_GAP))

    shell_top = full_shell.cut(cut_bot)
    shell_top = shell_top.cut(cut_top_cap_zone)

    # 顶盖缝隙处的麦克风孔
    for i in range(MIC_COUNT):
        angle = i * 360.0 / MIC_COUNT
        rad = math.radians(angle)
        mx = MIC_RING_R * math.cos(rad)
        my = MIC_RING_R * math.sin(rad)
        mic_hole = Part.makeCylinder(MIC_HOLE_D / 2, WALL * 2,
                                     Base.Vector(mx, my, H - CAP_H - CAP_GAP - 1))
        shell_top = shell_top.cut(mic_hole)

    return shell_top


def make_shell_bottom(full_shell):
    """下壳：从 BASE_H 到 SPLIT_Z - RING_H/2"""
    z_top = SPLIT_Z - RING_H / 2

    cut_top = Part.makeBox(D * 2, D * 2, H,
                           Base.Vector(-D, -D, z_top))
    cut_base = Part.makeBox(D * 2, D * 2, BASE_H,
                            Base.Vector(-D, -D, 0))

    shell_bot = full_shell.cut(cut_top)
    shell_bot = shell_bot.cut(cut_base)

    # 螺丝柱
    for i in range(N_SCREWS):
        angle = (i * 360.0 / N_SCREWS) + 45  # 偏移 45° 避开灯环扣位
        rad = math.radians(angle)
        bx = SCREW_RING_R * math.cos(rad)
        by = SCREW_RING_R * math.sin(rad)

        boss = Part.makeCylinder(SCREW_BOSS_D / 2, z_top - BASE_H,
                                 Base.Vector(bx, by, BASE_H))
        hole = Part.makeCylinder(SCREW_D / 2, z_top - BASE_H + 1,
                                 Base.Vector(bx, by, BASE_H - 0.5))
        boss = boss.cut(hole)
        shell_bot = shell_bot.fuse(boss)

    return shell_bot


def make_led_ring():
    """LED 灯环扩散罩：4mm 高环形，位于分割线处"""
    z_bot = SPLIT_Z - RING_H / 2
    r_outer = ellipse_r_at_z(SPLIT_Z, RX, RY)
    r_inner = r_outer - RING_T

    ring_outer = Part.makeCylinder(r_outer, RING_H,
                                   Base.Vector(0, 0, z_bot))
    ring_inner = Part.makeCylinder(r_inner, RING_H,
                                   Base.Vector(0, 0, z_bot))
    ring = ring_outer.cut(ring_inner)
    return ring


def make_top_cap():
    """浮岛式顶盖：Ø92mm × 6mm，带 R4 圆角"""
    cap = Part.makeCylinder(CAP_D / 2, CAP_H,
                            Base.Vector(0, 0, H - CAP_H))
    # 圆角
    cap = cap.makeFillet(CAP_R, cap.Edges)
    return cap


def make_base():
    """底盖：Ø62mm × 3mm，带 R8 圆角"""
    base = Part.makeCylinder(BASE_D / 2, BASE_H,
                             Base.Vector(0, 0, 0))
    # 圆角
    edges_to_fillet = [e for e in base.Edges
                       if abs(e.BoundBox.ZMin) < 0.1 or abs(e.BoundBox.ZMax - BASE_H) < 0.1]
    if edges_to_fillet:
        base = base.makeFillet(min(BASE_R, BASE_H - 0.5), edges_to_fillet)
    return base


# ─── 主流程 ────────────────────────────────────────────────

def build_orb_v9():
    if not HAS_FREECAD:
        print("\n═══ Orb V9 参数验证 ═══")
        print(f"直径: {D}mm  高度: {H}mm  比例: {H / D:.2f}")
        print(f"椭球: rx={RX}  ry={RY}")
        print(f"分割高度: {SPLIT_Z}mm")
        print(f"灯环: {RING_H}mm 高 / {RING_T}mm 厚")
        print(f"顶盖: Ø{CAP_D}mm × {CAP_H}mm / 缝隙 {CAP_GAP}mm")
        print(f"底盖: Ø{BASE_D}mm × {BASE_H}mm / R{BASE_R}")
        print(f"分割处半径: {ellipse_r_at_z(SPLIT_Z, RX, RY):.1f}mm (Ø{2*ellipse_r_at_z(SPLIT_Z, RX, RY):.1f}mm)")
        print(f"螺丝: M2×6 × {N_SCREWS}")
        print(f"麦克风: {MIC_COUNT} 孔 / Ø{MIC_HOLE_D}mm")
        print("\n请在 FreeCAD 中运行此脚本以生成 3D 模型。")
        return

    doc = FreeCAD.newDocument("Orb_V9")

    print("Step 1/5: 生成椭球壳体...")
    full_shell, solid_outer = make_ellipsoid_shell()

    print("Step 2/5: 上壳 (Shell_Top)...")
    shell_top = make_shell_top(full_shell, solid_outer)
    obj = doc.addObject("Part::Feature", "Shell_Top")
    obj.Shape = shell_top

    print("Step 3/5: 下壳 (Shell_Bottom)...")
    shell_bot = make_shell_bottom(full_shell)
    obj = doc.addObject("Part::Feature", "Shell_Bottom")
    obj.Shape = shell_bot

    print("Step 4/5: LED 灯环 (LED_Ring)...")
    led_ring = make_led_ring()
    obj = doc.addObject("Part::Feature", "LED_Ring")
    obj.Shape = led_ring

    print("Step 5a/5: 顶盖 (Top_Cap)...")
    top_cap = make_top_cap()
    obj = doc.addObject("Part::Feature", "Top_Cap")
    obj.Shape = top_cap

    print("Step 5b/5: 底盖 (Base)...")
    base = make_base()
    obj = doc.addObject("Part::Feature", "Base")
    obj.Shape = base

    doc.recompute()

    # 导出 STL
    import os
    export_dir = os.path.join(os.path.dirname(__file__), "exports")
    os.makedirs(export_dir, exist_ok=True)

    parts = {
        "Shell_Top": shell_top,
        "Shell_Bottom": shell_bot,
        "LED_Ring": led_ring,
        "Top_Cap": top_cap,
        "Base": base,
    }
    for name, shape in parts.items():
        stl_path = os.path.join(export_dir, f"orb_v9_{name.lower()}.stl")
        shape.exportStl(stl_path)
        print(f"  导出: {stl_path}")

    # 保存 FreeCAD 工程
    fcstd_path = os.path.join(os.path.dirname(__file__), "Orb_V9.FCStd")
    doc.saveAs(fcstd_path)
    print(f"\n工程保存: {fcstd_path}")
    print("═══ Orb V9 建模完成 ═══")

    return doc


if __name__ == "__main__":
    build_orb_v9()
