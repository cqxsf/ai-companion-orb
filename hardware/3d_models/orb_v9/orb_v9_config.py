"""
Orb V9 — 全局参数定义（FreeCAD + OpenSCAD 共用）

V9 核心设计改进（对比 V8）：
  1. 尺寸放大: Ø98mm → Ø112mm（更有存在感）
  2. 连续椭球: 消除 V6/V7/V8 的"上下拼接感"
  3. 浮岛顶盖: 悬浮式设计，0.6mm 缝隙兼做麦克风孔 + 灯光溢出
  4. 隐藏灯环: 4mm 高磨砂 PC 扩散罩，灯光从内部自然透出
  5. 5 件式装配: 顶盖/上壳/灯环/下壳/底盖

比例参考：
  V8 (HomePod mini)  H:W = 0.69  (Ø98 × H68)
  V9 (桌面情绪物件)  H:W = 0.77  (Ø112 × H86)
"""

# ─── 整机尺寸 ──────────────────────────────────────────────
ORB_DIAMETER = 112.0         # 整体直径 mm
ORB_RADIUS_X = 56.0          # 椭球 X 轴半径
ORB_RADIUS_Y = 43.0          # 椭球 Y 轴半径（高度方向）
ORB_HEIGHT = 86.0            # 整体高度
HW_RATIO = ORB_HEIGHT / ORB_DIAMETER  # 0.77

WALL_THICKNESS = 2.2         # 壳壁厚度

# ─── 椭球方程 ──────────────────────────────────────────────
# (x/56)^2 + (y/43)^2 = 1
# 旋转体: 绕 Y 轴旋转生成

# ─── 分割高度 ──────────────────────────────────────────────
SPLIT_HEIGHT = 44.0          # 上下壳分割高度（从底部计）
LED_RING_HEIGHT = 4.0        # 灯环槽高度
LED_RING_THICKNESS = 1.5     # 灯环扩散罩壁厚

# ─── 顶盖（浮岛结构）─────────────────────────────────────
TOP_CAP_DIAMETER = 92.0      # 顶盖直径
TOP_CAP_HEIGHT = 6.0         # 顶盖厚度
TOP_CAP_GAP = 0.6            # 顶盖与上壳缝隙（麦克风孔 + 灯光溢出）
TOP_CAP_FILLET = 4.0         # 顶盖边缘圆角

# ─── 底盖 ─────────────────────────────────────────────────
BASE_DIAMETER = 62.0         # 底部平面直径
BASE_HEIGHT = 3.0            # 底盖厚度
BASE_FILLET = 8.0            # 底部圆角

# ─── LED 灯环 ─────────────────────────────────────────────
LED_COUNT_MAIN = 16          # 主灯环 WS2812B 数量
LED_COUNT_HALO = 8           # 底部 Halo WS2812B 数量
LED_TOTAL = LED_COUNT_MAIN + LED_COUNT_HALO

# ─── 麦克风 ───────────────────────────────────────────────
MIC_COUNT = 4                # 4 麦阵列
MIC_SPACING = 42.0           # 麦克风间距
MIC_HOLE_DIAMETER = 1.0      # 麦克风孔径

# ─── 装配 ─────────────────────────────────────────────────
SCREW_TYPE = "M2x6"          # 螺丝规格
SCREW_COUNT = 4              # 螺丝数量
SCREW_HOLE_DIAMETER = 2.2    # 螺丝孔直径（M2 + 间隙）
SCREW_BOSS_DIAMETER = 5.0    # 螺丝柱直径

# ─── 内部空间 ─────────────────────────────────────────────
INTERNAL_TOP_H = 12.0        # 顶部空间（麦克风板）
INTERNAL_MID_H = 38.0        # 中部空间（主控 PCB）
INTERNAL_BOT_H = 36.0        # 底部空间（电池 + 扬声器）

# ─── PCB ──────────────────────────────────────────────────
PCB_DIAMETER = 55.0          # 55mm 圆形 PCB
PCB_THICKNESS = 1.6          # 4 层板厚度

# ─── 3D 打印参数 ──────────────────────────────────────────
PRINT_LAYER_HEIGHT = 0.2     # mm
PRINT_INFILL = 15            # %
PRINT_SHELL_MATERIAL = "PLA"
PRINT_RING_MATERIAL = "透明PETG"  # 灯环材料
