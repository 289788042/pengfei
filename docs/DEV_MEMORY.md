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
