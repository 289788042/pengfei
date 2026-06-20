# 《错位时卡 / 错位时差》文档入口

更新时间：2026-06-20

这份文件是 docs 目录的入口索引。不要把所有文档合并成一个大文档；本项目需要保留“当前准则、执行计划、历史资产、开发记录、QA 记录”的层级，否则旧设定和新拍板会混在一起。

## 一句话规则

新对话或新开发阶段，先读本文件，再读：

1. `PROJECT_MEMORY.md`
2. `DEV_MEMORY.md`
3. 与当前任务直接相关的专题文档

如果文档之间冲突，以用户最近明确拍板的口径为准；落到文件层级时，`PROJECT_MEMORY.md` 和 `DEV_MEMORY.md` 优先于旧设计文档。

## 当前最高优先级文档

| 文档 | 状态 | 用途 |
| --- | --- | --- |
| `PROJECT_MEMORY.md` | 当前准则 | 游戏定位、策划口径、新手教程、恋爱系统、结局池、NPC 方向、用户偏好 |
| `DEV_MEMORY.md` | 当前准则 | 当前代码架构、最近重构、反复 BUG、MCP 验收方式、开发注意事项 |

这两份是“继续开发前必须读”的文件。后续新设计和新技术结论也优先更新这两份。

## 设计专题文档

| 文档 | 状态 | 用途 |
| --- | --- | --- |
| `design_reboot_workshop.md` | 近期设计会议纪要 | 从结局、恋爱、周节奏、前三月主线重启游戏设计，信息量最大 |
| `implementation_plan_first_three_months.md` | 近期执行计划 | 第一到第三月如何落地：林凡、阿强、陈默进入节奏 |
| `first_month_mainline_onboarding.md` | 近期执行计划 | 第一月新手教程和生存体验细案 |

这些文件用于做系统/剧情/节奏设计时参考。若它们和 `PROJECT_MEMORY.md` 冲突，以 `PROJECT_MEMORY.md` 的最新口径为准。

## 历史资产池

| 文档 | 状态 | 用途 |
| --- | --- | --- |
| `game_systems_design.md` | 历史资产 | 旧结局池、春节系统、NPC、债务、数值阈值等，很多东西不能丢 |
| `game_design_v2.md` | 历史资产 | 早期游戏定位、手机 App 框架、旧系统方向 |
| `开发文档.md` | 历史资产 / 旧技术说明 | 旧版技术架构、系统说明、死亡结局和数据结构 |
| `AI写作提示词模板.md` | 历史资产 / 写作参考 | 旧剧情生成提示词，含微信/NPC 文案风格要求 |

历史资产不是当前执行标准。它们用于打捞旧想法，例如金丝雀、回老家创业、春节系统、林凡旧线等。引用前必须判断是否已被新设计废弃或暂缓。

## 开发和 QA 记录

| 文档 | 状态 | 用途 |
| --- | --- | --- |
| `../CODEX_HANDOFF.md` | 开发历史记录 | 2026-06-16 到 2026-06-17 的系统修改、提交、MCP 验证 |
| `../QA_PLAYTEST_3_MONTHS.md` | QA 历史记录 | 三个月真实玩家式乱点测试、BUG、已修/未修问题 |

这些文件用于查“以前为什么这么改”“某个 BUG 是否出现过”“某个系统是否验证过”。不要把里面的旧设计自动当成最新方向。

## 按任务选择阅读路径

### 新对话 / 接手项目

1. `docs/README.md`
2. `docs/PROJECT_MEMORY.md`
3. `docs/DEV_MEMORY.md`
4. `git status --short`
5. 当前任务涉及的专题文档

### 做新手教程 / 第一月体验

1. `PROJECT_MEMORY.md`
2. `DEV_MEMORY.md`
3. `first_month_mainline_onboarding.md`
4. `design_reboot_workshop.md` 中第一月、周节奏、新手教程相关章节

### 做恋爱 / NPC / 结局系统

1. `PROJECT_MEMORY.md`
2. `design_reboot_workshop.md`
3. `implementation_plan_first_three_months.md`
4. `game_systems_design.md` 中结局和 NPC 历史资产

### 修 BUG / 改代码架构

1. `DEV_MEMORY.md`
2. `PROJECT_MEMORY.md` 中相关体验口径
3. `CODEX_HANDOFF.md`
4. `QA_PLAYTEST_3_MONTHS.md`
5. 相关脚本源码

### 做音频 / 场景切换 / UI 层级

1. `PROJECT_MEMORY.md` 中画面、音频、UI 层级口径
2. `DEV_MEMORY.md` 中相关 BUG 映射
3. `QA_PLAYTEST_3_MONTHS.md` 中地点/背景/层级问题
4. `scripts/EnvironmentController.gd`
5. `scripts/GalgameSystem.gd`
6. `scripts/LocationActionRunner.gd`

## 冲突处理规则

- 用户最近明确说过的话优先。
- `PROJECT_MEMORY.md` 和 `DEV_MEMORY.md` 优先于旧设计文档。
- 运行时代码不一定代表正确设计；可能只是旧实现还没改。
- 历史资产不能轻易删除，但必须标注为“历史资产 / 暂缓 / 废弃 / 候选”。
- 如果旧文档里有随机偶遇、地图大屏、开局 BOSS 等内容，按最新口径处理：这些当前不进入新手阶段。

## 维护规则

- 不把所有文档合并成一个大文件。
- 不随意改旧文档正文，除非明确做历史整理。
- 新拍板设计写进 `PROJECT_MEMORY.md`。
- 新代码结构、BUG 根因、MCP 验证写进 `DEV_MEMORY.md`。
- 如果一个阶段结束，先同步记忆，再考虑提交。
- 每次新增重要文档，都在本索引登记。
