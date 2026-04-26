# 涌现系统：小球群集移动法则与参数速查表

本文档记录了《共识废墟》中"机器小球"底层的群集（Boids）运算逻辑，它是实现多实体分流、聚簇、冷寂等涌现效果的基石。

## 一、物理积分算法（每物理帧）

游戏摒弃了直接的硬编码寻路方案（如 NavigationAgent），转而采用模拟力的叠加：

```text
[1] 提取三种独立的受力向量（动态强度）
对齐力向 = 邻居速度的平均向量 * (平均时速 / 最大限速)  // 速度越低，互相传染的对齐力越小，能自然平息
排斥力向 = (自身坐标 - 邻居坐标) 的归一化方向 * (1 - 距离 / 40) // 动态反馈：越拥挤推力越剧烈
趋光力向 = (灯塔坐标 - 自身坐标) 的归一化方向 * (强度 / 距离的平方反比) // 距离平方倒数法则：多灯塔时永远被最近的塔主导引力

[2] 融合主加速度与位移积分
主加速度 = (对齐力向 * align_weight) + (排斥力向 * sep_weight) + (趋光力向 * light_weight)
当前速度 = (老速度 + 主加速度 * delta * 1000) * 阻尼衰减(damping)

[3] 引擎转态与静止锁死
- 防越限：如果速度超出 normal_max_speed，切断多余速度。
- 冷寂截断：如果微积分后速度小于 5.0，且处于无强加速度的状态（如所有灯塔皆暗），此时主动将速度置零（Vector2.ZERO），杜绝数学浮点数震荡导致的鬼畜漂移，实现群体随时间自然停下、彻底死寂的表现。
```

---

## 二、恐慌系统二相性（Phase 2: Panic Contagion）

小球存在一个内部核心情绪池 `panic` (范围 0.0 ~ 1.0)。该数值实时决定小球的行为模式：

### 1. 恐慌值增长（三条路径）

| 路径 | 触发条件 | 公式 | 涉及参数 |
| :--- | :--- | :--- | :--- |
| **深渊吞噬** | 距 Abyss < `abyss_distance` | `panic += abyss_fear_gain * delta` | `abyss_fear_gain` = 0.8, `abyss_distance` = 200.0 |
| **急转弯震荡** | `abs(Δangle / delta)` > `panic_angular_threshold` | `panic += panic_angular_gain * delta` | `panic_angular_threshold` = 1.2, `panic_angular_gain` = 0.2 |
| **传染扩散** | 邻居 `panic >= 0.5` 且自身 `panic < 0.5` 且距离 < `panic_spread_radius * robot_radius` | `panic += panic_spread_intensity * delta` | `panic_spread_radius` = 2.5, `panic_spread_intensity` = 0.3, `robot_radius` = 20.0 |

### 2. 恐慌值衰减（自然冷却）

```text
panic -= panic_decay * delta    // 每帧自然冷却，参数 panic_decay = 0.3
panic = clamp(panic, 0.0, 1.0)
```

> 所有小球都有 **自然冷却** 的底线自愈能力：只要不受到上述三种刺激，每秒扣除 `panic_decay` 寻找平静。

### 3. 二阶行为坍缩切换（阈值 0.5）

| 状态 | 加速度公式 | 限速 | 表现 |
| :--- | :--- | :--- | :--- |
| **正常** (`panic < 0.5`) | `acc = alignment * align_weight + separation * sep_weight + light * light_weight` | `normal_max_speed` = 300.0 | 黄色，接受灯塔引导，保持蜂群对齐 |
| **发疯** (`panic >= 0.5`) | `acc = separation * 0.3 + random_dir * panic_random_force` | `panic_max_speed` = 400.0 | 深红色，切断灯塔+对齐，布朗运动乱窜 |

> ⚠️ 发疯态的排斥力系数 `0.3` 目前硬编码在 `robot.gd` 第 46 行，未抽到 `game_params.gd`。如需调节建议提成 export 变量。

---

## 三、参数修改清单与意义解释

全游戏决定涌现手感的核心参数全被集中抽象为了全局单例。
> **去哪里修改这些参数？**
> 回到 Godot 编辑器，在底部「文件系统(FileSystem)」面板中双击点开 `res://scripts/game_params.gd` 脚本文件，你可以在顶部找到所有的 `@export var`。修改等号前后的数值并保存（Ctrl+S），甚至可以在游戏运行态中点击 Remote 层级树实时热更拖拽这些数值。

### 基础 Boids 参数

| 参数变量名 (`game_params.gd`) | 当前值 | 含义 | 调整时的表现影响 |
| :--- | :--- | :--- | :--- |
| `light_weight` | 1.0 | **灯塔主引力统御值** | 数值越高，小球对光塔目标越趋之若鹜。设为0将无视光源。 |
| `align_weight` | 0.5 | **蜂群对齐力/随流比重** | 调得太高（如1.0）会导致球群集体绕圈盘旋，进不去光塔；调太低则各自为营，没有蜂流感。 |
| `sep_weight` | 0.2 | **近距防粘排斥力** | 数值越低排列密度越高（挤成一坨），数值越高则群体队形散得很开。 |
| `robot_radius` | 20.0 | **小球物理视野半径** | 控制可视大小，同时也是排斥力和传染距离的基准。 |
| `damping` | 0.9 | **地面摩擦系数/系统阻尼** | 越低（如0.7）急刹车转弯利索；越高（如0.98）像冰面打滑。 |
| `normal_max_speed` | 300.0 | **安全巡航最高限速** | 无论推力多大，每秒也最多跑这么多像素。 |

### 恐慌专属参数

| 参数变量名 (`game_params.gd`) | 当前值 | 含义 | 调大效果 | 调小效果 |
| :--- | :--- | :--- | :--- | :--- |
| `abyss_fear_gain` | 0.8 | **深渊恐慌增速** | 靠近深渊秒慌 | 可以在深渊边缘磨蹭不慌 |
| `abyss_distance` | 200.0 | **深渊影响半径(px)** | 影响范围更大 | 需要贴脸才触发 |
| `panic_angular_threshold` | 1.2 | **急转弯恐慌阈值(rad/s)** | 转得更猛才会慌 | 小幅转弯就触发恐慌 |
| `panic_angular_gain` | 0.2 | **急转弯恐慌增量** | 急转弯贡献更多恐慌 | 急转弯几乎不影响恐慌 |
| `panic_decay` | 0.3 | **恐慌自然冷却速率** | 冷静得更快，恐慌短命 | 恐慌持续时间长 |
| `panic_spread_radius` | 2.5 | **传染距离倍率(×robot_radius)** | 传染距离更远，链式反应更猛 | 需要紧贴才传染 |
| `panic_spread_intensity` | 0.3 | **传染吸收强度** | 一碰就感染到高值 | 需要长时间接触才累积 |
| `panic_random_force` | 4.0 | **发疯布朗加速度** | 发疯乱窜幅度更大 | 发疯后动作温和 |
| `panic_max_speed` | 400.0 | **发疯态最高限速** | 发疯时跑得更快 | 发疯时速度接近正常 |
