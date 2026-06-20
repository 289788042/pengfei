# 《错位时卡 / 错位时差》开发记忆与技术交接

更新时间：2026-06-20

用途：记录最近开发过程、提交、MCP 验证、重构方向、反复出现的 BUG 和根因。后续开发前先读 `docs/README.md`，再读 `docs/PROJECT_MEMORY.md`，再读本文件。

## 1. 项目位置和基础环境

- 项目路径：`E:\pengfei`
- GitHub：`https://github.com/289788042/pengfei.git`
- 当前主分支之前已推送。
- Godot 可执行文件：`D:\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`
- Godot MCP Pro 可用。必要时先用 `tool_search` 查 Godot 工具，再用 `play_scene res://scenes/MainGame.tscn` 测试。
- CLI fallback：`node D:/godot-mcp-pro/server/build/cli.js ...`
- 之前 MCP 反复断，已删除 `C:\Users\MSI\.codex\config.toml` 中固定 `GODOT_MCP_PORT = "6505"`。
- 已添加 MCP watchdog：
  - `E:\pengfei\tools\Start-GodotMcpHttp.ps1`
  - `E:\pengfei\tools\Watch-GodotMcpHttp.ps1`
- Watchdog 提交：`d2cf1ce Add Godot MCP watchdog scripts`

## 2. 重要提交记忆

- `d1f29a5 Polish compact map app UI`
  - 高德地图从大屏回到小屏。
  - 变为小屏卡片式 UI，显示当前位置、精力/现金/花呗、地点消耗/收益/条件。
  - 整张地点卡可点击。
- `d2cf1ce Add Godot MCP watchdog scripts`
  - 增加 Godot MCP watchdog 脚本。
  - 移除固定端口配置，降低 MCP 断连概率。

## 3. 当前工作区状态提醒

最近工作区是脏的，包含正在进行的体验和架构重构。不要随手 reset 或 checkout。

已修改：

- `scenes/MainGame.gd`
- `scripts/AppPopupSystem.gd`
- `scripts/EnvironmentController.gd`
- `scripts/GalgameSystem.gd`
- `scripts/GameManager.gd`
- `scripts/UIStateManager.gd`
- `scripts/WeChatSystem.gd`

新增未跟踪：

- `Assets/Audio/`
- `scripts/LocationActionRunner.gd`
- `scripts/LocationActionRunner.gd.uid`
- `scripts/PhoneAppController.gd`
- `scripts/PhoneAppController.gd.uid`
- `scripts/TutorialDirector.gd`
- `scripts/TutorialDirector.gd.uid`
- `scripts/UIFocusManager.gd`
- `scripts/UIFocusManager.gd.uid`

用户目前没有要求提交这些改动。若要提交，先检查 diff、跑验证，再按主题拆 commit。

## 4. 最近一次架构重构目标

用户指出一直打小补丁会埋更大雷，要求切回主程序模式，把代码设计重构干净，顺着当前教程/体验思路往下做。

本轮重构目标：

- 把教程状态从 `MainGame.gd` 里抽出来，避免所有流程塞进主场景脚本。
- 把手机 App 打开/关闭/清层职责抽出来，解决支付宝、微信、地图互相叠屏后状态污染。
- 把 UI 焦点和对话层级变暗职责抽出来，解决“前景对话看不见”和“地图透明乱掉”。
- 把地点行动和背景 hold/release 抽出来，解决去地点、结算、返回、背景释放重复逻辑。
- 保留旧入口包装，降低一次性重构风险。

## 5. 新增脚本职责

### `scripts/TutorialDirector.gd`

负责第一月早期教程状态机。

当前应包含/承担：

- 第一周 App gate：支付宝 -> 地图 -> 加班 -> 微信 -> 地图海边 -> 公园/后续 -> 结束本周。
- 第二周地图新地点提示。
- 哪个 App 图标应该发光、点错 App 提示什么。
- 蓝色教程文本和右侧数值面板呼吸时机。
- 主 UI 操作仍通过 `MainGame` 调用，避免教程脚本直接知道所有节点细节。

### `scripts/PhoneAppController.gd`

负责手机 App 的打开、关闭、互斥和视觉状态恢复。

当前承担：

- `open_alipay()`
- `open_wechat()`
- `close_all_apps()`
- `reset_layer_visual_state()`
- 打开一个 App 前关闭旧 App 层。
- 清除手机暗化和对话焦点残留。
- 强制关闭 WeChat。
- 清空支付宝 callouts。

历史问题：玩家点两次支付宝、点微信、再点地图后，地图 UI 透明叠乱。根因是 App 层和暗化/焦点状态没有统一清理，PhoneAppController 是为此拆出的。

### `scripts/UIFocusManager.gd`

负责 UI 焦点、底层变暗、恢复，以及对话遮罩清理。

当前承担：

- `set_dialog_focus_active()`
- 以 RGB 亮度压暗背景 UI，但保持 alpha 不变。
- `hide_phone_dim_overlay()`
- `force_clear_dialog_overlay()`

关键修复：之前对话焦点把底层 UI alpha 降到 0.34，导致地图/手机 App 自身透明，玩家多次切 App 后整个地图 UI 乱套。现在应只改 RGB 亮度，不改 alpha。

### `scripts/LocationActionRunner.gd`

负责地点行动生命周期。

当前承担：

- location event hold/release。
- location background switching。
- 地点背景路径选择，包括 gym 雨天和 beach/park。
- 行动开始、结算、返回主界面的协调。

注意：`AppPopupSystem` 中旧的 `_location_event_hold_count` 仍可能被 `GalgameSystem` 读取，因此目前有兼容镜像，不要贸然删。

## 6. 重要现有脚本职责

### `scenes/MainGame.gd`

主场景总装配。现在应逐步瘦身，仅保留：

- 节点引用。
- 系统初始化。
- UI 事件包装。
- 老接口兼容包装。
- 对 TutorialDirector / PhoneAppController / UIFocusManager / LocationActionRunner 的代理调用。

### `scripts/AppPopupSystem.gd`

App 弹窗、地图、地点、日记、购物、BOSS 等大量 UI 和系统入口仍集中在这里，是最大历史包袱之一。

近期改动：

- `_close_all_menus()` 委托给 `phone_apps`。
- location begin/end/background 委托给 `LocationActionRunner`。
- 保留兼容变量，避免 GalgameSystem 旧读取断掉。

风险：这个脚本仍大，未来应继续按 App 拆系统，但不要一次性全拆。

### `scripts/GalgameSystem.gd`

分页对话、飘字、消息提示、galgame 选择、手机暗化、地点背景 hold/release、音频/环境过渡相关。

历史重点：

- 曾增加 `_phone_dim_tween`，show/hide 互相 kill，修复 Ctrl 跳过地点剧情后旧 hide tween 把新结算遮罩关掉。
- 曾增加 `force_clear_dialog()`，用于月末账单、Game Over、结局入口清旧对白和手机暗化层。
- 选择阶段不能被 Ctrl/空格当普通对话跳掉。

### `scripts/UIStateManager.gd`

全局 UI 阻塞/恢复。对话、选择、弹窗时禁用右侧手机和结束本周。

近期重要修复：

- 新增/使用 `clear_stored_disabled(root)`。
- `_reset_weekday_choice_buttons()` 清除 weekday panel 的 stored disabled，修复提前结束本周后饮食标准按钮灰掉不能选。

### `scripts/WeChatSystem.gd`

微信系统。当前只作为通讯、基础关系地基保留，剧情后面可能重做。

近期修复：

- 聊天页右键/返回应回上一级，不直接关闭微信。
- 只有微信主菜单右键才关闭微信。
- 键盘返回和鼠标返回都应触发教程完成，不再只认鼠标点返回。

### `scripts/EnvironmentController.gd`

主场景和地点背景切换。

近期修复：

- 同一个 home 场景中点支付宝/地图不应触发背景渐隐渐出。通过 `_current_visual_key` 或等价逻辑避免同场景重播 fade。
- 海边背景切换太突兀，fade overlay 目标 alpha 从 0.72 调到 1.0，让切换时能完全盖住旧画面。

### `scripts/GameManager.gd`

核心数据、App 解锁、周/月推进、属性和经济。

近期修复：

- BOSS 弯聘早期隐藏。`_app_unlock_turn["job"]` 从 5 改到 8，避免和日记同时出来。
- 日记仍可在较早时机作为复盘工具出现，但也需要介绍。

## 7. 已修或正在修的关键 BUG 记忆

### 7.1 对话框右侧小箭头飞出天际

用户最早指出：galgame 对话框右侧浮动向下小箭头会随着对话变多慢慢往上跑，不管就飞出天际。

结论：箭头位置必须相对对话框固定，而不是被文本高度/滚动/分页累积偏移影响。

### 7.2 支付宝压住对话框

用户截图显示：支付宝大屏盖在对话框上，底部系统提示几乎看不见。

设计口径：

- 如果 App 和对话不可避免同时出现，App 或中间层亮度压低，最前面对话必须清楚。
- 对话点掉后，第二层 UI 再恢复亮度。

### 7.3 支付宝 icon 呼吸太弱/太强

过程：

- 用户先嫌图标亮得黄不拉几，看不出来亮。
- 后来嫌动画太过，放大太大，最亮时“支服了宝”四个字看不见。

当前口径：

- 呼吸要明显但克制。
- 亮度和外发光可以有，但不能洗掉文字。
- 缩放幅度小，避免图标在手机桌面乱跳。

### 7.4 Alipay 教程提示遮挡

用户指出总览和花呗提示放右侧挡住现金余额，要求放左侧。

口径：

- 左边 TAB 旁边小对话框解释功能。
- 文字要换行。
- 不能为了省事把框拉到最左边。

### 7.5 加班两次后 App 都点不动

用户曾连续加班两次后，高德地图和任何 App 都点不动。排查方向与 UIStateManager 阻塞层、galgame 选择/结算未释放、地点 hold 未 release 有关。

后来多次修了：

- `GalgameSystem` 选择阶段不再误跳。
- 地点事件结束必须 release hold。
- `UIStateManager` 统一判断是否恢复按钮。
- `ActionService.spend_weekend_action()` 只记录，不再真正消耗行动次数。

### 7.6 微信教程完成只认鼠标点返回

问题：微信点开后，只有鼠标点返回才能下一步；键盘返回/右键不算，微信图标一直闪烁。

修复口径：

- 所有返回路径都必须调用同一个教程完成回调。
- 微信聊天页右键回上一级，不直接关闭。

### 7.7 酒吧请女生喝酒卡住

用户反馈：去酒吧遇到女生，请她一杯酒聊摄影，选择请她后没然后，不能返回家，卡住。

根因方向：

- 地点碎片事件的选择结果缺少收尾回调。
- 需要保证任何地点选项都最终进入结算/返回/释放 hold。

### 7.8 周套餐选择和对话框冲撞

用户截图显示每周选套餐界面和 galgame 对话框冲撞。

设计口径：

- 有重要剧情时，先别让玩家选。
- P5 也是遇到重要事件就不进入自由选择。
- 或者选完再触发剧情，但不能两个 UI 同时压。

### 7.9 第一次遇到陈默和套餐选择冲撞

同上。重要事件要独立调度，不能和工作日套餐面板抢层级。

### 7.10 点支付宝后同场景突然暗一下再亮

用户反馈：新手教程点完支付宝，下一步点高德前，如果再点支付宝，左边家里场景突然暗一下再亮。同一场景内开 App 不应触发环境 fade。

修复方向：

- EnvironmentController 用当前视觉 key 判断，如果背景没变，不执行 fade。
- App 打开关闭只影响 UI 层，不触发场景切换。

### 7.11 地图 UI 透明乱掉

用户截图：点两次支付宝、点微信、再点高德后，地图 UI 整体透明叠在手机桌面上，文字和状态乱成一团。

根因：

- 对话焦点/手机暗化/弹窗层互相污染。
- 旧 dim 逻辑改了 alpha，导致实际 UI 节点半透明。
- 打开地图没有彻底重置上一层 App 的 modulate/self_modulate、遮罩和 disabled 状态。

修复：

- UIFocusManager 改为 RGB dim，保持 alpha。
- PhoneAppController 打开 App 前关闭旧层和清理 dim。
- 地图打开时重置 location menu 视觉状态。

验证点：

- Alipay -> WeChat -> Map 后，只应有 Map 可见，alpha = 1，没有 phone dim 残留。

### 7.12 第一周海边回来不知道干嘛

用户反馈：海边回来不知道干嘛。应继续教玩家“结束本周”。

修复口径：

- park/beach route 应触发 first week location callback。
- after beach 返回后，教程提示点击结束本周。
- next week button 脉冲提示。

### 7.13 第二周周末无指示

用户反馈：第二周周末没有任何指示，不知道干嘛。

修复口径：

- 第二周周末提示地图有新地点解锁了，可以打开看看。
- 地图 icon 发光直到点击。

### 7.14 提前结束本周后饮食标准灰掉

用户多次反馈：行动没用完提前结束，本周饮食标准灰色，不让选，卡死。

修复：

- `UIStateManager.clear_stored_disabled(root)`。
- `_reset_weekday_choice_buttons()` 清 stored disabled。
- 新周工作日面板显示前，必须重置套餐按钮和工作按钮。

### 7.15 海边背景突兀

用户反馈：去海边时家里渐隐渐出，但海边背景一下跳出来；图书馆不会。

修复方向：

- fade overlay 盖满到 alpha 1.0 再切背景。
- 海边流程不要绕过 EnvironmentController 正常切换。

### 7.16 日记和 BOSS 同时解锁

用户反馈：日记 App 出来时 BOSS 也同时出来，没有介绍，不对。

修复：

- BOSS/job 解锁推后到 turn 8。
- 后续仍需给每个新 App 单独介绍和高亮入场。

## 8. 最近完成的功能/修复摘要

- 修复地图透明/叠乱：dim 不再改 alpha。
- 修复地图打开前清理 phone focus overlay、phone dim、location menu modulate/self_modulate。
- 修复同一个 home 背景重复 fade。
- 修复第一周海边后继续引导结束本周。
- 修复第二周周末提示地图新地点。
- 修复提前结束本周后餐饮按钮灰掉。
- 修复海边背景切换突兀的一部分。
- 推迟 BOSS 解锁，避免日记和 BOSS 同时出现。
- 接入/整理音频相关：Rain、Beach、Restaurant、Office；开场 home 应该有 rain；gym 雨天应配 `rain_on_window`。
- 重构出 TutorialDirector / PhoneAppController / UIFocusManager / LocationActionRunner。

## 9. 最近 MCP 验证记忆

推荐验证方式：

1. `play_scene res://scenes/MainGame.tscn`
2. 用 `execute_game_script` 切到周末/指定教程状态。
3. `click_button_by_text` 打开 App。
4. `get_game_screenshot` 看图。
5. 对 UI 节点执行脚本检查 alpha、visible、disabled、hold_count。
6. 结束用 `stop_scene`。

最近验证过：

- 所有新脚本 validate 通过。
- UI dim：原始 `(1,1,1,1)`，对话焦点中 `(0.46,0.46,0.46,1)`，恢复后 `(1,1,1,1)`。
- location hold 开始为 1，结束为 0，phase 回 weekend。
- Alipay -> WeChat -> Map 后只有 Map 可见，alpha=1，没有 phone dim。
- Godot runtime 无明显错误。
- `git diff --check` 只出现 CRLF 规范化警告。

## 10. 代码设计风险和后续重构方向

### 10.1 MainGame 仍太重

虽然已经抽出四个脚本，但 `MainGame.gd` 仍有大量 UI 包装和旧状态。后续继续把具体流程下沉到系统脚本。

### 10.2 AppPopupSystem 仍是巨型系统

它仍承担地图、购物、日记、BOSS、地点等太多东西。后续应按 App 拆，但要小步走：

- MapAppController
- DiaryAppController
- JobAppController
- ShopAppController
- LocationActionRunner 已经是第一刀。

### 10.3 UI 层级必须统一

所有 UI 打开前都要走统一入口：

- 关闭互斥 App。
- 清理旧 dim。
- 确认底层禁用状态。
- 设置 z_index。
- 设置 mouse_filter。
- 关闭时恢复。

禁止每个 App 自己偷偷改可见性和 alpha。

### 10.4 教程状态要数据化

TutorialDirector 现在是第一刀，后续最好把教程 step 做成表/枚举：

- 当前目标。
- 允许 App。
- 高亮目标。
- 点错提示。
- 完成条件。
- 完成回调。

这样不会每加一个新手步骤就在 MainGame 里补 if。

### 10.5 地点事件必须统一收尾

任何地点事件，无论：

- 普通结算
- 选项结算
- 邂逅加微信
- 拒绝
- 条件不足
- Ctrl 跳过
- 返回按钮

都必须最终：

- release location hold。
- 恢复背景。
- 记录日记/支付宝流水。
- 恢复 UIStateManager。
- 清理 phone dim。
- 告诉 TutorialDirector 是否完成目标。

## 11. 待开发优先级

当前用户已经要求从小补丁切到更干净架构，但也明确当前优先级是体验和基础系统。

建议顺序：

1. 把 `PROJECT_MEMORY.md` 和本文件补齐，并在后续每个阶段更新。
2. 完成并验证新手教程第一周：支付宝 -> 地图加班 -> 微信 -> 海边 -> 结束本周。
3. 完成第二周提示和新地点渐进开放。
4. 把主日程/周末时间约束设计落地，解决无限肝。
5. 清理早期随机男 NPC 入口，确保沈逸/健身房搭讪不打断教程。
6. 做第一月到第三月主线纵切：林凡擦肩、阿强家庭伏笔、陈默客户饭局。
7. 再开始陈默第一年/金丝雀状态的系统原型。

## 12. 不要忘的具体 UI/文案细节

- 支付宝是“支服了宝”，但用户会写“支付宝”，UI 内目前也有梗化名字。
- 花呗初始欠款应与台词一致，约 2876.32。
- 债务数字要加粗偏黄/醒目。
- 支付宝早期隐藏复杂财务模块。
- 支付宝提示框放左侧并换行。
- 左侧 tab：总览、账单、花呗、理财；理财锁；删除关于。
- 地图不写“可前往/去”；亮/灰/锁表达状态。
- 地图不使用“练/园”这种单字低质标签。
- 公司加班第一周置顶，宅家刷手机锁。
- 加班卡片教程时呼吸发光。
- 微信右键在聊天页返回上级，不关闭。
- 家人关心事件情绪 +8 必须出现。
- 夜校老师要推课程。
- “结束本周”按钮不要跟月末多少钱混写，玩家可去账单看。
- 有重要剧情时不要弹饮食/工作套餐面板。
- 场景切换必须视觉和音频一起淡入淡出。
- 如果 App/对话/菜单叠层不可避免，最前层对话最亮，后层压暗。

## 13. 老资产和旧系统不要误删

虽然早期随机男 NPC 暂缓，但以下资产不是废弃，只是暂不前置：

- 沈逸：后期文化/精神需求/文艺陷阱。
- 许子轩、林远等旧随机角色：可作为后续地点随机池，但不进新手。
- 春节 BOSS 战：旧系统里很重要，可后面与家庭/婚恋/年龄压力结合。
- 回老家创业：隐藏结局资产，必须保留。
- 金丝雀：核心婚恋结局资产，必须保留并重做得更复杂。
- 林凡旧线：旧代码/历史可能有春节、彩礼、厨房背影等内容，后续可从 git 历史打捞。

## 14. 验收清单

每次提交前至少做：

- `git status --short`
- Godot validate 改过的 GDScript。
- 运行 MainGame。
- 截图验证关键 UI。
- 乱点顺序验证：支付宝重复点、微信、地图、返回、右键、结束本周。
- 看 Output/Editor errors。
- 如改教程，完整跑第一周。
- 如改地点，确认 hold release 为 0。
- 如改场景，确认 fade 和音频同步。
- 如改按钮状态，跨周验证工作日套餐不灰。

## 15. 记忆更新执行规则

以后我使用这两份记忆文件时，必须遵守以下流程：

1. 开发前读取：
   - 先读 `docs/README.md`，确认文档主次和冲突规则。
   - 再读 `docs/PROJECT_MEMORY.md`，确认当前策划口径。
   - 最后读 `docs/DEV_MEMORY.md`，确认代码架构、历史 BUG 和验收清单。
   - 如果工作涉及前三月主线，再读 `docs/design_reboot_workshop.md` 和 `docs/implementation_plan_first_three_months.md`。

2. 开发中判断是否需要更新：
   - 如果只是临时试验，不写入长期记忆。
   - 如果用户拍板、代码落地、BUG 根因确认、架构职责改变，就必须写入。
   - 如果用户纠正了台词、UI 顺序、按钮状态、系统限制，这也算长期记忆。

3. 开发后同步：
   - 设计结论写进 `PROJECT_MEMORY.md`。
   - 代码结构、文件职责、修复根因、MCP 验证写进 `DEV_MEMORY.md`。
   - 同一件事如果既影响设计又影响代码，两边都写，但角度不同。

4. 提交前检查：
   - 如果本次 commit 改变了新手流程、系统架构、结局/NPC 设定，检查记忆文档是否同步。
   - 如果用户要求推送 GitHub，推送前至少确认记忆文档没有漏掉本阶段关键口径。

5. 冲突处理：
   - 新口径覆盖旧口径，但不要删除旧资产。
   - 写清“废弃/暂缓/历史资产/待验证”。
   - 如果旧代码仍实现了废弃口径，要在待修风险里标出。

## 16. 对话到开发动作的细节映射

这一节把用户反馈和已经做过/应该做的开发动作对应起来，避免以后只记得“修过”，忘了为什么修。

### 16.1 对话箭头 BUG

用户原话含义：对话框右侧浮动向下小箭头随着对话变多慢慢往上跑，最后飞出天际。

开发含义：

- 箭头节点位置必须依附对话框固定锚点。
- 不应基于文本高度累计偏移。
- 每次显示新页时应重置箭头位置和 tween。
- 若对话框大小变化，箭头按容器尺寸重新定位，而不是沿用上次位置。

### 16.2 手机亮起和 App gate

用户要求：

- 对话说完“先打开支付宝，再打开高德地图”后，手机亮起，可以操作。
- 只允许支付宝，其他 App 被拦截并弹提示。
- 支付宝关闭后才允许地图。

开发含义：

- TutorialDirector 应维护 `allowed_app` 或等价状态。
- PhoneAppController 打开 App 前先问 TutorialDirector 是否允许。
- 点错 App 不应静默无效，要通过 GalgameSystem 显示提示。
- 手机主屏亮度/disabled 状态不能由多个脚本分别恢复，必须由 UIStateManager + TutorialDirector 协调。

### 16.3 支付宝 callout

用户要求：

- 小提示框解释总览、账单、花呗。
- 理财锁定。
- 删除关于。
- 文字放左侧，不挡主要数字。
- 字号放大，早期复杂财务模块隐藏。

开发含义：

- Alipay UI 初始教学态应有简化布局。
- callout 位置不能硬挡内容，需要以 tab 区域/左侧空白为参考。
- 如果后续进入非教学态，可逐步恢复更多财务模块。
- 账单和花呗页即使锁部分功能，也要解释“以后这里做什么”。

### 16.4 高德地图早期锁点

用户要求：

- 公司加班打开并置顶。
- 宅家刷手机锁。
- 海边在微信后解锁。
- 加班后加班锁住，只能去海边。
- 第二周再提示新地点。

开发含义：

- Map location availability 不能只看 GameManager 全局地点表，还要叠加 TutorialDirector 的阶段限制。
- 地点卡需要 `tutorial_highlight` 状态，用于呼吸发光。
- 锁定地点不显示“去/可前往”，只显示灰态/锁/开放条件。
- 不要用单字标签。

### 16.5 微信第一周教学

用户要求：

- 第一次加班后微信亮。
- 点其他 App 提示先看看微信。
- 微信内自由探索。
- 家庭群事件必须出现，情绪 +8。
- 夜校老师推课程。
- 所有返回方式都能完成教程。
- 聊天页右键回上一级，主菜单右键才关闭。

开发含义：

- WeChatSystem 的 back 行为必须分层：chat -> list/home -> close。
- TutorialDirector 不能只监听按钮 click，应监听统一的 `wechat_closed_or_explored` 事件。
- 家庭群事件应有一次性 flag，避免重复刷情绪。
- 老师消息应作为课程系统伏笔，不要现在做完整夜校系统也能出现。

### 16.6 蓝色教程和右侧属性面板

用户要求：

- 先说加班回来精神紧绷、疲惫、emo。
- 再出蓝色教程。
- 蓝字讲情绪值、严重后果、心理健康、右侧属性面板。
- 说到“手机里正在发光的那个框框就是”时，属性面板开始呼吸。
- 蓝字没点完时一直呼吸，点完再停。
- 然后才说去海边散心。

开发含义：

- GalgameSystem 需要支持教程文本颜色/样式，或 TutorialDirector 用专门页面类型。
- Stats panel glow 的开始点要绑定到具体教程页索引，而不是提前触发。
- Glow stop 绑定教程页结束回调。
- 地图 App glow 应在蓝字全部结束后再启动。

### 16.7 饮食/套餐面板冲撞

用户截图 7/8 指出：

- 套餐选择面板和对话框冲撞。
- 陈默首次事件也撞套餐选择。
- 重要剧情时不应该让玩家选，或者选完再触发剧情。

开发含义：

- Weekday planning panel 和 story event 之间需要调度队列。
- 进入重要剧情前，隐藏/禁用套餐面板。
- 剧情结束后再恢复套餐选择，或本周自动占用日程。
- 不能让两个“主交互层”同时可见。

### 16.8 地图透明乱套

用户明确复现路径：

- 新手教程点完支付宝后到地图阶段。
- 再点支付宝，左边家里场景会突然暗一下再亮。
- 点两次支付宝、点微信、再点高德，地图 UI 就乱。

开发含义：

- 同场景 App 开关不能调用 EnvironmentController fade。
- App 打开前必须清理上一个 App 的 visible、modulate、self_modulate、mouse_filter、z_index 和 dim overlay。
- Dialog focus 只改 RGB，不改 alpha。
- Map open 必须重建/刷新 UI 状态，而不是复用被压暗过的节点。

### 16.9 海边/地点切换

用户要求：

- 去地点切换场景时视觉 fade 和音频 fade 同步。
- 海边背景不能突然跳。
- 图书馆正常，说明海边路径可能绕过统一流程。

开发含义：

- 所有地点背景切换统一走 LocationActionRunner + EnvironmentController。
- fade 到全黑/足够遮盖后再切 texture。
- 音频 crossfade 和视觉 fade 用同一生命周期。
- 地点结束后 release hold，再回 home。

### 16.10 周末提前结束和按钮灰掉

用户多次反馈：

- 行动次数没用完提前结束，本周饮食标准灰掉，卡死。
- 这不是第一次出现。

开发含义：

- UIStateManager 存储 disabled 状态时，跨周必须清理。
- 新工作日面板打开前要强制 reset 按钮 disabled。
- 不要把“上一层剧情禁用状态”恢复到新一周按钮上。

### 16.11 日记和 BOSS 同时解锁

用户反馈：

- 日记 App 出现时 BOSS 也同时出现，没有介绍。

开发含义：

- App unlock 不能只按 turn number 自动一起出现。
- 每个新 App 应有 introduction event / highlight。
- BOSS unlock 后移；前三月不急。
- 日记作为复盘工具也需要自然介绍。

### 16.12 音频

用户要求：

- Home 开场有雨声。
- Rain、Beach、Restaurant、Office 背景音接入。
- 健身房雨天背景使用 `rain_on_window`。
- 视觉和音频都渐隐渐出。

开发含义：

- EnvironmentController 或单独 AudioEnvironmentController 应按 location/weather 管环境音。
- Home/rain 应在开局初始化，不等玩家切场景。
- Gym weather 判定要传给音频。
- 不同场景音频切换要 crossfade，避免突兀。

## 17. 近期重构后的待验证事项

这些是下一次继续开发前应优先跑的，不要直接开始新功能。

- 完整跑第一周：开场 -> 支付宝 -> 关闭 -> 地图 -> 加班 -> 微信 -> 家庭事件 -> 蓝色教程 -> 海边 -> 结束本周。
- 用错误顺序乱点：支付宝重复点、微信、地图、右键、返回、关闭按钮，确认 UI 不透明乱套。
- 第二周开始：确认饮食标准按钮不灰，确认地图新地点提示出现。
- 去海边：确认视觉 fade 完整，音频切换不突兀。
- 微信：聊天页右键回上一级，主菜单右键关闭。
- UI 层级：有对话时 App 降亮，对话最清楚。
- BOSS：确认开局和日记解锁时不同时冒出来。
- 日记：确认解锁/介绍不会打断主教程。

## 18. 以后提交信息建议

如果下一次提交当前重构和记忆文档，可以考虑拆成两类：

- 代码重构提交：例如 `Refactor tutorial and phone UI flow controllers`
- 记忆文档提交：例如 `Document project memory and recent flow decisions`

如果用户要求先看效果，可以先不提交文档；但如果代码已经提交，文档也应尽快提交，否则下次上下文丢失会再次回到靠聊天记忆。

## 19. 2026-06-20 追加：第一周微信必读家人群

发现问题：玩家在第一周加班后打开微信，如果直接点返回，会跳过“相亲相爱一家人”关心消息和情绪 +8，直接解锁海边。这不符合用户明确要求的“家人群事件必须出现，也是新手教程必须有的东西”。

修复口径：
- 初始家人群关心消息增加 `mainline_flag = "first_week_family_support_seen"`。
- `WeChatSystem._show_family_chat_display()` 在玩家点“知道了”并完成结算后写入该主线 flag。
- `TutorialDirector.on_wechat_closed()` 只有检测到该 flag 后，才允许进入蓝色数值教程和海边解锁。
- 若玩家没读家人群就关闭微信，微信保持教程 gate，继续高亮微信，并提示“先看看‘相亲相爱一家人’的消息吧。家里人都在等你报平安。”
- `should_finish_first_week_wechat_on_back()` 也必须等待该 flag，避免玩家从其他聊天页返回时自动关闭微信并跳过家人群。

验证结果：
- 逃课路径：打开微信后直接关闭，`gate=wechat`，`beach_unlocked=false`，`first_week_family_support_seen=false`。
- 正常路径：读家人群并确认结算后，flag 写入；再关闭微信才进入数值教程并解锁海边。

## 20. 2026-06-20 追加：第一周结束本周按钮锁定

发现问题：第一周刚进入周末时，“结束本周”按钮显示为可点状态。实际点击不会跳周，但玩家看到亮按钮、点了又没反应，会误以为游戏卡住。

修复口径：
- `TutorialDirector.should_lock_end_week_button()`：第一周海边回来的收尾提示出现前，锁住结束本周。
- `MainGame._update_weekend_ui()`、`_enter_weekend()`、`_repair_next_week_button_state()` 都必须尊重该锁定状态，不能再无条件 `disabled=false`。
- 海边回来后，`TutorialDirector.should_pulse_end_week_button()` 让“结束本周”按钮持续呼吸发光，直到玩家点击。
- `refresh_first_week_app_focus()` 在无 app gate 时不能误停这个结束本周按钮的呼吸焦点。

验证结果：
- 第一周刚进入周末：`lock=true`，`Btn_NextWeek.disabled=true`，画面上按钮灰掉。
- 海边提示点完后：`lock=false`，`Btn_NextWeek.disabled=false`，`_phone_focus_button == Btn_NextWeek`，实际画面按钮亮起并有光效。

## 21. 2026-06-20 追加：WeekFlowController / MapAppController 架构拆分

用户明确要求回到主程序模式，继续清架构，不要一直打体验小补丁。本轮重构目标是把周流程和地图入口从巨型脚本里继续拆出去，同时保持旧入口不破坏其他系统调用。

新增脚本：
- `scripts/WeekFlowController.gd`
  - 接管 `_enter_weekday`、`_begin_weekday_flow`、`_show_weekday_planning_panel`、`_reset_weekday_choice_buttons`、`_maybe_trigger_weekday_story_event`。
  - 接管 `_enter_weekend`、`_update_weekend_ui`、`_on_pay_rent`、`_on_btn_next_week`、周末确认弹窗、`_proceed_next_week`。
  - `MainGame.gd` 保留同名薄包装，避免旧系统直接调用断掉。
- `scripts/MapAppController.gd`
  - 作为高德地图唯一入口，负责打开地图前的可用性判断、解锁判断、清焦点、关闭旧菜单、恢复小屏手机层、调用旧地图渲染层。
  - 地点卡点击改为先进入 `MapAppController.start_location()`，再转发旧地点生命周期。旧 `_start_location` 暂时保留在 `AppPopupSystem.gd`，等下一轮拆 Location/Map 细节时再继续瘦身。

当前边界：
- `MainGame.gd` 的周流程已经明显变薄，但月末账单计算、主线触发函数本体仍在 MainGame。
- `AppPopupSystem.gd` 的地图纯 UI 构建函数仍在旧文件中，`MapAppController` 目前先收入口和点击路径，后续可继续把 `_render_map_menu`、`_map_location_order`、`_add_small_map_location_button` 等纯地图 UI 函数迁出。

验证结果：
- 脚本编译：`MainGame.gd`、`WeekFlowController.gd`、`AppPopupSystem.gd`、`MapAppController.gd` 均通过。
- 干净开局推进到第一周周末：`week_flow=true`，`gate=alipay`，结束本周仍被教程锁住。
- 地图打开：`map_visible=true`，地图节点有内容，`_map_app` 实例存在。
- 地点卡启动：点击公司加班卡后地图关闭、进入加班地点剧情、日程写入 `周六:公司加班 | 周日:空闲`。
- 地点结算：点掉结算后 `money` 增加、`energy=60`、`sanity=65`、教程 gate 切到 `wechat`，地点 hold 释放为 0。
- 周推进：调用 `_proceed_next_week()` 后进入第 2 周工作日，`phase=WEEKDAY`，`month=1`，`week=2`，`turn=2`。

## 22. 2026-06-20 追加：MapAppController 接管地图 UI 渲染

本轮继续执行用户要求的“别一直打小补丁，先把架构收干净”。在上一轮 `MapAppController` 只接管地图打开入口和地点点击入口之后，这一轮把高德地图小屏 UI 的专属渲染逻辑也迁出 `AppPopupSystem.gd`。

迁移内容：
- `scripts/MapAppController.gd`
  - 接管 `render_map_menu()`，负责高德地图小屏整体 UI 构建。
  - 接管地点排序、路线摘要、状态指标 chip、地点卡片构建、地点锁定/可去状态、教程高亮地点卡呼吸、收益/消耗/条件文案、第一月地点开放节奏。
  - 保留地点执行委托：点击地点卡后仍调用 `AppPopupSystem._start_location()`，地点生命周期、支付、碎片事件、NPC 重逢、背景 hold/release 仍暂时归旧地点系统。
  - 渲染前清理旧 child 时改为 `remove_child()` 后 `queue_free()`，修掉同一帧重复打开地图时旧 child 还没释放导致的地图叠层风险。
- `scripts/AppPopupSystem.gd`
  - 删除原先 700 行左右地图 UI 专属 helper。
  - `_render_map_menu()` 只保留兼容薄壳，转发给 `MapAppController.render_map_menu()`。
  - 保留 `_restore_map_to_phone_layer()`、`_clear_phone_focus_overlays()`、`_reset_layer_visual_state()`、`_close_all_menus()` 等跨 App 层级工具。
  - 地点执行中第一周加班/海边教程路由改为调用 `MainGame.is_first_week_beach_route_unlocked()`，不再依赖已移走的地图 helper。

当前边界：
- 地图 App 现在归 `MapAppController`，以后改地图 UI、地点卡、地点开放节奏，优先改这个文件。
- 地点行动生命周期仍在 `AppPopupSystem.gd`，下一步如果继续重构，应考虑把地点配置、地点执行、支付后结算、碎片事件、NPC 重逢进一步拆成 `LocationActionController` 或继续增强 `LocationActionRunner`。

验证结果：
- Godot 编译：`MapAppController.gd`、`AppPopupSystem.gd`、`MainGame.gd`、`WeekFlowController.gd` 均通过。
- 直接调用 `MapAppController.render_map_menu()`：`visible=true`，`children=1`，`cards=8`，`modulate=(1,1,1,1)`。
- 连续两次调用 `MapAppController.open_map()`：`first=true`、`second=true`，仍保持 `children=1`、`cards=8`，无地图叠层。
- 调用 `MapAppController.start_location("overtime")`：地图关闭，日程写入 `周六:公司加班 | 周日:空闲`，地点 hold=1，阻塞对话出现。
- 旧入口 `AppPopupSystem._on_app_map()`：仍能打开地图，`visible=true`，`children=1`，`cards=8`，说明 `MainGame` 旧调用链未断。
- Godot editor errors 最终为 0。

## 23. 2026-06-20 追加：LocationActionRunner 接管地点行动生命周期

本轮继续执行“架构优先，不再堆小补丁”。上一轮地图 UI 已归 `MapAppController`，这一轮把地点行动的主要生命周期从 `AppPopupSystem.gd` 迁到 `LocationActionRunner.gd`。

迁移内容：
- `scripts/LocationActionRunner.gd`
  - 接管地点配置 `location_config()`：图书馆、健身房、酒吧、宅家、公园、咖啡厅、夜市、公司加班。
  - 接管地点开始 `start_location()`、可前往判断 `can_start_location()`、支付后继续 `run_location_after_payment()`。
  - 接管地点背景/环境音切换、地点 hold/release、结束后回到周末。
  - 接管每周地点访问计数、重复行动收益衰减、深圳湾每周一次限制。
  - 接管地点结果文本、地点活动日志记录、第一周加班/海边教程回调路由。
  - 保持对 `AppPopupSystem` 的委托：城市碎片展示、碎片选项 UI、NPC 邂逅/重逢具体演出、数值应用仍暂时由旧系统处理。
- `scripts/AppPopupSystem.gd`
  - `_start_location()`、`_run_location_after_payment()`、`_can_start_location()`、`_location_config()` 等变成兼容薄壳，转发到 `LocationActionRunner`。
  - `_finish_location_event_after()` 优先使用 `LocationActionRunner.finish_after()`，避免 hold/release 收尾双写。
  - 删除旧的地点配置大块、地点开始/支付后继续大块、每周访问状态大块。
- `scripts/MapAppController.gd`
  - “本周是否已去深圳湾”不再读 `AppPopupSystem._park_visited_week` 旧变量，改为通过 `AppPopupSystem._is_once_per_week_location_visited()` 间接查询 runner。

当前边界：
- 地点“编排/生命周期”归 `LocationActionRunner`。
- 城市碎片、碎片选项、NPC 邂逅/重逢演出仍在 `AppPopupSystem`，这是下一轮继续拆的重点。
- `AppPopupSystem` 仍保留地点相关兼容薄壳，因为旧 UI 按钮、MapAppController、碎片/NPC 逻辑还会调用这些旧入口。

验证结果：
- Godot 编译：`LocationActionRunner.gd`、`AppPopupSystem.gd`、`MapAppController.gd`、`MainGame.gd`、`WeekFlowController.gd` 均通过。
- 运行态确认：`app=true`，`runner=true`，runner 具备 `start_location()` 和 `location_config()`，初始 hold=0。
- 直接调用 `runner.start_location("overtime")`：日程写入 `周六:公司加班 | 周日:空闲`，`hold_runner=1`，`hold_app=1`，阻塞地点对话出现。
- 点掉地点叙事和结算后：`hold_runner=0`，`hold_app=0`，`money` 增加，`energy=60`，`sanity=65`。
- 第一周加班后的教程链仍正确：`gate=wechat`。
- 地图渲染仍正确：`visible=true`，`children=1`，`cards=8`，`modulate=(1,1,1,1)`。
- Godot 项目脚本无编译错误。MCP 曾因临时 `await process_frame` 验收脚本产生两条 debugger warning，属于工具脚本噪音，不是项目脚本错误。

## 24. 2026-06-20 追加：CityEventController / EncounterController 拆分

本轮继续执行用户要求的“架构优先，别一直小补丁”。上一轮地点生命周期已归 `LocationActionRunner`，这一轮把地点行动后半段的城市碎片和 NPC 邂逅/重逢从 `AppPopupSystem.gd` 拆出去。

新增脚本：
- `scripts/CityEventController.gd`
  - 接管 `Data/city_fragments.json` 加载。
  - 接管城市碎片随机筛选、`min_turn` 过滤、带选项碎片 UI、选项花费/收益合并、碎片结果展示。
  - 碎片选项期间仍锁住“结束本周”，结束后释放，保持旧体验。
- `scripts/EncounterController.gd`
  - 接管 NPC 邂逅条件判断、条件不足提示、邂逅冷却写入、微信请求阶段衔接。
  - 接管 NPC 重逢候选检查、重逢演出、重逢结算。
  - 继续保持当前口径：第一阶段核心男性随机邂逅关闭，关系入口以后由主线/半主线事件确定触发。

兼容边界：
- `AppPopupSystem.gd` 继续保留 `_city_fragments`，作为城市碎片池镜像，避免旧调试/临时脚本读取断掉。
- `AppPopupSystem.gd` 继续保留 `_encounter_cooldowns`，因为 `GalgameSystem.gd` 和 `DebugPanel.gd` 仍会直接读写这个字段。
- `AppPopupSystem.gd` 里的 `_trigger_city_fragment()`、`_check_encounter()`、`_handle_encounter()`、`_check_reunion()`、`_handle_reunion()`、`_show_reunion_result()` 都改成薄壳，转发到新控制器。
- `LocationActionRunner.gd` 查询城市碎片时，优先走 `AppPopupSystem._has_city_fragments()`，不再直接依赖 App 内部字典。

当前边界：
- 地图 App：`MapAppController`。
- 地点生命周期：`LocationActionRunner`。
- 城市碎片：`CityEventController`。
- NPC 邂逅/重逢演出：`EncounterController`。
- `AppPopupSystem` 仍然负责大量手机 App、通用弹窗、数值结算展示和旧入口兼容。下一轮清理重点应转向支付宝/微信/职业 App 或通用结算展示服务，而不是继续往 App 文件里塞新玩法。

验证结果：
- Godot 编译：`CityEventController.gd`、`EncounterController.gd`、`AppPopupSystem.gd`、`LocationActionRunner.gd` 均通过。
- 运行态实例化：`app=true`，`_city_events=true`，`_encounters=true`。
- 城市碎片池读取成功：keys 为 `gym/library/bar/home/park/cafe/market`。
- 连续两次打开地图：`map_visible=true`，`location_menu.children=1`，没有地图 UI 叠层。
- `AppPopupSystem._has_city_fragments("park") == true`。
- `AppPopupSystem._check_encounter("park")` 返回空，符合当前“随机核心男性邂逅关闭”的设计口径。
- 直接触发 `AppPopupSystem._trigger_city_fragment("park")`：Galgame 对话出现，地点 hold 计数为 1，说明城市碎片展示链路已由新控制器接管。
- Godot editor errors 最终为 0。

## 25. 2026-06-20 追加：ActionResultController 接管叙事结算链路

本轮继续执行“代码架构先收干净”的路线。上一轮已拆出城市碎片和 NPC 邂逅/重逢，本轮把 `AppPopupSystem.gd` 中被地点、碎片、邂逅、职业、消费 App 共同依赖的叙事结算链路拆出来。

新增脚本：
- `scripts/ActionResultController.gd`
  - 接管结果文本清洗：移除地点叙事里嵌入的彩色结算行。
  - 接管结算文本格式化：普通数值结算、NPC 好感结算。
  - 接管结果展示：优先调用 `MainGame.show_result_text()`，否则回落到 Galgame 对话。
  - 接管叙事 -> 结算 -> 应用数值 -> 回调的完整顺序。
  - 接管数值应用：普通地点/行动数值、NPC 好感、`credit_debt`、`max_energy` 等兼容逻辑。
  - 接管变更字典合并和未绑定 NPC 好感过滤。

兼容边界：
- `AppPopupSystem.gd` 保留原函数名：
  - `_format_result()`
  - `_show_result()`
  - `_show_story_then_apply_changes()`
  - `_show_story_then_apply_npc_changes()`
  - `_merge_change_dicts()`
  - `_apply_location_changes()`
  - `_apply_npc_bonus_changes()`
- 这些函数现在是薄壳，转发到 `ActionResultController`。这样宝淘、团美、贝壳、职业、城市碎片、邂逅等旧调用不需要大范围改名。

当前边界：
- `AppPopupSystem` 不再自己维护叙事结算/数值应用细节。
- 之后如果要统一“对话框压暗第二层 UI”“结算展示节奏”“蓝字教程/普通剧情/结算三类文本层级”，优先从 `ActionResultController` 或 MainGame 的结果展示入口继续收，而不是散修每个 App。
- `MainGame.gd` 里仍有工作日 `_show_action_result()` 和若干主线处直接调用 `action_service.apply_stat_changes()`，未来可以考虑继续把主线/工作日结果也统一到同一结果控制器或 ActionService 上，但本轮先不扩大改动面。

验证结果：
- Godot 编译：`ActionResultController.gd`、`AppPopupSystem.gd`、`CityEventController.gd`、`EncounterController.gd` 均通过。
- 运行态实例化：`app._result_flow != null`。
- `_merge_change_dicts({"sanity":2,"energy":-1},{"sanity":3,"energy":1})` 返回 `{"sanity":5}`，零值会被清掉。
- `_strip_embedded_result_lines("路上很累\n[color=90EE90]情绪 +3[/color]")` 返回 `路上很累`。
- `_apply_location_changes({"sanity":7,"energy":-5})` 在情绪/精力设为 50 时，结果为情绪 57、精力 45。
- 连续两次打开地图仍然 `child_count=1`，地图 UI 没有叠层。
- `AppPopupSystem._has_city_fragments("park") == true`。
- Godot editor errors 最终为 0。

## 26. 2026-06-20 追加：CareerAppController 接管 BOSS弯聘/职业系统

本轮继续执行“清架构，不堆小补丁”。上一轮已经把通用叙事结算链路拆到 `ActionResultController`，本轮把 `AppPopupSystem.gd` 里的 BOSS弯聘/职业系统迁出。

新增脚本：
- `scripts/CareerAppController.gd`
  - 接管 BOSS弯聘打开与 UI 构建。
  - 接管职位名、学历名展示。
  - 接管职业行动门槛：是否周末、周末日程是否已满、精力是否足够、学历是否达标、年龄是否超过 30。
  - 接管三个职业动作：
    - 回到初级行政。
    - 投递/跳槽新媒体运营。
    - 投递/跳槽大客户经理。
  - 职业动作仍通过 `ActionResultController` 的旧兼容入口展示叙事与结算，不自己应用数值。

兼容边界：
- `AppPopupSystem.gd` 继续保留旧函数名：
  - `_on_app_job()`
  - `_on_job_admin()`
  - `_on_job_media()`
  - `_on_job_client()`
  - `_media_lock_reason()`
  - `_client_lock_reason()`
  - `_get_job_name()`
  - `_get_degree_name()`
- 这些函数现在只转发到 `CareerAppController`，因此 `MainGame.gd` 里原来的按钮连接 `btn_app_job.pressed.connect(app._on_app_job)` 不需要改。

当前边界：
- 职业 App 以后归 `CareerAppController`。
- 职业系统未来会承载学历、工作跃迁、年龄风险、陈默资源入口、职场主线压力，不应再把新职业逻辑写回 `AppPopupSystem.gd`。
- `CareerAppController` 当前仍复用 `AppPopupSystem._build_app_overlay()` 的通用列表 UI。以后如果 BOSS弯聘要变成独立大屏/更复杂的招聘 UI，可以在这个控制器里单独演化。

验证结果：
- Godot 编译：`CareerAppController.gd`、`AppPopupSystem.gd` 均通过。
- 运行态实例化：`app._career_app != null`。
- 测试态设置 `turn_count=8`、周末、成人本科、精力/情绪 100 后打开 BOSS弯聘：`job_visible=true`，`children=1`。
- 新媒体运营面试门槛为空：`app._media_lock_reason() == ""`。
- 触发新媒体运营面试后，职位变为 1，周末日程写入 `周六:新媒体运营面试 | 周日:空闲`。
- 职业 App 重新打开后显示当前职位 `新媒体运营`，大客户经理门槛为空。
- 验收脚本中一次强行连续结束两段 Galgame 对话触发 MCP debugger warning，但后续状态确认职业动作已完成；项目脚本本身无编译错误。

## 27. 2026-06-20 追加：DiaryAppController 接管日记本 UI/筛选/流水

本轮继续从 `AppPopupSystem.gd` 拆具体 App。日记本是玩家复盘行动、数值变化和关键选择的反馈系统，后续主线和关系线变长后会更重要，因此独立成控制器。

新增脚本：
- `scripts/DiaryAppController.gd`
  - 接管日记本大屏 UI 初始化。
  - 接管本月回顾 summary。
  - 接管筛选按钮收集、样式刷新、当前筛选状态。
  - 接管活动流水渲染，包括时间、分类、描述、数值变化文本和颜色。
  - 接管空状态提示。

兼容边界：
- `AppPopupSystem.gd` 保留旧入口：
  - `_on_app_diary()`
  - `_on_diary_filter(category)`
  - `_refresh_diary_ui()`
  - `_setup_diary_heavy_ui()`
- 这些函数现在只转发到 `DiaryAppController`，因此 `MainGame.gd` 中原有按钮连接不用改。
- `AppPopupSystem.gd` 仍保留 `diary_popup` 和 `diary_log_container` 引用，因为通用关闭/层级管理仍需要它们。

实现细节：
- 日记控制器自己持有 `_filter`、`_filter_buttons`、`_summary_label`，不再把日记状态挂在 `AppPopupSystem`。
- `refresh_ui()` 清理日志节点时先 `remove_child()` 再 `queue_free()`，避免同一帧切筛选时旧日志和新日志短暂叠在一起。
- 日记本仍复用 `HeavyAppUI` 和 `AppPopupSystem` 的通用大屏/样式工具，后续如果日记要做成更强的复盘系统，可继续在 `DiaryAppController` 里演化。

验证结果：
- Godot 编译：`DiaryAppController.gd`、`AppPopupSystem.gd` 均通过。
- 运行态实例化：`app._diary_app != null`。
- 测试态设置 `turn_count=5`、周末并写入 3 条活动记录后打开日记：`visible=true`，日志节点数为 3。
- 切换到“消费”筛选后：日志节点数即时变为 1，包含“通勤衬衫”，不包含“职业复盘”。
- Godot editor errors 最终为 0。

## 28. 2026-06-20 追加：ConsumerAppController 接管消费类 App

本轮继续执行“先清架构，不再堆小补丁”的路线，把 `AppPopupSystem.gd` 里的宝淘、团美医美、贝壳找房和深夜失眠冲动消费迁出到独立控制器。

新增脚本：
- `scripts/ConsumerAppController.gd`
  - 接管宝淘打开、商品列表渲染、护肤/穿搭支付入口。
  - 接管团美医美打开、医美项目列表渲染、颜值门槛和支付入口。
  - 接管贝壳找房打开、住房列表渲染、押金门槛、换房结果和房租状态写入。
  - 接管深夜失眠随机诱惑、冲动消费/忍住睡觉两个选择、活动日志与周推进。
  - 继续复用 `AppPopupSystem._build_app_overlay()`、`ActionResultController` 的叙事结算入口和 `AlipaySystem.request_payment()`，不重复造 UI/支付/结算链路。
  - 清理菜单 child 时使用 `remove_child()` 后 `queue_free()`，避免同帧重复打开 App 时旧内容和新内容叠在一起。

兼容边界：
- `AppPopupSystem.gd` 保留旧入口函数：
  - `_on_app_baotao()`、`_on_app_tuanmei()`、`_on_app_house()`
  - `_on_bt_skincare()`、`_on_bt_fashion()`
  - `_on_tm_injection()`、`_on_tm_surgery()`
  - `_on_house_village()`、`_on_house_apartment()`、`_on_house_luxury()`
  - `_enter_late_night()`、`_on_emo_bag()`、`_on_emo_sleep()`
- 这些旧入口现在只转发到 `ConsumerAppController`，所以 `MainGame.gd` 现有按钮连接、`WeekFlowController` 的深夜入口和旧调试脚本不会断。
- App 解锁仍走 `GameManager.is_app_unlocked()`；手机教程/阻塞对话仍走 `MainGame.can_open_phone_app()`，拆分不会绕过新手教程门控。

当前边界：
- 消费类 App 以后归 `ConsumerAppController`。新增消费陷阱、消费欲望、换房、深夜冲动消费，不要再写回 `AppPopupSystem.gd`。
- `AppPopupSystem.gd` 仍保留通用 App overlay 构建、层级显示、重置视觉状态、通用关闭和兼容入口。
- 支付宝本体、微信本体仍在各自系统里，消费类 App 只负责调用支付和承接结算，不直接改支付宝 UI。

验证结果：
- Godot 编译：`AppPopupSystem.gd`、`ConsumerAppController.gd` 均通过。
- Godot 项目 headless 加载通过，无脚本编译错误。
- 运行态实例化：`app._consumer_app != null`。
- 测试态设置 `turn_count=17`、周末、清除阻塞对话后：
  - 宝淘打开：`visible=true`，`children=1`。
  - 团美打开：`visible=true`，`children=1`。
  - 贝壳打开：`visible=true`，`children=1`。
  - 深夜失眠弹窗打开：`visible=true`，冲动消费按钮文字正常。
- 连续两次打开宝淘后 `child_count=1`，无叠层。
- 触发宝淘护肤支付入口后 `payment_popup.visible=true`，旧按钮动作到新控制器再到支付宝的链路未断。
- MCP 日志里保留了一条早先测试脚本误调用不存在方法和一次截图目录不存在造成的工具噪音；后续脚本编译与运行态验收均正常。

## 29. 2026-06-20 追加：WeekPlanningController 接管工作日规划

本轮继续清理“基础流程系统”。用户之前多次遇到“本周饮食标准灰掉、提前结束后卡死、工作日/周末流程按钮状态混乱”的问题，因此把工作日规划从 `AppPopupSystem.gd` 和 `MainGame.gd` 里收出来，单独放到 `WeekPlanningController`。

新增脚本：
- `scripts/WeekPlanningController.gd`
  - 接管工作日规划按钮状态：饮食按钮初始可点，工作态度按钮初始锁住；选择饮食后锁饮食、解锁工作。
  - 接管三档饮食选择：低档 +300 餐饮且情绪 -5；中档 +800 餐饮且精力 +10；高档 +2000 餐饮且情绪 +20、精力 +15。
  - 接管三档工作态度：摸鱼、正常打卡、疯狂加班，对应精力/情绪/待发工资变化。
  - 接管工资档位计算、工作日结算叙事、结算页、衰老延迟消息后的工作日结束。

兼容边界：
- `MainGame.gd` 保留旧入口函数：`_on_food_low()`、`_on_food_mid()`、`_on_food_high()`、`_on_work_slack()`、`_on_work_normal()`、`_on_work_overtime()`、`_complete_work_action()`、`_apply_action_changes()`、`_show_action_result()`、`_get_salary()`、`_finish_workday()`。
- 这些函数现在只转发到 `WeekPlanningController`，保证旧调试脚本或旧系统调用不断。
- `AppPopupSystem.gd` 保留旧饮食函数名 `_on_food_low()`、`_on_food_mid()`、`_on_food_high()`、`_unlock_work_buttons()`，但只做兼容转发；手机 App 系统不再持有饮食/工作按钮引用。
- `WeekFlowController.gd` 仍负责进入工作日、进入周末、月底/周末推进；但按钮状态重置和工作按钮文案更新转交给 `WeekPlanningController`。

当前边界：
- 以后任何“工作日规划面板”的改动，优先改 `WeekPlanningController`。
- `WeekFlowController` 只管阶段流转，不写具体饮食/工作数值。
- `AppPopupSystem` 不再写工作日规划逻辑。
- `MainGame` 目前仍保留工作日结束转场 `_play_transition()`、职场事件 `_proceed_after_work_event()`，因为它们牵涉主场景 UI 和事件层；后续如果继续拆，可以再收成 `WorkdayTransitionController` 或并入 `WeekFlowController`。

验证结果：
- Godot 编译：`WeekPlanningController.gd`、`MainGame.gd`、`AppPopupSystem.gd`、`WeekFlowController.gd` 均通过。
- Godot headless 项目加载通过。
- 运行态进入工作日规划：面板显示，饮食可点，工作态度锁住。
- 选择中档饮食后：`monthly_food_cost=800`，`energy=60`，`sanity=50`，工作按钮解锁。
- 旧入口 `app._on_food_low()` 仍可转发：`monthly_food_cost=300`，`sanity=45`，连续吃差计数 +1，工作按钮解锁。
- 选择正常打卡后进入叙事/结算链；点掉叙事和结算后，`pending_salary=1500`，`energy=70`，`sanity=85`，进入工作日结束转场。
- 转场后落到职场事件阶段属于正常随机事件链，不是卡死。
- Godot editor errors 最终为 0。
