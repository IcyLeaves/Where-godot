# Where（Godot 4.4）

网格策略向第一幕教学关原型：**白天**操控警长移动与调查，**夜晚**观看志愿者与扒手行动；商店购买志愿者、金币与物品、逮捕扒手与胜负结算。

## 运行

1. 使用 **Godot 4.4** 打开本目录（含 `project.godot`）。
2. 主场景：`res://scenes/Main.tscn`（已在项目设置中指定）。

运行所需角色图集位于 **`assets/sprites/where/`**。若本地仍有完整 `character-pack-full_version` 等目录，仅作备用素材，默认已被 `.gitignore` 排除。

## 仓库结构（简要）

| 路径 | 说明 |
|------|------|
| `scenes/` | 主场景等 |
| `scripts/` | `Main.gd`、数据与 UI 脚本（如 `map_animated_actor.gd`） |
| `assets/sprites/where/` | 本版本实际引用的 32×32 角色图集 |

## 版本记录

见 [CHANGELOG.md](CHANGELOG.md)。
