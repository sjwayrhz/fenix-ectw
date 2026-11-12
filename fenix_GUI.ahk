#Requires AutoHotkey v2.0
#SingleInstance Force
#Include FindText.ahk

; 必须开：不然 WinGetList 只找得到当前桌面上的窗口，
; 其他桌面上的游戏窗口会被当成隐藏窗口漏掉，
; 对齐（AlignGameWindows）就永远只找到 1 个、没东西可挪。
; 轮询不受影响，因为它每次只要当前桌面那一个窗口。
DetectHiddenWindows(true)

; ============================================================
; fenix 功能菜单（图形界面版，AHK v2）
; 原来的两个脚本已经合并到这一个窗口里，
; 不会出现两个脚本互相冲突。
;
; 功能：
;   1. 桌面轮询（F11）：按 F11 或点按钮启动后，三个桌面一直
;      轮询切换，停掉之前不会自己停。
;      切到每个桌面后，先激活游戏窗口（窗口是窗口模式跑的，
;      不激活的话按 F/X 进不去游戏；以前要手动点一下窗口，
;      现在脚本自己激活，不用手动点了）。先按窗口标题找：
;      标题是 "Atlantica Online Fenix"，三个桌面标题都一样，
;      但每个桌面只有一个游戏窗口，用 DLL 的
;      IsWindowOnCurrentVirtualDesktop 挑出当前桌面上的那一个
;      激活它，不会切到别的桌面去。标题找不到时再用图标位置
;      找（图标在当前桌面上，图标位置的窗口就是当前这个桌面的
;      游戏窗口）。
;      轮询时先看放映机图标和状态图标：放映机图标在、并且是
;      非暗色，就只按 X、不按 F；其他情况按 F，放映机图标在才
;      在约 0.05 秒后按 X。
;      状态图标是交叉双剑的方形图标：亮版底色浅蓝、暗版底色
;      深紫，图标里的数字会变，只认图案不看数字。三种状态：
;      暗色（暗版图案找到）、未知（未知图案找到，全黑、剑也是
;      黑的、只有边框是亮的那种）、非暗色（两个都没找到，就当
;      亮色）。放映机图标是附件里那张放映机截图（45x39），
;      它在才说明能按 X、能点状态图标。
;      用 FindText 找图标：暗版一个 42x35 的黑白图案（阈值 120，
;      从你发的截图转出来的），暗版是深底浅剑；未知一个 46x41 的
;      黑白图案（阈值 82，从你发的截图整个图标转的），全黑、剑也
;      是黑的、只有边框亮；亮版图案只用来定位亮色图标的位置、记下
;      坐标，不参与亮暗判断。放映机图标一个 45x39 的图案（阈值 68）。
;      暗版图案找到后，还要在图标中心附近取一个 5x5 网格验亮度
;      （亮点不到一半才是真暗色），因为亮版图标底色浅、亮点多，
;      图案万一认错亮版，亮度能把它拦下来。未知图案和亮版、暗版
;      都认不到对方，图案本身就够了，不用再验亮度。
;      在游戏窗口里面全窗口找图标，不用记位置：窗口挪位置、
;      图标挪位置都能找到；窗口外面不找，屏幕别处的暗色
;      误匹配进不来。
;      之前用的 ImageSearch 模板图里带了会变的数字和游戏背景角，
;      数字一变、背景一换就整张对不上，所以完全找不到；FindText
;      只比图案本身的明暗形状，容错 0.2，数字变了也不影响。
;      轮询：
;        每轮到一个桌面：先激活游戏窗口，再在窗口里面找放映机
;        图标和状态图标；放映机图标在、并且是非暗色，就只按 X、
;        不按 F；未知图标按 F、按 X、不点图标；放映机图标在、并且
;        状态图标是暗色，才按 F、按 X、点状态图标一下，尝试帮它
;        变亮色。放映机图标不在，就只按 F，不按 X、不点。一直重复。
;        桌面1永远不按 X，只有桌面2、桌面3按（F、点图标在桌面1照常）。
;      没有暂停按钮：F11（或点「启停键 F11」按钮）就是停止
;      （再启动从桌面 1 重新开始）。
;   2. 开箱子（两点点击 + 右键点击合并）：
;      左边按钮：两种点击同时操作
;        两点点击：(700,450) 点一下 -> (822,450) 点一下，循环
;        右键点击：同时在 (980,593) 定时右键
;      中间按钮：抽奖（只做右键点击）
;        只在 (980,593) 定时右键，两点点击不启动
;      右边按钮：合成（只做点击移动点击，即两点点击）
;        只做两点点击，右键点击不启动
;      三个按钮互斥：点另一个会先停掉当前模式再启动新模式；
;      再点一次正在运行的按钮就是停止。
;   4. 账号登陆（没有快捷键，只能点按钮）：
;      三个短下拉框一个桌面一个（桌面1/2/3），每个框里是 accounts
;      文件夹里已保存的账号（一个账号一个 .txt，文件名就是账号名，
;      第 1 行是登陆密码，第 2 行是二次密码），只能选、不能输；
;      每个框最后一行是空行，选空行 = 这个桌面不登陆。
;      同一排右边三个按钮：新增（弹对话框填账号、密码、二次密码，三个都填好
;      点保存才写入 accounts\账号名.txt）、登陆、删除（删桌面1框里选中的账号）。
;      点登陆：窗口最小化 -> 按桌面 1→2→3 依次切桌面、激活该桌面的
;      Atlantica Online Fenix 客户端 ->
;      FindText 找 Login 按钮 -> 点账号框输账号 -> Tab -> 输密码 ->
;      点 Login -> 等待：出现二次密码界面就点密码框、用 FindText
;      逐个识别数字键、按二次密码依次点数字、等“输入”变亮后点它；
;      出现“登陆确认”对话框就用 FindText 找“是”并点击。
;      登陆过程中按 Esc 取消。
; 使用：双击运行本脚本，点按钮或按快捷键即可。
;       F11 开关桌面轮询，F12 开关开箱子（兼取点键）。
;       桌面轮询有一个「启停键 F11」按钮，右边有个
;       「使用女神的生命水」勾选框，勾上后右边出现冷却分钟下拉框；参数直接写死在代码里。开箱子的坐标用按钮取点（点取点按钮后窗口会最小化，
;       把鼠标移到位置上按 F12 取点），点“保存配置”会存到同目录的
;       fenix_Config.ini，下次打开自动恢复。
;       关窗口或点“退出”即全部停止并退出。
; 注意：功能 1 需要 VirtualDesktopAccessor.dll 和 FindText.ahk
;       都放在本脚本同目录，DLL 版本要和你的
;       Windows 版本匹配，否则该功能会被禁用。
; ============================================================

CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; ===== 功能 1 的 DLL（先加载，失败也不影响功能 2）=====
DllPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
hDll := DllCall("LoadLibrary", "Str", DllPath, "Ptr")
GoToDesktopNumberProc := 0
GetDesktopCountProc := 0
IsWindowOnCurrentVirtualDesktopProc := 0
GetWindowDesktopNumberProc := 0
GetCurrentDesktopNumberProc := 0
DesktopCount := 0
PollDesktopCount := 0   ; 轮询实际跑的桌面数 = min(桌面总数, 3)，启动轮询时算（她 2026-11-09 定：只跑前 3 个）
if (hDll) {
    GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hDll, "AStr", "GoToDesktopNumber", "Ptr")
    GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hDll, "AStr", "GetDesktopCount", "Ptr")
    IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hDll, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
    GetWindowDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hDll, "AStr", "GetWindowDesktopNumber", "Ptr")
    GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hDll, "AStr", "GetCurrentDesktopNumber", "Ptr")
    DesktopCount := DllCall(GetDesktopCountProc, "Int")
}

; ===== 状态 =====
DesktopRunning := false
DesktopNext := 0        ; 下一个要去的桌面（从 0 开始，即桌面 1）
DesktopPhase := "switch"
DesktopWaitMs := 1000
DesktopKey := "f"
DesktopKey2 := "x"      ; 每次按 F 后再按的第二个键
KeyGapMs := 50          ; 按 F 和按 X 之间相隔的毫秒数（约 0.05 秒）
SwitchClickX := 212     ; 每次切换后要点的固定位置
SwitchClickY := 57
GameTitle := "Atlantica Online Fenix"  ; 游戏窗口标题（截图里看到的；三个桌面都一样，但每个桌面只有一个，用 DLL 挑当前桌面上的那一个）

; ===== 轮询循环（功能 1）的阶段和计时 =====
; 没有检测阶段了：每次到一个桌面，先激活游戏窗口，再找图标
; （放映机图标和状态图标），找到就按规则处理。位置都是固定
; 的：第一次全窗口找并记下位置，以后只在记录位置附近找。
; DesktopPhase 是每一步的小阶段：switch 切桌面、activate 激活游戏窗口
; （先按标题找，找不到再用图标位置）、click212 点切换后坐标、click 原地点击、
; check 检查放映机图标和状态图标（决定按 F 还是只按 X、点不点
; 状态图标）、pressX 按 X 和点图标。
CyclePhase := "main"
CycleCount := 0
CurrentDesktop := 0
QuickSwitchEnabled := false ; 快捷切换桌面（键盘 F1/F2/F3）的开关；打开脚本时默认开启（自动执行段末尾调 StartQuickSwitch）
Recording := false        ; 是不是正在录鼠标
RecordEvents := []        ; 录下来的鼠标动作，每条是 [类型, X, Y, 间隔毫秒]
RecordLastTick := 0       ; 上一个录下来的动作是什么时候（A_TickCount）
RecordLastL := false      ; 上次轮询时左键是不是按着
RecordLastR := false      ; 上次轮询时右键是不是按着
PlayingBack := false      ; 是不是正在回放
RecordsDir := A_ScriptDir "\records"  ; 保存的录制文件夹，一个录制一个 .txt 文件
LoadedRecordName := ""  ; 当前内存里的录制是从哪个文件读来的（空表示刚录的、没保存）
; 录键盘时要轮询的按键（脚本自己的热键 F1-F5、F8、F9、F11、F12、飘号键不录，
; 免得录进去又触发脚本功能）。字母、数字、空格、回车、Tab、Esc、退格、
; 左右 Shift/Ctrl/Alt、方向键、F6/F7、小键盘。
KeysToRecord := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","1","2","3","4","5","6","7","8","9","0","Space","Enter","Tab","Escape","Backspace","LShift","RShift","LCtrl","RCtrl","LAlt","RAlt","Up","Down","Left","Right","F6","F7","Numpad0","Numpad1","Numpad2","Numpad3","Numpad4","Numpad5","Numpad6","Numpad7","Numpad8","Numpad9","NumpadDot","NumpadAdd","NumpadSub","NumpadMult","NumpadDiv","NumpadEnter"]
KeyPrevState := Map()       ; 每个按键上次轮询时是不是按着（录键盘用）
; 刚激活的游戏窗口的位置和大小，找图标只在这个窗口里面找。
GameWinX := 0
GameWinY := 0
GameWinW := 0
GameWinH := 0
; 各桌面记下的图标中心坐标（下标从 1 开始，对应桌面 1、2、3……）
; 0 表示该桌面还没找到这个点（第一次全窗口找，找到就记下来）。
CalStatusX := []        ; 状态图标（双剑）中心
CalStatusY := []
CalProjX := []          ; 放映机图标中心
CalProjY := []
CheckProjFound := false ; 这轮检查：放映机图标在不在（check 步记下，pressX 步用）
LifeWaterUsed := [false, false, false] ; 女神的生命水：每个桌面（下标 1..3）有没有记过「已使用」
LifeWaterPressTick := [0, 0, 0] ; 女神的生命水：每个桌面上次按 F9 的时刻（A_TickCount，0=没按过），给冷却下拉框计时用
ProjPrevYes := [false, false, false] ; 每个桌面上一次轮询时放映机在不在（暗色点击有效期用）
ProjYesTick := [0, 0, 0]             ; 每个桌面放映机这次「连续在」是从何时开始的（A_TickCount，0=当前不在）
DarkClickWindowMs := 15000           ; 暗色点击有效期：放映机由不在变在之后 15 秒内点才有效
CheckStatusNotFound := false ; 这轮检查：状态图标是不是都没找到（check 步记下，pressX 步用）

; ===== 图标图案（功能 1 用，FindText）=====
; 状态图标：交叉双剑的方形图标，亮版底色浅蓝、暗版底色深紫，
; 图标里的数字会变，只认图案不看数字。亮版图案 42x35，阈值 120，
; 从你发的截图裁出来的图标方形转的（取 y 7-41、x 3-44），浅底
; 深剑（暗像素只占约 9%）。暗版原来也用整图 42x35，后来发现中间
; 的计数数字会变（3/50、10/50…）、整图被数字拖累，换一台电脑时
; 偶尔认不出，2026-11-07 改成左右两条没有数字的长条（左 13 宽、
; 右 15 宽、满高 42、阈值 120），两条都对上才算找到，见
; DarkStripLText 处的说明。亮暗判断只看暗版：找到暗版就是暗色；
; 暗版没找到时再找未知图案，找到就是未知；两个都没找到就当
; 非暗色（亮色）。亮版图案只用来定位亮色图标的位置、记下坐标，
; 不参与亮暗判断。未知图案（46x41，阈值 82）和亮版、暗版都认不到
; 对方，见 StatusUnknown.png。
; 放映机图标：附件里那张放映机截图，45x39，阈值 68，整个图
; 标转的图案，里面没有会变的数字。它在不在，决定按不按 X、
; 点不点状态图标。
; FindText 返回的是图案中心，点图标中心用的就是这个坐标。
; 游戏里图标尺寸变了图案就对不上，到时把游戏实屏截图发我，
; 按实际尺寸重做图案。
; FindErr1/FindErr0 是 FindText 的容错（0.1 = 10%）：找不到
; 就调高，认错别的图标就调低。
FindErr1 := 0.1
FindErr0 := 0.1
ProjErr1 := 0.2
ProjErr0 := 0.2
; 状态图标（亮/暗/未知）专用容错：2026-11-06 由 0.1 调高到 0.2，
; 和放映机一样宽松（出现过约 80 分钟三种图标图案都认不出的情况；
; 亮/暗认错还有亮度复核兜底）。FindErr 保持 0.1 不动，登陆流程的
; 等待搜索（登陆按钮、确认按钮、输入按钮）还在用它，别跟着变。
IconErr1 := 0.2
IconErr0 := 0.2
BrightText := "|<Bright>*120$42.U000001000000000000000000000003zk00003zk10401zU20430z0k041UV1U040kS30040MA6E040A0A004060M004030k00001VU00400H0004000000400M000400Q000000S000000n000001VU000030k0000200000040A000000400000040000E06000000000000000000000000400080000000000000000000001U"
; 暗版图标不用整图图案，改用左右两条长条（2026-11-07 她定的方案）：
; 图标中间的计数数字会变（3/50、10/50…），整图图案被数字拖累，
; 换一台电脑时偶尔超容错认不出。两条长条里没有数字：从
; StatusDark.png 取左条 x2..14（宽 13）、右条 x30..44（宽 15），
; 满高 42，阈值 120。宽度逐个测过：左 10/11 宽正好切在剑刃高亮
; 边缘上、误差反而高，13 宽最稳；右条越宽越稳，15 宽再留一列
; 余量不碰数字。两条一起验（相对位置锁死）：对另一台电脑的新图
; 误差 0.06，对亮/未知图标 0.7 以上，不会认错。判断逻辑在
; FindDarkPair：先找左条，再在它右边找右条，两条都对上才算暗版。
DarkStripLText := "|<DarkL>*120$13.zzzzw04zyzrTsjwLz/zZzyzzTzjzrzvzxzyzzTzjzrzvzxzyzTTjjvrzvzxzyzzTzzzzzzzzzzzzzTzrzzzzzzzzyDzU"
DarkStripRText := "|<DarkR>*120$15.zzzzz00Dzxyzr7ykzoDy1zkzyDznzyzzrzyzzrzyzzrzyzzzzzzzzzzzjzxzzTtzzrzwzzbzyzzrzyzzrztzzzzzyzzjzzzzzzzzzzzzzU"
; 左条中心到右条中心的横向距离（两条满高、上下对齐，纵向差 0）；
; 图标中心 = 两条中心的中间点（左条中心 +14.5）。
DarkStripDx := 29
UnknownText := "|<Unknown>*82$46.zzzzzzzvzzzzzzzjzzzzzzzk000000yTzzzzztdzTzzyzqjwzzznzSzszzwTxfzVzzVzqjz3zwDzOzzDznzxfzwTyDzqjzszlzzOzznzDzxfzzbtzzqjzzDDzzOzzytzzxvzzxjzzrjzztzzzSzzzrzzxfzzzzzzqjzzzzzzOzzzzzzxfzzzzzzqjrzzzyzOzzzzzzxfzzzzzzqjzzzzzzOzyTztzxfztzzbzqjzzzzzzOzzzzzzxfzzzzzzqjzzzzzzOzzzPzzxfzzzzzzyjjzzzzTTzzzzzzzi000000SzzzzzzzvzzzzLzzz"
ProjectorText := "|<projector>*79$46.s000000TDzzzzzwwzzzzzzurzzzzzzfTzVzzzyhzw3zzzurzm7zzzfTy0Nzzyhzt3y3zurzk7sLzfTzEQBTyhzx7koTurzm711zfTz8SOTyhzUXs7zurw0AgTzfTU00kTyhy03k/Turl07k5zfTY030DyhyG00Svurxj007zfTszk7zyhzkzkTzurzUzszzfTyET7zyhztkATzurznsDzzfTzbwTzyhzzbzzzurzzbzxzfTzzbzzyhzzznzzurzzzzzzfzzzzzzzj000000D"
ProjectorTextOld := "|<projector>*68$45.Tzzzzzzv0000003Hzzzzzz+TzzzzzxLzwLzzzezz1zzzxLzk7zzzezy0zzzxLzU6T3zezw0s1zxLzU3EHzezw0sERxLzo701zezy0s0DxLzm764rezk0k1axLw084Srez001UCxLk0601zey80y0jxLl00k1jez8006NxLt0007jezUz07zxLz3z0zzezs3y7zxLzU7lzrezwM6DyxLzVs7zzezz7szzxLzwDzzzezzsTzbxLzzszbzezzzkXzxLzzzzzzfTzzzzzzQ000000vzzzzzzzSnk0008I"

; ===== 功能 4：账号登陆 =====
; accounts 文件夹里一个账号一个 .txt：文件名 = 账号名，第 1 行 = 登陆密码，
; 第 2 行（可选，手动添加）= 二次密码（数字）。
AccountsDir := A_ScriptDir "\accounts"
LoginRunning := false     ; 登陆流程是否在进行（Esc / 其他功能启动 / 全部停止 会把它置 false，流程在下一个等待点退出）
; 图案分工：Login / 输入 / 是 用 FindText 图案（从 1.jpg、3.jpg、4.jpg 裁的，灰度阈值法，1 = 暗点）；
; 二次密码键盘不用任何“招牌”图案当锚点——黄色“2级密码”字样在她屏幕上有多处假匹配（实测栽过），
; 改成：数字图案直接从她逐个截的 10 张数字图生成，拿 FindText 在整个游戏窗口里逐个数字
; 找命中，再按键盘格距把命中拼成一整盘才认（见 HuntPinKeypad）。
; 找图和拼图的结果都会写进 fenix_Find_Log.txt。
; Login 按钮上的 "Login" 字样（1.jpg）
LoginBtnText := "|<Login>*150$39.zzzzzzzzzzzzzzzzzzzzTzzzTztzzzlzzDzzzzztz7UTzzDUM2M7twlCH4zDb9mNrtwtCHCzDb9mNrtwnUHCz0svnNrzzzAzzzzzyDzzzzzzzzzzzzzzzzzzzzzw"
; 二次密码界面里变亮的 "输入" 按钮字样（3.jpg）
SecEnterText := "|<Enter>*160$31.zzzzzzzzzzzzzzzznbszztVzDzk6TnzwU7tzwDzsTy0NwDzk0y7zs0SNzk0DAzy07DDz0nDnzUFDwzzzzzzzzzzzzzzzzU"
; 登陆确认对话框里的 "是"（4.jpg）
ConfirmYesText := "|<Yes>*150$17.zzzzzzzzzk7zjjz0Tyyzw1zzzz01zxzzMDyrzujzi0zzzzzzzzzU"
; 英文客户端确认对话框里的 "Yes"（image-25）；确认那一步两个图案都找，哪个先找到点哪个
ConfirmYesENText := "|<YesEN>*150$24.zzzzzzzzzzzzxrzzxrzzyiCDyhpzzQ4zzRzDzRrjzSATzzzzzzzzzzzzU"
; 英文客户端“输入”按钮未点亮时的 "Enter" 字样（image-24，阈值 70——字是灰的、按钮面是暗的，
; 阈值得压低才分得开）。只用来在点数字之前辨认是不是英文客户端：输完密码按钮会点亮、
; 字样变色，这个图案就找不到了。英文版没有点亮图案可等，输完直接按位置点 Enter。
SecEnterENText := "|<EnterEN>*70$39.zzzzzzzzzzzzzzzzzzzzzzzzzzy3zDzzznztzzzyS333/zkH9n8TySNC1Dznn9ntzySNCTDzkHAM9zzzzzzzzzzzzzzzzzzzzzzzzzzzU"
; 登陆完成后要点掉的「关闭」二字（image-30，她 2026-11-08 截的图，32x19 整幅生成，阈值 150；
; 字的灰度在 79 以下、背景在 150 以上，中间没有过渡像素，图案很干净）
CloseBtnText := "|<Close>*150$32.0000000000000000000000448000W1Dk000040Dy8F00824E020jo0Tz8F0082AE050Z4028+F0112AE1UAUQ00000000000000008"
; 登陆后收尾点的英文「Close」图案（她 2026-11-08 的截图
; image-35.png，36x16，游戏里英文版的关闭按钮）：字芯是平的灰
; 77、按钮面是亮的 176..232，和中文「关闭」一样是暗字亮底
; （阈值 120，78..175 之间取哪都一样）。和 CloseBtnText 是
; 「或」关系：收尾时两个都找，哪个先找到就点哪个。
CloseBtnENText := "|<CloseEN>*120$36.00000000000000000000U0000SU0000UU00010b7C010ccF010cgT010cXE00UcVF00SbCC0000000000000000000000000U"
; 数字键盘上的每个数字：图案直接从她逐个截下来的数字图（十张小图，依次是 1 到 9、0）
; 按原图大小生成，一个合成像素都没加；阈值 160 和图案写在一起。
; 数字随机排列，所以每个数字单独认；认的时候只找密码里用到的那几个。
DigitText := Map(
    "0", "|<P0>*160$17.zzzzzzzzzkTzCTyQzwtztnznbzbDzCTyQzwtztnzsDzzzzzzzzzzzz",
    "1", "|<P1>*160$14.zzzzzzzzzztzsTzbztzyTzbztzyTzbztzyTzbzzzzzzzzzzzzzzs",
    "2", "|<P2>*160$16.zzzzzzzzzzzw7zbDyQzznzzDztzzDztzzDztzzbzy0zzzzzzzzzzzs",
    "3", "|<P3>*160$20.zzzzzzzzzzzkTztnzyQzzzDzznzz1zzzDzznzzwzzbDztnzz1zzzzzzzzzzzzzzs",
    "4", "|<P4>*160$16.zzzzzzzzzzzz7zsTzVzwbzmTyNztbzCTwtzk3zyTztzzzzzzzzzzzs",
    "5", "|<P5>*160$16.zzzzzzzzzzzzzz0TwzznzzDzw3znbzyTztzzbzCTwtzsDzzzzzzzzs",
    "6", "|<P6>*160$18.zzzzzzzzzzzzzzzzUzzCTzCTzDzzDzz0zzCTzCTzCTzCTzCTzUzzzzzzzzzzzzzU",
    "7", "|<P7>*160$20.zzzzzzzzzzzzzzs3zzwzzzDzzbzztzzwzzzDzzbzztzzyTzzbzztzzzzzzzzzzzzzzzzzzU",
    "8", "|<P8>*160$15.zzzzzy3zbDwtzbDwtzkTwtzbDwtzbDwtzkTzzzzzzzw",
    "9", "|<P9>*160$20.zzzzzzzzzzzkTztnzyQzzbDztnzyQzzkDzznzzwzzbDztnzz1zzzzzzzzzzzU"
)
; 找数字的容错：真命中在 2.jpg、3.jpg 和她机器的实屏采样上量到的误差都是 0；
; 最容易串认的是 3 的图案认到 8 的格子（误差 0.029/0.000）。0.015 两边都卡得住：
; 真命中留了约 5 个点的余量，量到的串认全都过不去。就算偶尔串进来一个，拼图
; 那一步还有“被别的数字图案抢认的命中不算数”兜底（见 PinCellContested）。
PinErr1 := 0.015
PinErr0 := 0.015
; 以 FindText 找到的图案中心为基准的偏移（按截图量出来的）
LoginAccountDX := 0       ; Login 按钮 -> 账号输入框
LoginAccountDY := -139
; 二次密码键盘的几何（格子中心之间横竖都是 36；量自 2.jpg 并在她机器的实屏采样上核对过）：
; 每个数字的图案中心 -> 它所在格子中心的偏移（从她的截图像素量出，都是个位数像素）
PinDigitOff := Map(
    "0", [-1, 0], "1", [0, -2], "2", [0, 0], "3", [0, 0], "4", [0, 0],
    "5", [-1, 0], "6", [0, 0], "7", [0, 0], "8", [0, 0], "9", [0, 0]
)
; 10 个格子的中心相对第 1 格中心的偏移（行优先，第 4 行只有 1 格）
PinCellOff := [[0, 0], [36, 0], [72, 0], [0, 36], [36, 36], [72, 36], [0, 72], [36, 72], [72, 72], [0, 108]]
PinBoxOff := [161, 25]    ; 第 1 格中心 -> 二次密码输入框中心
PinEnterOff := [159, 107] ; 第 1 格中心 -> “输入”按钮中心
PinBoxOffEN := [146, 26]   ; 英文版：第 1 格中心 -> 二次密码输入框中心（量自 image-24）
PinEnterOffEN := [143, 108] ; 英文版：第 1 格中心 -> “Enter”按钮中心（量自 image-24）
PinHuntNote := ""         ; 最近一次找键盘的小结（各数字命中数等），登陆失败时写进日志备查

ClickMode := ""         ; "" = 未运行，"both" = 两种同时，"right" = 仅右键（抽奖），"two" = 仅两点点击（合成）
LastClickMode := "" ; F12 启动时用上次点过的开箱子模式；刚打开脚本还没点过模式按钮时为空，F12 按了没反应（第一次必须先点按钮）。只记本次运行，不存配置，关掉脚本就没了
CaptureTarget := 0  ; 0 = 没在取点；1 = 自动放入，2 = 开始精炼，3 = 箱子位置（点了取点按钮后，等按 F12 取点）
CaptureTick := 0    ; 取点成功时的 TickCount；成功后 2 秒内 F12 不起作用，防误触
TwoRunning := false
TwoPhase := 0
WaitAfterFirst := 1000    ; 点 1 后等，固定值
WaitAfterSecond := 2000   ; 点 2 后等，固定值

RightRunning := false
RightClickInterval := 3500 ; 右键间隔，固定值

; ===== 参数 =====
; 轮询的参数和开箱子的三个等待时间直接写死在代码里，不用 ini 文件。
; 开箱子的三个坐标存在脚本同目录的 fenix_Config.ini 里，
; 点“保存配置”会更新它，下次打开自动恢复。
ConfigFile := A_ScriptDir "\fenix_Config.ini"
CfgDesktopWait := "1000"
CfgDesktopKey := "f"
CfgSwitchX := "212"
CfgSwitchY := "57"
CfgPoint1X := IniRead(ConfigFile, "Click", "Point1X", "700")
CfgPoint1Y := IniRead(ConfigFile, "Click", "Point1Y", "450")
CfgPoint2X := IniRead(ConfigFile, "Click", "Point2X", "822")
CfgPoint2Y := IniRead(ConfigFile, "Click", "Point2Y", "450")
CfgRightX := IniRead(ConfigFile, "Click", "RightX", "980")
CfgRightY := IniRead(ConfigFile, "Click", "RightY", "593")

; 开箱子运行时用的坐标，先按配置文件里的值来；
; 点“取点”按钮改了之后就用新取到的值。
Point1X := Integer(CfgPoint1X)
Point1Y := Integer(CfgPoint1Y)
Point2X := Integer(CfgPoint2X)
Point2Y := Integer(CfgPoint2Y)
RightX := Integer(CfgRightX)
RightY := Integer(CfgRightY)

; ===== 图形界面 =====
; 脚本版本号（她 2026-11-09 定的方案 A：显示在窗口标题栏里）。
; 纪律：每次打新 tag 时，把这里改成新 tag 号，和 tag 保持一致
; （改这个常量的提交就是 tag 要指向的提交，这样她点「更新」
; 拉下来的标题就是对的）。
ScriptVersion := "v0.55"
MyGui := Gui(, "fenix 功能菜单 " ScriptVersion)
MyGui.SetFont("s10")

; 点按钮时先最小化窗口（藏到托盘），再执行按钮原来的功能。
; 只包按钮的点击，不包快捷键（按快捷键时不最小化）。
; 退出、取点（自己会最小化再恢复）、使用说明（要看面板）、更新（要看更新结果那一行）不用包。
MinimizeAndRun(Func) {
    return (*) => MinimizeThenCall(Func)
}
MinimizeThenCall(Func) {
    MyGui.Minimize()
    Func.Call()
}

; 使用说明面板（窗口右侧，点「使用说明」按钮展开/收起）。
HelpShown := false
HelpText := "快捷键说明"
    . "`n`nF11：开始 / 停止「桌面轮询」（只轮询前 3 个桌面，第 4 个起不去）"
    . "`n「使用女神的生命水」勾选框（在轮询启停键按钮的右边，勾上才生效）：轮询到某个桌面没找到放映机图标、且这个桌面还没用过生命水，就按一次 F9 并记为已用过；之后再轮询到还是没放映机，不再按；等轮询到这个桌面又有放映机了，标记改回未用过，下次没放映机时再按 F9。三个桌面各记各的。勾选框右边的下拉框（勾上勾选框后才出现）是冷却分钟数：某个桌面按过 F9 后，选定的分钟数内不再考虑给它按 F9，时间到了、放映机还不在就再按一次；选 0 是不设冷却，和没有这个下拉框一样；选「不使用」等于没勾这个勾选框"
    . "`nF12：取点时按它取点（取点成功后 2 秒内按 F12 不起作用，防误触）；「开箱子」运行中按它停止；没运行时按它启动上次点过的模式（刚打开脚本还没点过模式按钮时，按 F12 没反应，第一次必须先点按钮；关掉脚本后上次模式不保留）"
    . "`n飘号键（1 左边）：开启 / 关闭「快捷切换」"
    . "`nF1 / F2 / F3：切到桌面 1 / 2 / 3（快捷切换开启时才管用）"
    . "`nF4：回放录制，点按回放 1 次，按住约 2 秒弹出对话框填重复次数（默认 0 = 无限制，填 3 就回放 3 次），回放中再按 F4 立刻停（快捷切换开启时才管用）"
    . "`nF5：开始 / 停止录制，回放中按 F5 也立刻停（快捷切换开启时才管用）"
    . "`nEsc：取点时取消；账号登陆进行中按 Esc 取消登陆"
    . "`n功能 4「账号登陆」没有快捷键：桌面1/2/3 三个下拉框各选一个已保存的账号（只能选不能输），每个框最后一行是空行、选空行就是这个桌面不登陆；两个框选了同一个账号，点「登陆」会弹窗拦下，不允许重复登陆；点「登陆」按桌面1→2→3 依次登陆选了账号的桌面（切过去后先核对桌面号，没切成会跳过那个桌面、并在最后的汇总里报错，不会在错桌面上登陆），自动完成输账号密码、二次密码、登陆确认，全部登完再依次回到每个登陆过的桌面、把游戏窗口里的「关闭」（英文版是 Close，两个都认）点掉（每个桌面最多找 8 秒，找不到就跳过，登陆时报错跳过的桌面不找），最后切回开始时所在的桌面；点「新增」弹对话框，账号、密码、二次密码（只能是数字）都填好点保存，才会存成 accounts 文件夹里的 账号名.txt（第 1 行密码、第 2 行二次密码），不用再去改 txt 文件；「删除」删的是桌面1框里选中的账号"
    . "`n底部「更新」按钮（没有快捷键）：点一下就在脚本所在文件夹里执行 git pull，有新版本就自动重启脚本让新代码生效；结果显示在账号登陆下面那一行，几秒后自动消失，不弹框"
ToggleHelp(*) {
    global HelpShown, MyGui, txtHelp
    if (HelpShown) {
        txtHelp.Visible := false
        MyGui.Show("w412 h556")
        HelpShown := false
    } else {
        txtHelp.Visible := true
        MyGui.Show("w732 h556")
        HelpShown := true
    }
}

; ---- 功能 1：桌面轮询 ----
MyGui.Add("Text", "x10 y10 w360", "1. 桌面轮询 (F11)")
btnDesktop := MyGui.Add("Button", "x10 y35 w120 h30", "启停键 F11")
btnDesktop.OnEvent("Click", MinimizeAndRun(ToggleDesktop))
chkLifeWater := MyGui.Add("CheckBox", "x140 y35 w135 h30", "使用女神的生命水")
chkLifeWater.OnEvent("Click", ToggleLifeWaterOptions)
; 生命水冷却下拉框：0/5/10 是分钟数，「不使用」等于关掉生命水。
; 默认选 0（不设冷却，和没有这个框时一样），每次打开脚本都回到 0，不存配置。
; 勾上勾选框才显示下拉框和「分钟」两个字，不勾就藏起来（默认不勾，所以先藏）。
ddlLifeWater := MyGui.Add("DropDownList", "x285 y35 w55 r4", ["0", "5", "10", "不使用"])
ddlLifeWater.Value := 1
txtLifeWaterUnit := MyGui.Add("Text", "x345 y42 w28", "分钟")
ddlLifeWater.Visible := false
txtLifeWaterUnit.Visible := false
txtDesktopStatus := MyGui.Add("Text", "x10 y70 w360", "状态：未运行")
MyGui.Add("Text", "x10 y90 w392 h2 +0x1000")

; ---- 功能 2：开箱子（两点点击 + 右键点击）----
; 坐标不用手输数字：点下面三个取点按钮，窗口会最小化，
; 把鼠标移到要记录的位置按 F12 取点（有「取点成功」提示），
; 按 Esc 取消。取到的坐标不显示在界面上。
MyGui.Add("Text", "x10 y100 w360", "2. 开箱子 (F12)")
MyGui.SetFont("s9")
btnCapRight := MyGui.Add("Button", "x10 y122 w126 h30", "箱子位置取点F12")
btnCapRight.OnEvent("Click", (*) => CapturePos(3))
btnCapP1 := MyGui.Add("Button", "x143 y122 w126 h30", "自动放入取点F12")
btnCapP1.OnEvent("Click", (*) => CapturePos(1))
btnCapP2 := MyGui.Add("Button", "x276 y122 w126 h30", "开始精炼取点F12")
btnCapP2.OnEvent("Click", (*) => CapturePos(2))
MyGui.SetFont("s10")
btnBoth := MyGui.Add("Button", "x10 y158 w170 h30", "两种点击同时操作")
btnBoth.OnEvent("Click", MinimizeAndRun(ToggleBoth))
btnRightOnly := MyGui.Add("Button", "x188 y158 w104 h30", "抽奖")
btnRightOnly.OnEvent("Click", MinimizeAndRun(ToggleRightOnly))
btnSynth := MyGui.Add("Button", "x298 y158 w104 h30", "合成")
btnSynth.OnEvent("Click", MinimizeAndRun(ToggleSynth))
txtClickStatus := MyGui.Add("Text", "x10 y193 w360", "状态：未运行")
MyGui.Add("Text", "x10 y213 w392 h2 +0x1000")

; ---- 3. 快捷切换桌面 ----
MyGui.Add("Text", "x10 y223 w360", "3. 快捷切换桌面 (~)")
btnQuickStart := MyGui.Add("Button", "x10 y248 w191 h30", "开始：快捷切换")
btnQuickStart.OnEvent("Click", MinimizeAndRun(StartQuickSwitch))
btnQuickStop := MyGui.Add("Button", "x211 y248 w191 h30", "停止")
btnQuickStop.OnEvent("Click", MinimizeAndRun(StopQuickSwitch))
btnQuickStop.Enabled := false
txtQuickStatus := MyGui.Add("Text", "x10 y288 w360", "状态：未录制")

; ---- 已保存的录制 ----
; 录制存在脚本目录下的 records 文件夹里，一个录制一个文件，文件名就是录制的名字。
; 下拉框里可以直接输新名字（点保存就是存成这个名字），也可以选已有的名字（点读取、删除）。
MyGui.Add("Text", "x10 y313 w360", "已保存的录制")
cmbRecords := MyGui.Add("ComboBox", "x10 y338 w190", [])
btnSaveRecord := MyGui.Add("Button", "x208 y338 w60 h30", "保存")
btnSaveRecord.OnEvent("Click", MinimizeAndRun(SaveRecord))
btnLoadRecord := MyGui.Add("Button", "x274 y338 w60 h30", "读取")
btnLoadRecord.OnEvent("Click", MinimizeAndRun(LoadRecord))
btnDeleteRecord := MyGui.Add("Button", "x340 y338 w60 h30", "删除")
btnDeleteRecord.OnEvent("Click", MinimizeAndRun(DeleteRecord))
MyGui.Add("Text", "x10 y378 w392 h2 +0x1000")

; ---- 4. 账号登陆 ----
; 三个短选择框和新增/登陆/删除三个按钮在同一排（和最早的单框版式一样）：
; 一个框管一个桌面，框下面分别标注桌面1/2/3。每个框里是 accounts
; 文件夹里已保存的账号（只能选、不能输），最后一行是空行，选空行 =
; 这个桌面不登陆。点「登陆」按桌面 1→2→3 依次登陆选了账号的桌面。
; 新增账号走「新增」按钮弹的对话框（账号、密码、二次密码都在对话框
; 里填）；「删除」删的是桌面1框里选中的账号。账号名最长 6 个字符，
; 三个框各 w68 正好显示全（w60 时最后一个字符显示不下，她定的）；
; 三个按钮合起来宽约 170，和功能 3 的录制框一样宽。窗口配合加宽
; 到 412（原 380），上面三个部分也相应略宽，整体匀称。
MyGui.Add("Text", "x10 y388 w360", "4. 账号登陆（无快捷键）")
cmbAcc1 := MyGui.Add("DropDownList", "x10 y413 w68 r35", [])
cmbAcc2 := MyGui.Add("DropDownList", "x82 y413 w68 r35", [])
cmbAcc3 := MyGui.Add("DropDownList", "x154 y413 w68 r35", [])
SendMessage(0x1701, 35, 0, cmbAcc1)  ; CB_SETMINVISIBLE：弹出列表一次显示 35 行，不用滚动
SendMessage(0x1701, 35, 0, cmbAcc2)
SendMessage(0x1701, 35, 0, cmbAcc3)
MyGui.Add("Text", "x10 y445 w68 +Center", "桌面1")
MyGui.Add("Text", "x82 y445 w68 +Center", "桌面2")
MyGui.Add("Text", "x154 y445 w68 +Center", "桌面3")
btnAddAccount := MyGui.Add("Button", "x227 y413 w55 h30", "新增")
btnAddAccount.OnEvent("Click", AddAccount)
btnLogin := MyGui.Add("Button", "x286 y413 w55 h30", "登陆")
btnLogin.OnEvent("Click", MinimizeAndRun(LoginAccount))
btnDeleteAccount := MyGui.Add("Button", "x345 y413 w55 h30", "删除")
btnDeleteAccount.OnEvent("Click", MinimizeAndRun(DeleteAccount))
; 更新结果就显示在这一行（平时空着）：点底部「更新」后显示几秒，然后自动消失。
; 功能 4 原来的「状态：未登陆」一行 2026-11-06 按她要求去掉，登陆进度改记到日志。
txtUpdateStatus := MyGui.Add("Text", "x10 y469 w392", "")
MyGui.Add("Text", "x10 y493 w392 h2 +0x1000")

; ---- 底部 ----
btnStopAll := MyGui.Add("Button", "x10 y503 w72 h30", "全部停止")
btnStopAll.OnEvent("Click", MinimizeAndRun(StopAll))
btnSaveConfig := MyGui.Add("Button", "x90 y503 w72 h30", "保存配置")
btnSaveConfig.OnEvent("Click", MinimizeAndRun(SaveConfig))
btnHelp := MyGui.Add("Button", "x170 y503 w72 h30", "使用说明")
btnHelp.OnEvent("Click", ToggleHelp)
; 「更新」不包 MinimizeAndRun：点了要留在窗口上看更新结果那一行。
btnUpdate := MyGui.Add("Button", "x250 y503 w72 h30", "更新")
btnUpdate.OnEvent("Click", CheckForUpdate)
btnExit := MyGui.Add("Button", "x330 y503 w72 h30", "退出")
btnExit.OnEvent("Click", (*) => ExitApp())
; 使用说明面板（窗口右侧，平时藏着，点「使用说明」才展开显示）。
txtHelp := MyGui.Add("Edit", "x422 y10 w300 h536 +ReadOnly +Multi +VScroll", HelpText)
txtHelp.Visible := false
MyGui.OnEvent("Close", (*) => ExitApp())

; 最小化时藏到托盘：任务栏不显示，只剩右下角托盘图标。
; 点一下托盘图标（或右键菜单「显示窗口」）就恢复窗口。
MyGui.OnEvent("Size", GuiOnSize)
GuiOnSize(GuiObj, MinMax, Width, Height) {
    if (MinMax = -1) {
        GuiObj.Hide()
    }
}
A_TrayMenu.Add("显示窗口", (*) => MyGui.Show())
A_TrayMenu.Default := "显示窗口"
OnMessage(0x404, TrayIconClick)
TrayIconClick(wParam, lParam, Msg, Hwnd) {
    ; 0x202 = 左键松开（单击托盘图标）
    if (lParam = 0x202) {
        MyGui.Show()
    }
}

; DLL 没加载成功时，禁用功能 1 和快捷切换，不影响功能 2
if (DesktopCount < 1) {
    btnDesktop.Enabled := false
    btnQuickStart.Enabled := false
    txtDesktopStatus.Text := "状态：不可用（DLL 加载失败，请检查同目录的 VirtualDesktopAccessor.dll）"
}

RefreshRecordList()
RefreshAccountList()

MyGui.Show("w412 h556")

; 打开脚本时默认开启功能 3（快捷切换）：和点「开始」按钮走
; 同一条路，开启后 2 秒还会把三个桌面的游戏窗口居中。
; DLL 加载失败时不开启（开始按钮已被禁用，功能也用不了）。
if (DesktopCount >= 1) {
    StartQuickSwitch()
}

; ===== 功能 1：桌面轮询 =====
; F11 或点按钮启动：一直轮询，直到再按 F11 或再点按钮停掉。
; 轮询时每轮按 F；放映机图标在，才按 X（桌面1不按 X）；放映机图标在、
; 并且状态图标是暗色，才点状态图标一下，尝试变亮色；未知图标不点。
; 三个功能互斥：同一时间只能跑一个。启动哪个功能，就先停掉另外两个；
; 以后加新功能也按这个规矩——启动时停掉其他所有功能。
StopDesktopPolling() {
    global DesktopRunning, CyclePhase, txtDesktopStatus
    if (!DesktopRunning) {
        return
    }
    DesktopRunning := false
    CyclePhase := ""
    SetTimer(StepDesktop, 0)
    txtDesktopStatus.Text := "状态：已停止"
}

ToggleDesktop(*) {
    global DesktopRunning, DesktopPhase, DesktopWaitMs, DesktopKey, SwitchClickX, SwitchClickY
    global txtDesktopStatus
    global CfgDesktopWait, CfgDesktopKey, CfgSwitchX, CfgSwitchY
    global CyclePhase, CycleCount, DesktopNext, CurrentDesktop, DesktopCount, PollDesktopCount
    global CalStatusX, CalStatusY, CalProjX, CalProjY
    global ProjPrevYes, ProjYesTick
    if (DesktopRunning) {
        StopDesktopPolling()
        ToolTip()
        return
    }
    ; 启动轮询前先停掉另外两个功能（开箱子、快捷切换）。
    StopClickLoops()
    StopQuickSwitch()
    ; 轮询参数不用界面填，直接用代码里写死的值（间隔 1000 毫秒、
    ; 按键 f、切换后点 (212,57)）。
    DesktopWaitMs := Integer(CfgDesktopWait)
    DesktopKey := CfgDesktopKey
    SwitchClickX := Integer(CfgSwitchX)
    SwitchClickY := Integer(CfgSwitchY)
    DesktopRunning := true
    CycleCount++
    ; 轮询只跑前 3 个桌面（她 2026-11-09 定的）：桌面再多也只轮
    ; 前 3 个，第 4 个起不去；不足 3 个就按实际个数跑。桌面总数
    ; DesktopCount 还是 DLL 读到的真实个数（登陆那边要用它做
    ; 边界检查），不动，只另算一个轮询专用的个数。
    PollDesktopCount := Min(DesktopCount, 3)
    LogFind("polling: start, " DesktopCount " desktops total, polling first " PollDesktopCount)
    ; 各桌面图标位置清零（0 表示还没找到，第一次全窗口找，找到就记下来）。
    CalStatusX := []
    CalStatusY := []
    CalProjX := []
    CalProjY := []
    Loop PollDesktopCount {
        CalStatusX.Push(0)
        CalStatusY.Push(0)
        CalProjX.Push(0)
        CalProjY.Push(0)
    }
    DesktopNext := 0
    CurrentDesktop := 0
    ; 暗色点击有效期重新观察：放映机上次状态和计时起点都清零，
    ; 第一次看到放映机在就算它刚变在、窗口从那一刻起算 15 秒。
    ProjPrevYes := [false, false, false]
    ProjYesTick := [0, 0, 0]
    StartCyclePhase("main")
    StepDesktop()
}

; 开始轮询：从桌面 1 重新开始。
StartCyclePhase(NewPhase) {
    global CyclePhase, DesktopPhase, DesktopNext, CurrentDesktop
    global txtDesktopStatus
    CyclePhase := NewPhase
    DesktopPhase := "switch"
    DesktopNext := 0
    CurrentDesktop := 0
    ToolTip()
    txtDesktopStatus.Text := "状态：轮询中（放映机图标在才按 X，桌面1不按 X，暗色才点状态图标，未知不点，只轮询前3个桌面）"
}

; 把一次找到的结果记到脚本同目录的 fenix_Find_Log.txt，
; 方便查为什么会认错（坐标和找到哪个图案都在里面）。
LogFind(Msg) {
    try {
        FileAppend(Format("{:02d}:{:02d}:{:02d} ", A_Hour, A_Min, A_Sec) . Msg . "`n", A_ScriptDir . "\fenix_Find_Log.txt", "UTF-8")
    } catch {
    }
}

; 在指定矩形里用 FindText 找一个图案：找到返回 true，CX/CY 是
; 图案中心（FindText 直接返回图案中心，点图标用的就是这个
; 坐标）；没找到返回 false。坐标会夹到屏幕内，FindText 报错
; （如图案写错）时当没找到处理。
FindPattern(Text, X1, Y1, X2, Y2, &CX, &CY, E1 := "", E0 := "") {
    global FindErr1, FindErr0
    if (E1 = "") {
        E1 := FindErr1
    }
    if (E0 = "") {
        E0 := FindErr0
    }
    CX := 0
    CY := 0
    if (X1 < 0) {
        X1 := 0
    }
    if (Y1 < 0) {
        Y1 := 0
    }
    if (X2 > A_ScreenWidth) {
        X2 := A_ScreenWidth
    }
    if (Y2 > A_ScreenHeight) {
        Y2 := A_ScreenHeight
    }
    FX := 0
    FY := 0
    try {
        if (FindText(&FX, &FY, X1, Y1, X2, Y2, E1, E0, Text).Length) {
            CX := FX
            CY := FY
            return true
        }
    } catch {
    }
    return false
}

; 找一个图标：图标位置不会变，所以没记下位置时（每次刚启动
; 轮询时）全屏找一次，找到后调用方把位置记在内存里；以后只在
; 记下位置附近找（中心 ±60/±200），不再放大到全屏——附近没找到
; 就是没找到。纵向原来是 ±50，2026-11-06 放宽到 ±200：放映机
; 位置曾被记偏 110px，±50 够不着真位置、连漏了 5 分钟。
; 找到返回 true，OutX/OutY 是图标中心。
FindIcon(Pattern, RecX, RecY, &OutX, &OutY, E1 := "", E0 := "") {
    OutX := 0
    OutY := 0
    if (RecX != 0) {
        return FindPattern(Pattern, RecX - 60, RecY - 200, RecX + 60, RecY + 200, &OutX, &OutY, E1, E0)
    }
    return FindPattern(Pattern, 0, 0, A_ScreenWidth, A_ScreenHeight, &OutX, &OutY, E1, E0)
}

; 找放映机图标（Idx 是桌面序号，从 1 开始）。
FindProjector(Idx, &OutX, &OutY) {
    global ProjectorText, ProjectorTextOld, ProjErr1, ProjErr0, CalProjX, CalProjY
    RX := (Idx >= 1 && Idx <= CalProjX.Length) ? CalProjX[Idx] : 0
    RY := (Idx >= 1 && Idx <= CalProjY.Length) ? CalProjY[Idx] : 0
    Found := FindIcon(ProjectorText, RX, RY, &OutX, &OutY, ProjErr1, ProjErr0)
    if (Found) {
        CalProjX[Idx] := OutX
        CalProjY[Idx] := OutY
        LogFind("D" . Idx . " projector FOUND (" . OutX . "," . OutY . ")")
        return true
    }
    Found := FindIcon(ProjectorTextOld, RX, RY, &OutX, &OutY, ProjErr1, ProjErr0)
    if (Found) {
        CalProjX[Idx] := OutX
        CalProjY[Idx] := OutY
        LogFind("D" . Idx . " projector (old size) FOUND (" . OutX . "," . OutY . ")")
    }
    return Found
}

; 在图标中心附近取一个 5x5 网格点的亮度，亮点（灰度>120）占一半
; 以上才是真亮色。亮版底色是浅蓝（亮点约 88%），暗版底色是
; 深紫（亮点约 16%，顶上有亮边的那张约 32%）。用亮点比例而
; 不用平均值，单个点落在剑上、数字上、亮边上都不会翻盘。
IconBright(CX, CY) {
    Bright := 0
    N := 0
    for DY in [-10, -5, 0, 5, 10] {
        for DX in [-16, -8, 0, 8, 16] {
            try {
                C := PixelGetColor(CX + DX, CY + DY)
                R := (C >> 16) & 0xFF
                G := (C >> 8) & 0xFF
                B := C & 0xFF
                if ((R * 38 + G * 75 + B * 15) // 128 > 120) {
                    Bright++
                }
                N++
            } catch {
            }
        }
    }
    if (N = 0) {
        return false
    }
    Frac := Bright / N
    LogFind("brightness at (" CX "," CY ") bright " Bright "/" N " = " Round(Frac, 2))
    return (Frac > 0.5)
}

; 点状态图标：先模拟人工操作，在图标内部小范围移动鼠标，第三次移动
; 到位置时点下去（让点击像人工移动中顺手点的一下），再继续移动两次，
; 然后把鼠标移到左边的横向黄金分割点（屏幕宽度的 0.382 倍、高 200），
; 免得鼠标挡住图标、影响下次识别。
ClickStatusIcon(IconX, IconY) {
    global CurrentDesktop
    Loop 5 {
        MX := IconX + Random(-18, 18)
        MY := IconY + Random(-14, 14)
        MouseMove(MX, MY, 0)
        if (A_Index = 3) {
            LogFind("D" (CurrentDesktop + 1) " CLICK status icon at (" MX "," MY ") (3rd jitter move)")
            Click(MX, MY)
        }
        Sleep(100)
    }
    MouseMove(Round(A_ScreenWidth * 0.382), 200, 5)
    ; 点完多等 0.5 秒再走：切桌面卡顿时，点下去的输入可能还没处理完，
    ; 马上切桌面会把这次点击带到新桌面上去，点到新桌面相同位置的按钮。
    Sleep(500)
}

; 找亮版状态图标（只用来定位亮色图标的位置、记下坐标，不参与
; 亮暗判断）：找到亮版图案，还要用背景亮度再确认一次是真亮色
; （亮版底色浅蓝，暗版底色深紫）。图案认错的时候（比如暗版图标
; 顶上有亮边），亮度会把它拦下来，当没找到。
FindBright(Idx, &OutX, &OutY) {
    global BrightText, CalStatusX, CalStatusY, IconErr1, IconErr0
    RX := (Idx >= 1 && Idx <= CalStatusX.Length) ? CalStatusX[Idx] : 0
    RY := (Idx >= 1 && Idx <= CalStatusY.Length) ? CalStatusY[Idx] : 0
    Found := FindIcon(BrightText, RX, RY, &OutX, &OutY, IconErr1, IconErr0)
    if (!Found) {
        return false
    }
    if (!IconBright(OutX, OutY)) {
        LogFind("D" . Idx . " icon bright pattern found at (" . OutX . "," . OutY . ") but brightness says dark, treat as not found")
        return false
    }
    CalStatusX[Idx] := OutX
    CalStatusY[Idx] := OutY
    LogFind("D" . Idx . " icon bright FOUND (" . OutX . "," . OutY . ")")
    return true
}

; 找暗版图标的两条长条（图案说明在 DarkStripLText 那里）：先找
; 左条，对每个候选再在它右边 29px 处找右条（偏差 5px 以内算
; 对上），两条都对上才算找到，返回两条中心的中间点当图标中心。
; 搜索窗口和 FindIcon 一样的规矩：记过位置就只在附近找（左条
; 中心按图标中心左移 15 估算，窗口 ±60/±200），没记过全屏找一次。
FindDarkPair(RecX, RecY, &OutX, &OutY) {
    global DarkStripLText, DarkStripRText, DarkStripDx, IconErr1, IconErr0
    OutX := 0
    OutY := 0
    if (RecX != 0) {
        X1 := RecX - 15 - 60
        Y1 := RecY - 200
        X2 := RecX - 15 + 60
        Y2 := RecY + 200
    } else {
        X1 := 0
        Y1 := 0
        X2 := A_ScreenWidth
        Y2 := A_ScreenHeight
    }
    FX := 0
    FY := 0
    Matches := ""
    try Matches := FindText(&FX, &FY, X1, Y1, X2, Y2, IconErr1, IconErr0, DarkStripLText)
    if (!IsObject(Matches)) {
        return false
    }
    Tried := 0
    for _, M in Matches {
        Tried++
        if (Tried > 10) {
            break
        }
        LCX := M.mx
        LCY := M.my
        EX := LCX + DarkStripDx
        RCX := 0
        RCY := 0
        if (!FindPattern(DarkStripRText, EX - 13, LCY - 26, EX + 13, LCY + 26, &RCX, &RCY, IconErr1, IconErr0)) {
            continue
        }
        if (Abs(RCX - EX) > 5 || Abs(RCY - LCY) > 5) {
            continue
        }
        OutX := Round((LCX + RCX) / 2)
        OutY := Round((LCY + RCY) / 2)
        return true
    }
    return false
}

; 找暗版状态图标（判断暗色用）：左右两条长条都对上，还要用背景
; 亮度再确认一次是真暗色（暗版底色深紫，亮版底色浅蓝）。图案认错
; 的时候，亮度会把它拦下来，当非暗色（亮色）。
FindDark(Idx, &OutX, &OutY) {
    global CalStatusX, CalStatusY
    RX := (Idx >= 1 && Idx <= CalStatusX.Length) ? CalStatusX[Idx] : 0
    RY := (Idx >= 1 && Idx <= CalStatusY.Length) ? CalStatusY[Idx] : 0
    Found := FindDarkPair(RX, RY, &OutX, &OutY)
    if (!Found) {
        return false
    }
    if (IconBright(OutX, OutY)) {
        LogFind("D" . Idx . " icon dark pattern found at (" . OutX . "," . OutY . ") but brightness says bright, treat as non-dark")
        return false
    }
    CalStatusX[Idx] := OutX
    CalStatusY[Idx] := OutY
    LogFind("D" . Idx . " icon dark FOUND (" . OutX . "," . OutY . ")")
    return true
}

; 找未知状态图标（判断未知用）：就是那张全黑、剑也是黑的、只有边框是亮的
; 交叉双剑图标（46x41，阈值 82，从你发的截图整个图标转的）。它和亮版、
; 暗版图案都认不到对方（交叉验证过），所以图案本身就够了，不用再验亮度。
; 找到返回 true，OutX/OutY 是图标中心。未知图标不点，只按 F 和 X。
FindUnknown(Idx, &OutX, &OutY) {
    global UnknownText, CalStatusX, CalStatusY, IconErr1, IconErr0
    RX := (Idx >= 1 && Idx <= CalStatusX.Length) ? CalStatusX[Idx] : 0
    RY := (Idx >= 1 && Idx <= CalStatusY.Length) ? CalStatusY[Idx] : 0
    Found := FindIcon(UnknownText, RX, RY, &OutX, &OutY, IconErr1, IconErr0)
    if (Found) {
        CalStatusX[Idx] := OutX
        CalStatusY[Idx] := OutY
        LogFind("D" . Idx . " icon unknown FOUND (" . OutX . "," . OutY . ")")
    }
    return Found
}

; 记下刚激活的游戏窗口的位置和大小，后面找图标只在这个窗口里面找。
SaveGameWinRect(hWnd) {
    global GameWinX, GameWinY, GameWinW, GameWinH
    try {
        WinGetPos(&X, &Y, &W, &H, "ahk_id " hWnd)
        GameWinX := X
        GameWinY := Y
        GameWinW := W
        GameWinH := H
    } catch {
    }
}

; 按窗口标题激活当前桌面上的游戏窗口：标题是 "Atlantica Online Fenix"，
; 三个桌面标题都一样，但每个桌面只有一个游戏窗口；用 DLL 的
; IsWindowOnCurrentVirtualDesktop 挑出当前桌面上的那一个激活它，
; 不会切到别的桌面去。找到就返回 true，没找到返回 false。
ActivateGameByTitle() {
    global GameTitle, IsWindowOnCurrentVirtualDesktopProc
    if (!IsWindowOnCurrentVirtualDesktopProc) {
        return false
    }
    try {
        WinList := WinGetList(GameTitle)
    } catch {
        return false
    }
    for hWnd in WinList {
        try {
            OnCurrent := DllCall(IsWindowOnCurrentVirtualDesktopProc, "Ptr", hWnd, "Int")
        } catch {
            continue
        }
        if (OnCurrent) {
            try {
                WinActivate("ahk_id " hWnd)
                SaveGameWinRect(hWnd)
                LogFind("activated game window by title, hwnd=" hWnd)
                return true
            } catch {
                return false
            }
        }
    }
    return false
}

; 在当前桌面找一个游戏图标（只为激活窗口定位用，标题找不到时才用）：
; 先试放映机图标，再试暗版状态图标，最后试亮版状态图标。
; 找到返回 true，OutX/OutY 是图标中心。
; 哪个图标都行，只要在游戏窗口上，能定位到窗口就行。
FindGameIcon(Idx, &OutX, &OutY) {
    if (FindProjector(Idx, &OutX, &OutY)) {
        return true
    }
    if (FindDark(Idx, &OutX, &OutY)) {
        return true
    }
    if (FindUnknown(Idx, &OutX, &OutY)) {
        return true
    }
    if (FindBright(Idx, &OutX, &OutY)) {
        return true
    }
    return false
}

; 把图标所在位置的窗口激活（标题找不到时才用这个办法）。
; 做法：鼠标移到图标上，取鼠标下的窗口，激活它。
; 图标在当前桌面上，所以图标位置的窗口一定是当前这个桌面的游戏窗口。
; 找到窗口就返回 true，没找到返回 false（找不到就照旧用点击来聚焦）。
ActivateGameWindow(IconX, IconY) {
    if (IconX = 0 || IconY = 0) {
        return false
    }
    WinID := 0
    try {
        MouseMove(IconX, IconY)
        Sleep(50)
        MouseGetPos(, , &WinID)
        if (WinID) {
            WinActivate("ahk_id " WinID)
            SaveGameWinRect(WinID)
            LogFind("activated game window at (" IconX "," IconY ") hwnd=" WinID)
            return true
        }
    } catch {
    }
    return false
}



; 轮询主循环：一个定时器驱动的状态机，每步做完再约下一步。
; 每轮：切桌面 -> 停 0.5 秒 -> 激活游戏窗口（先按标题找，找不到再用图标位置）
; 激活成功就直接去检查（左上角那两下点击本来就是为了聚焦，激活成功就没意义了）；
; 激活失败才点 (212,57) -> 停 0.5 秒 -> 原地点一下 -> 等 1000 毫秒 -> 检查放映机图标和状态图标
; （放映机图标在、并且是非暗色，就只按 X、不按 F；其他情况
; 按 F，放映机图标在才在约 0.05 秒后按 X；放映机图标在、
; 状态图标是暗色，才点状态图标）。
; 切到指定桌面，并且等切换真正完成（当前桌面号变成目标桌面）再返回。
; 切桌面卡顿时，只等固定时间可能不够，后面的找图标会读到上一个桌面
; 的画面，坐标记错、点错地方。最多等 2 秒，超时也继续往下走。
GoToDesktopAndWait(DesktopNum) {
    global GoToDesktopNumberProc, GetCurrentDesktopNumberProc
    try {
        DllCall(GoToDesktopNumberProc, "Int", DesktopNum)
    } catch {
        return
    }
    if (!GetCurrentDesktopNumberProc) {
        return
    }
    Start := A_TickCount
    Loop {
        try {
            Cur := DllCall(GetCurrentDesktopNumberProc, "Int")
        } catch {
            break
        }
        if (Cur = DesktopNum) {
            break
        }
        if (A_TickCount - Start > 2000) {
            break
        }
        Sleep(100)
    }
}

; 读当前桌面号（0 起：桌面1 = 0、桌面2 = 1、桌面3 = 2）；
; DLL 没加载好或调用失败返回 -1（表示读不到、没法核对）。
CurrentDesktopNum() {
    global GetCurrentDesktopNumberProc
    if (!GetCurrentDesktopNumberProc) {
        return -1
    }
    try {
        return DllCall(GetCurrentDesktopNumberProc, "Int")
    } catch {
        return -1
    }
}

StepDesktop() {
    global DesktopRunning, CyclePhase, DesktopPhase, DesktopNext, CurrentDesktop
    global DesktopCount, PollDesktopCount, DesktopKey, KeyGapMs, GoToDesktopNumberProc, DesktopWaitMs, SwitchClickX, SwitchClickY
    global GameWinX, GameWinY, GameWinW, GameWinH
    global txtDesktopStatus
    if (!DesktopRunning) {
        return
    }
    if (DesktopPhase = "switch") {
        CurrentDesktop := DesktopNext
        GoToDesktopAndWait(CurrentDesktop)
        DesktopNext := Mod(DesktopNext + 1, PollDesktopCount)
        DesktopPhase := "activate"
        SetTimer(StepDesktop, 500)   ; 切换后先停 0.5 秒
    } else if (DesktopPhase = "activate") {
        ; 切完桌面先激活游戏窗口，这样后面的按 F/X 才进游戏，
        ; 不用再手动点窗口。先按标题找（每个桌面只有一个游戏窗口，
        ; 用 DLL 挑出当前桌面上的那一个），找不到再用图标位置找。
        ; 激活成功的话，左上角 (212,57) 那两下点击就没意义了（本来
        ; 就是为了聚焦窗口），直接去检查；激活失败才照旧用点击来聚焦。
        ; 先把上个桌面的窗口位置清掉：激活失败时找图标就全屏找，
        ; 不会拿着上个桌面的窗口位置去找这个桌面的图标。
        GameWinW := 0
        GameWinH := 0
        Activated := false
        if (ActivateGameByTitle()) {
            Activated := true
        } else {
            Idx := CurrentDesktop + 1
            IX := 0
            IY := 0
            if (FindGameIcon(Idx, &IX, &IY)) {
                if (ActivateGameWindow(IX, IY)) {
                    Activated := true
                }
            } else {
                LogFind("D" Idx " activate: no window found by title or icon, skip activation")
            }
        }
        if (Activated) {
            DesktopPhase := "check"
            SetTimer(StepDesktop, DesktopWaitMs)
        } else {
            DesktopPhase := "click212"
            SetTimer(StepDesktop, 100)   ; 激活失败，稍停一下再点
        }
    } else if (DesktopPhase = "click212") {
        LogFind("D" (CurrentDesktop + 1) " CLICK focus (212,57) after activation failed")
        Click(SwitchClickX, SwitchClickY)
        DesktopPhase := "click"
        SetTimer(StepDesktop, 500)   ; 点完再停 0.5 秒
    } else if (DesktopPhase = "click") {
        MouseGetPos(&CX, &CY)
        LogFind("D" (CurrentDesktop + 1) " CLICK focus at current pos (" CX "," CY ") after activation failed")
        Click()
        DesktopPhase := "check"
        SetTimer(StepDesktop, DesktopWaitMs)
    } else if (DesktopPhase = "check") {
        MainCheckStep()
    } else if (DesktopPhase = "pressX") {
        PressXStep()
    }
}

; 按 X 的总闸（2026-11-07 她定的新规矩）：桌面1永远不按 X，
; 只有桌面2、桌面3按 X。轮询里所有按 X 的地方都走这个函数，
; 改规矩只改这里。F、点状态图标、生命水在桌面1都照常，不受影响。
; 返回 true = 真的按了；false = 是桌面1，没按。
PressPollX(Idx) {
    global DesktopKey2
    if (Idx = 1) {
        return false
    }
    Send(DesktopKey2)
    return true
}

; 轮询检查：每轮到一个桌面就先找状态图标、最后找放映机图标
; （放映机在不在是点不点、按不按 X 的判断底子，最后搜最新），
; 再按下面规则做。三种状态：暗色（暗版图案找到）、未知
; （未知图案找到）、非暗色（亮版图案找到）；都没找到就是
; 状态没找到（not found）。
; 桌面1永远不按 X：下面规则里说按 X 的地方，桌面1都跳过
; （走 PressPollX 总闸）；F、点图标、生命水在桌面1照常。
;   1. 放映机图标在、并且是非暗色：只按 X，不按 F，不点。
;   2. 未知：按 F；放映机图标在，才在约 0.05 秒后按 X；不点图标。
;   3. 暗色 + 放映机在：发现就马上点状态图标一下（在按 F 之前点），
;      点之前先复检一次放映机图标（搜状态图标期间它可能刚消失），
;      复检不在就不点；点完再判断一次：变非暗色就只按 X、不按 F；
;      还是暗色就按 F，再在约 0.05 秒后按 X。
;      放映机不在的暗色：不点，只按 F。
;      点击还有 15 秒有效期：放映机由不在变在才开始计时，这个
;      桌面连续「在」超过 15 秒后，就算找到暗色也不点（F、X
;      照常）；放映机变不在再变在，重新计时。见 NoteProjectorVisit。
;   4. 状态没找到：按 F；放映机图标在，才在约 0.05 秒后按 X；不点。
;   5. 女神的生命水（勾选框勾上才生效，本轮动作做完后判断一次）：
;      放映机不在、且这个桌面还没记过已使用，就按 F9 并记已使用；
;      放映机在，就把标记改回未使用。勾选框右边的下拉框选了
;      5/10 分钟时，按过 F9 的桌面冷却这么久，时间到了、
;      放映机还是不在就再按一次 F9；选 0 不设冷却，选「不使用」
;      等于没勾。见 ApplyLifeWaterRule。
MainCheckStep() {
    global CurrentDesktop, DesktopPhase, DesktopWaitMs, DesktopKey, KeyGapMs
    global CheckProjFound, CheckStatusNotFound
    Idx := CurrentDesktop + 1
    ; 先搜状态图标，最后搜放映机图标：放映机在不在是这一轮
    ; 点不点、按不按 X 的判断底子，放在最后搜，它最新。
    DX := 0
    DY := 0
    DarkFound := FindDark(Idx, &DX, &DY)
    UnknownFound := false
    BrightFound := false
    BX := 0
    BY := 0
    if (!DarkFound) {
        UX := 0
        UY := 0
        UnknownFound := FindUnknown(Idx, &UX, &UY)
        if (!UnknownFound) {
            ; 非暗色也不是未知：找一下亮版图案，确认是亮色。
            BrightFound := FindBright(Idx, &BX, &BY)
        }
    }
    CheckStatusNotFound := (!DarkFound && !UnknownFound && !BrightFound)
    PX := 0
    PY := 0
    ProjFound := FindProjector(Idx, &PX, &PY)
    CheckProjFound := ProjFound
    NoteProjectorVisit(Idx)
    ; 暗色 + 放映机在：发现就马上点（按 F 之前点，点的是这次刚找到的位置；
    ; 按 F 可能过图，等 0.05 秒后再点位置就变了）。
    ; 点之前先复检一次放映机图标：搜状态图标期间它可能刚消失，
    ; 复检不在就不点（规则：放映机不在不能点），并把复检结果刷给
    ; CheckProjFound，后面按不按 X 也按复检结果来。
    ; 点完再判断一次：点完变成非暗色（亮色）就不按 F 了（只按 X）；
    ; 还是暗色就照常往下按 F。
    if (ProjFound && DarkFound) {
        if (!DarkClickInWindow(Idx)) {
            ; 15 秒有效期已过（放映机连续在太久）：不点了，
            ; 其余照常往下走（按 F，pressX 步按 X）。
            LogFind("D" Idx " projwin: dark found but 15s click window expired, no click")
            ToolTip("Desktop " Idx ": projector yes, dark, click window expired, no click")
        } else {
        PX2 := 0
        PY2 := 0
        ProjFound := FindProjector(Idx, &PX2, &PY2)
        CheckProjFound := ProjFound
        if (!ProjFound) {
            LogFind("D" Idx " dark found but projector gone at pre-click re-check, click skipped")
            ToolTip("Desktop " Idx ": dark, projector gone at re-check, no click")
        } else {
            ClickStatusIcon(DX, DY)
            LogFind("D" Idx " dark found, clicked immediately")
            ToolTip("Desktop " Idx ": projector yes, dark, clicked immediately")
            ; 点完重新找一次状态，判断现在是不是非暗色（亮色）。
            DX2 := 0
            DY2 := 0
            StillDark := FindDark(Idx, &DX2, &DY2)
            NowBright := false
            if (!StillDark) {
                UX2 := 0
                UY2 := 0
                if (!FindUnknown(Idx, &UX2, &UY2)) {
                    BX2 := 0
                    BY2 := 0
                    NowBright := FindBright(Idx, &BX2, &BY2)
                }
            }
            if (NowBright) {
                ; 点完变非暗色：只按 X，不按 F（桌面1不按 X：两个都不按）。
                Pressed := PressPollX(Idx)
                LogFind("D" Idx " dark clicked, now non-dark, " (Pressed ? "X only, no F" : "no X (D1), no F"))
                ToolTip("Desktop " Idx ": dark clicked, now non-dark, " (Pressed ? "X only, no F" : "no X (D1), no F"))
                ApplyLifeWaterRule(Idx)
                DesktopPhase := "switch"
                SetTimer(StepDesktop, DesktopWaitMs)
                return
            }
            LogFind("D" Idx " dark clicked, still dark, press F")
        }
        }
    }
    if (ProjFound && !DarkFound && !UnknownFound && !CheckStatusNotFound) {
        ; 放映机图标在、并且是非暗色（亮色）：只按 X，不按 F，不点（桌面1不按 X）。
        Pressed := PressPollX(Idx)
        ToolTip("Desktop " Idx ": projector yes, non-dark, " (Pressed ? "X only, no F, no click" : "no X (D1), no F, no click"))
        ApplyLifeWaterRule(Idx)
        DesktopPhase := "switch"
        SetTimer(StepDesktop, DesktopWaitMs)
        return
    }
    ; 暗色、未知、状态没找到：按 F，约 0.05 秒后到 pressX 步（放映机图标在才按 X）。
    Send(DesktopKey)
    DesktopPhase := "pressX"
    SetTimer(StepDesktop, KeyGapMs)
}

; 暗色点击的 15 秒有效期记账：每轮检查的放映机结果定下来后
; 调一次。放映机由不在变在（上次记的是不在、这次在），从
; 这一刻开始计时；这次不在，就把起点清零。三个桌面各记各的。
; 每次启动轮询时在 ToggleDesktop 里清零重记：第一次看到放映机
; 在，就当它刚变在、窗口从那一刻起算。
NoteProjectorVisit(Idx) {
    global ProjPrevYes, ProjYesTick, CheckProjFound
    while (ProjPrevYes.Length < Idx) {
        ProjPrevYes.Push(false)
        ProjYesTick.Push(0)
    }
    if (CheckProjFound) {
        if (!ProjPrevYes[Idx]) {
            ProjYesTick[Idx] := A_TickCount
            LogFind("D" Idx " projwin: projector no -> yes, 15s dark-click window started")
        }
    } else {
        ProjYesTick[Idx] := 0
    }
    ProjPrevYes[Idx] := CheckProjFound
}

; 暗色点击还在不在有效期内：这个桌面放映机连续在、且从
; 变在的那一刻起没超过 15 秒，才返回 true。
DarkClickInWindow(Idx) {
    global ProjYesTick, DarkClickWindowMs
    if (Idx > ProjYesTick.Length || ProjYesTick[Idx] = 0) {
        return false
    }
    return (A_TickCount - ProjYesTick[Idx] <= DarkClickWindowMs)
}

; 女神的生命水（功能 1 的附带规则，「使用女神的生命水」勾选框
; 勾上才生效；不勾，这个函数第一行就返回，什么都不做）：
; 本轮轮询到这个桌面，放映机图标不在、而且这个桌面还没记过
; 「已使用」，就按一下 F9（用一次生命水）并记成已使用；之后
; 再轮询到、放映机还是不在，标记不变、不再按；等轮询到这个
; 桌面放映机图标在了，就把标记改回未使用，下次不在时再按 F9。
; 三个桌面各记各的（LifeWaterUsed 下标 1..3）。标记只在这次
; 运行里记着，脚本重开就回到全未使用。
; 勾选框右边的下拉框是冷却分钟数（判断时现读）：
;   选 0：不设冷却，和没有这个下拉框时一样（就按上面标记走）。
;   选 5/10：冷却从按下 F9 的那一刻起算，这么多分钟内
;     不再考虑给它按 F9——放映机中途出现只清标记、清不掉冷却
;     计时；时间到了、放映机还是不在，就再按一次 F9 并重新计时。
;   选「不使用」：等于没勾勾选框，这个函数直接返回。
; 在本轮动作都做完、要切走之前调用（MainCheckStep 的两个提前
; 返回处和 PressXStep 的两个结尾处各调一次，每轮只会走到一处）。
; 勾上「使用女神的生命水」才显示冷却下拉框和「分钟」两个字，不勾就藏起来。
ToggleLifeWaterOptions(*) {
    global chkLifeWater, ddlLifeWater, txtLifeWaterUnit
    Show := chkLifeWater.Value ? true : false
    ddlLifeWater.Visible := Show
    txtLifeWaterUnit.Visible := Show
}

ApplyLifeWaterRule(Idx) {
    global chkLifeWater, ddlLifeWater, LifeWaterUsed, LifeWaterPressTick, CheckProjFound
    if (!chkLifeWater.Value) {
        return
    }
    SelText := ddlLifeWater.Text
    if (SelText = "不使用") {
        return
    }
    CooldownMin := Integer(SelText)   ; 0、5、10（分钟）
    while (LifeWaterUsed.Length < Idx) {
        LifeWaterUsed.Push(false)
        LifeWaterPressTick.Push(0)
    }
    if (CheckProjFound) {
        if (LifeWaterUsed[Idx]) {
            LifeWaterUsed[Idx] := false
            LogFind("D" Idx " lifewater: projector yes, mark cleared (unused)")
        }
        ; 注意：这里不清 LifeWaterPressTick。冷却从按下 F9 那一刻
        ; 起算，中途放映机出现只能清标记、不能把冷却计时清掉，
        ; 不然放映机闪一下（在/不在之间跳一次），冷却就失效了。
    } else if (CooldownMin > 0 && LifeWaterPressTick[Idx] > 0
        && (A_TickCount - LifeWaterPressTick[Idx] < CooldownMin * 60000)) {
        ; 还在冷却内：不管标记是什么，都不再考虑按 F9。
        return
    } else if (!LifeWaterUsed[Idx]) {
        Send("{F9}")
        LifeWaterUsed[Idx] := true
        LifeWaterPressTick[Idx] := A_TickCount
        LogFind("D" Idx " lifewater: projector no, pressed F9, marked used")
        ToolTip("Desktop " Idx ": projector no, pressed F9 (life water)")
    } else if (CooldownMin > 0) {
        ; 标记还是已使用、但冷却已经到了：再按一次，重新计时。
        Send("{F9}")
        LifeWaterPressTick[Idx] := A_TickCount
        LogFind("D" Idx " lifewater: cooldown " CooldownMin " min expired, pressed F9 again")
        ToolTip("Desktop " Idx ": life water cooldown expired, pressed F9 again")
    }
}

; 按 X（轮询检查的下一步，约 0.05 秒后）。
; 放映机图标在才按 X（桌面1不按，走 PressPollX 总闸）。暗色已经
; 在检查步发现就马上点过了，这里不再点；未知和状态没找到都不点。
PressXStep() {
    global CurrentDesktop, DesktopPhase, DesktopWaitMs, CheckProjFound
    Idx := CurrentDesktop + 1
    if (!CheckProjFound) {
        ; 放映机图标不在：不按 X（只按了 F）。
        ToolTip("Desktop " Idx ": projector no, no X")
        ApplyLifeWaterRule(Idx)
        DesktopPhase := "switch"
        SetTimer(StepDesktop, DesktopWaitMs)
        return
    }
    Pressed := PressPollX(Idx)   ; 放映机图标在，才按 X（桌面1不按）
    ToolTip("Desktop " Idx (Pressed ? ": projector yes, X pressed" : ": projector yes, no X (D1)"))
    ApplyLifeWaterRule(Idx)
    DesktopPhase := "switch"
    SetTimer(StepDesktop, DesktopWaitMs)
}


; ===== 功能 2：开箱子 =====
; 取点：点取点按钮后窗口最小化，把鼠标移到要记录的位置，
; 按 F12 取点（F12 热键里调 FinishCapture），按 Esc 取消。
; target: 1=自动放入(点 1)，2=开始精炼(点 2)，3=箱子位置(右键)。
CapturePos(target) {
    global MyGui, CaptureTarget
    CaptureTarget := target
    MyGui.Minimize()
    Sleep(300)
    ShowTempToolTip("把鼠标移到要记录的位置，按 F12 取点，按 Esc 取消")
}

FinishCapture() {
    global MyGui, CaptureTarget, CaptureTick
    global Point1X, Point1Y, Point2X, Point2Y, RightX, RightY
    MouseGetPos(&mx, &my)
    if (CaptureTarget = 1) {
        Point1X := mx
        Point1Y := my
    } else if (CaptureTarget = 2) {
        Point2X := mx
        Point2Y := my
    } else {
        RightX := mx
        RightY := my
    }
    CaptureTarget := 0
    CaptureTick := A_TickCount
    MyGui.Restore()
    ShowTempToolTip("取点成功")
}

CancelCapture() {
    global MyGui, CaptureTarget
    CaptureTarget := 0
    ToolTip()
    MyGui.Restore()
}

UpdateClickButtons() {
    global ClickMode, btnBoth, btnRightOnly, btnSynth, txtClickStatus
    if (ClickMode = "both") {
        btnBoth.Text := "停止：两种点击同时操作"
        btnRightOnly.Text := "抽奖"
        btnSynth.Text := "合成"
        txtClickStatus.Text := "状态：运行中（开箱子：两种点击同时）"
    } else if (ClickMode = "right") {
        btnBoth.Text := "两种点击同时操作"
        btnRightOnly.Text := "停止：抽奖"
        btnSynth.Text := "合成"
        txtClickStatus.Text := "状态：运行中（抽奖）"
    } else if (ClickMode = "two") {
        btnBoth.Text := "两种点击同时操作"
        btnRightOnly.Text := "抽奖"
        btnSynth.Text := "停止：合成"
        txtClickStatus.Text := "状态：运行中（合成：两点点击）"
    } else {
        btnBoth.Text := "两种点击同时操作"
        btnRightOnly.Text := "抽奖"
        btnSynth.Text := "合成"
        txtClickStatus.Text := "状态：未运行"
    }
}

StopClickLoops() {
    global TwoRunning, RightRunning, ClickMode
    TwoRunning := false
    RightRunning := false
    SetTimer(StepTwo, 0)
    SetTimer(StepRight, 0)
    ClickMode := ""
    UpdateClickButtons()
    StopLogin()   ; 其他功能启动、全部停止时，顺便终止进行中的账号登陆
}

ToggleBoth(*) {
    global ClickMode, LastClickMode, TwoRunning, TwoPhase, Point1X, Point1Y, Point2X, Point2Y
    global WaitAfterFirst, WaitAfterSecond, RightRunning, RightX, RightY, RightClickInterval
    if (ClickMode = "both") {
        StopClickLoops()
        ToolTip()
        return
    }
    StopClickLoops()
    StopDesktopPolling()
    StopQuickSwitch()
    TwoRunning := true
    TwoPhase := 0
    RightRunning := true
    ClickMode := "both"
    LastClickMode := "both"
    UpdateClickButtons()
    StepTwo()
    StepRight()
    SetTimer(StepRight, RightClickInterval)
}

ToggleRightOnly(*) {
    global ClickMode, LastClickMode, RightRunning, RightX, RightY, RightClickInterval
    if (ClickMode = "right") {
        StopClickLoops()
        ToolTip()
        return
    }
    StopClickLoops()
    StopDesktopPolling()
    StopQuickSwitch()
    RightRunning := true
    ClickMode := "right"
    LastClickMode := "right"
    UpdateClickButtons()
    StepRight()
    SetTimer(StepRight, RightClickInterval)
}

ToggleSynth(*) {
    global ClickMode, LastClickMode, TwoRunning, TwoPhase, Point1X, Point1Y, Point2X, Point2Y, WaitAfterFirst, WaitAfterSecond
    if (ClickMode = "two") {
        StopClickLoops()
        ToolTip()
        return
    }
    StopClickLoops()
    StopDesktopPolling()
    StopQuickSwitch()
    TwoRunning := true
    TwoPhase := 0
    ClickMode := "two"
    LastClickMode := "two"
    UpdateClickButtons()
    StepTwo()
}

StepTwo() {
    global TwoPhase, Point1X, Point1Y, Point2X, Point2Y, WaitAfterFirst, WaitAfterSecond
    if (TwoPhase = 0) {
        Click(Point1X, Point1Y)
        ToolTip("点了点 1 (" Point1X ", " Point1Y ")")
        TwoPhase := 1
        SetTimer(StepTwo, WaitAfterFirst)
    } else {
        Click(Point2X, Point2Y)
        ToolTip("点了点 2 (" Point2X ", " Point2Y ")")
        TwoPhase := 0
        SetTimer(StepTwo, WaitAfterSecond)
    }
}

StepRight() {
    global RightX, RightY
    Click(RightX, RightY, "Right")
    ToolTip("右键点了 (" RightX ", " RightY ")")
}

; ===== 全部停止 =====
StopAll(*) {
    StopLogin()
    StopDesktopPolling()
    StopClickLoops()
    StopQuickSwitch()
    ToolTip()
}

; ===== 保存配置 =====
; 把开箱子当前用的三个坐标存到脚本同目录的 fenix_Config.ini，
; 下次打开自动恢复。等待时间是写死在代码里的固定值，不用 ini，不写。
; 正在运行时点保存也不会停掉正在跑的功能。
SaveConfig(*) {
    global ConfigFile
    global Point1X, Point1Y, Point2X, Point2Y, RightX, RightY
    IniWrite(Point1X, ConfigFile, "Click", "Point1X")
    IniWrite(Point1Y, ConfigFile, "Click", "Point1Y")
    IniWrite(Point2X, ConfigFile, "Click", "Point2X")
    IniWrite(Point2Y, ConfigFile, "Click", "Point2Y")
    IniWrite(RightX, ConfigFile, "Click", "RightX")
    IniWrite(RightY, ConfigFile, "Click", "RightY")
    MsgBox("配置已保存到：`n" ConfigFile "`n下次打开脚本会自动恢复这些坐标。")
}

; ===== 检查更新（底部「更新」按钮）=====
; 在脚本所在文件夹里执行 git pull：有新提交拉下来就自动 Reload，
; 让新代码立刻生效；已是最新、或者拉取失败，就不重启。
; 结果不弹框，显示在功能 4 下面那一行（txtUpdateStatus），几秒后自动消失。
UpdateRunning := false

CheckForUpdate(*) {
    global UpdateRunning, btnUpdate, txtUpdateStatus
    if (UpdateRunning) {
        return
    }
    UpdateRunning := true
    btnUpdate.Enabled := false
    SetTimer(ClearUpdateStatus, 0)
    txtUpdateStatus.Text := "正在检查更新…"
    Before := GitHeadHash()
    Out := ""
    Code := RunGit("pull", &Out)
    After := GitHeadHash()
    LogFind("update: git pull exit=" Code " head=" Before " -> " After)
    if (Out != "") {
        LogFind("update: " Out)
    }
    if (Code != 0) {
        txtUpdateStatus.Text := "更新失败，详情看日志 fenix_Find_Log.txt"
        SetTimer(ClearUpdateStatus, -6000)
        btnUpdate.Enabled := true
        UpdateRunning := false
        return
    }
    if (Before != "" && Before = After) {
        txtUpdateStatus.Text := "已是最新版本"
        SetTimer(ClearUpdateStatus, -3000)
        btnUpdate.Enabled := true
        UpdateRunning := false
        return
    }
    txtUpdateStatus.Text := "更新成功，正在重启脚本…"
    Sleep(1500)
    Reload()
}

ClearUpdateStatus() {
    global txtUpdateStatus
    txtUpdateStatus.Text := ""
}

; 读当前 HEAD 的提交哈希（读不到返回空：比如脚本文件夹不是 git 仓库）。
GitHeadHash() {
    Out := ""
    if (RunGit("rev-parse HEAD", &Out) != 0) {
        return ""
    }
    if (RegExMatch(Out, "([0-9a-f]{40})", &M) && M[1] != "") {
        return M[1]
    }
    Clean := Trim(StrReplace(StrReplace(Out, "`r", ""), "`n", ""))
    return StrLen(Clean) = 40 ? Clean : ""
}

; 在脚本文件夹里跑一条 git 命令：输出（标准输出和错误合在一起）放进 Out，
; 返回退出码。GIT_TERMINAL_PROMPT=0 让 git 需要交互输入时直接失败，不卡住。
RunGit(Args, &Out) {
    Tmp := A_Temp "\fenix_update_git.txt"
    try FileDelete(Tmp)
    OldPrompt := EnvGet("GIT_TERMINAL_PROMPT")
    EnvSet("GIT_TERMINAL_PROMPT", "0")
    Q := Chr(34)
    Code := RunWait("cmd /c git " Args " > " Q Tmp Q " 2>&1", A_ScriptDir, "Hide")
    EnvSet("GIT_TERMINAL_PROMPT", OldPrompt)
    Out := ""
    if (FileExist(Tmp)) {
        try Out := FileRead(Tmp)
        try FileDelete(Tmp)
    }
    return Code
}

; F12 用的开关：运行中（无论哪种模式）按 F12 停止；
; 未运行时启动上次点过的模式（点哪个按钮启动的就记哪个）。
; 刚打开脚本还没点过任何模式按钮时 LastClickMode 为空，
; 按 F12 什么都不做——第一次必须先点按钮。
ToggleClickHotkey(*) {
    global ClickMode, LastClickMode
    if (ClickMode != "") {
        StopClickLoops()
        ToolTip()
    } else if (LastClickMode = "right") {
        ToggleRightOnly()
    } else if (LastClickMode = "two") {
        ToggleSynth()
    } else if (LastClickMode = "both") {
        ToggleBoth()
    }
}

; 把三个桌面上的游戏窗口都挪到屏幕正中间。
; 屏幕分辨率用主显示器的（A_ScreenWidth / A_ScreenHeight），
; 每个窗口按它自己的宽高算中心，大小不变。
; 这样录的鼠标坐标换桌面也能用。窗口可能不在，
; 找不到就跳过，不报错。
AlignGameWindows() {
    global GameTitle, GetWindowDesktopNumberProc, GetCurrentDesktopNumberProc
    LogFind("align: started")
    if (!GetWindowDesktopNumberProc || !GetCurrentDesktopNumberProc) {
        LogFind("align: DLL proc missing, skip")
        return
    }
    try {
        CurrentDesk := DllCall(GetCurrentDesktopNumberProc, "Int")
        WinList := WinGetList(GameTitle)
    } catch as Err {
        LogFind("align: exception getting desktop/window list: " Err.Message)
        return
    }
    ScreenW := A_ScreenWidth
    ScreenH := A_ScreenHeight
    LogFind("align: current desktop=" CurrentDesk ", windows found=" WinList.Length ", screen=" ScreenW "x" ScreenH)
    if (WinList.Length = 0) {
        LogFind("align: no game window found")
        return
    }
    for hWnd in WinList {
        try {
            Desk := DllCall(GetWindowDesktopNumberProc, "Ptr", hWnd, "Int")
        } catch as Err {
            LogFind("align: GetWindowDesktopNumber failed for hwnd=" hWnd ": " Err.Message)
            Desk := -1
        }
        try {
            WinGetPos(&WinX, &WinY, &WinW, &WinH, "ahk_id " hWnd)
        } catch as Err {
            LogFind("align: WinGetPos failed for hwnd=" hWnd ": " Err.Message)
            continue
        }
        NewX := (ScreenW - WinW) // 2
        NewY := (ScreenH - WinH) // 2
        if (NewX < 0)
            NewX := 0
        if (NewY < 0)
            NewY := 0
        try {
            WinMove(NewX, NewY, WinW, WinH, "ahk_id " hWnd)
            LogFind("align: centered hwnd=" hWnd " (desktop " Desk ") from (" WinX "," WinY " " WinW "x" WinH ") to (" NewX "," NewY ")")
        } catch as Err {
            LogFind("align: WinMove failed for hwnd=" hWnd ": " Err.Message)
        }
    }
    LogFind("align: done")
}

; ===== 快捷切换桌面 =====
; 点按钮或按键盘 F1/F2/F3 切到对应桌面。
; 桌面号从 0 开始（桌面 1 = 0）。DLL 没加载成功时切不了。
; F1/F2/F3 切桌面：切过去后自动激活（点选）那个桌面上的游戏窗口，
; 不用再手动点一下。先等切换真正完成，再按标题找（每个桌面只有一个
; 游戏窗口，用 DLL 挑出当前桌面上的那一个），找不到再用图标位置找；
; 都找不到就点一下 (212,57) 来聚焦（和轮询的激活失败后一样）。
GoToDesktop(DesktopNum) {
    global GoToDesktopNumberProc, DesktopCount, GameWinW, GameWinH, SwitchClickX, SwitchClickY
    if (!GoToDesktopNumberProc || DesktopNum < 0 || DesktopNum >= DesktopCount) {
        return
    }
    GoToDesktopAndWait(DesktopNum)
    GameWinW := 0
    GameWinH := 0
    if (ActivateGameByTitle()) {
        return
    }
    Idx := DesktopNum + 1
    IX := 0
    IY := 0
    if (FindGameIcon(Idx, &IX, &IY)) {
        if (ActivateGameWindow(IX, IY)) {
            return
        }
    }
    ; 标题和图标都找不到，点一下来聚焦。
    try {
        Click(SwitchClickX, SwitchClickY)
    } catch {
    }
}

; 快捷切换的开始/停止：开始打开键盘 F1/F2/F3 切桌面，停止就关掉。
; 开始后「开始」变灰、「停止」可用；停止后反过来。
StartQuickSwitch(*) {
    global QuickSwitchEnabled, btnQuickStart, btnQuickStop
    ; 启动快捷切换前先停掉另外两个功能（轮询、开箱子）。
    StopDesktopPolling()
    StopClickLoops()
    QuickSwitchEnabled := true
    btnQuickStart.Enabled := false
    btnQuickStop.Enabled := true
    ShowTempToolTip("快捷切换已开启")
    ; 2 秒后把三个桌面上的游戏窗口都挪到屏幕正中间，
    ; 这样录的鼠标坐标换桌面也能用。
    LogFind("quickswitch: started, align timer set (2s)")
    SetTimer(AlignGameWindows, -2000)
}

; SC029 = ` 键（飘号键，左上角 1 左边那个）：快捷切换的启动 / 停止开关（全局热键，不受开关状态限制）。
; （AHK v2 里反引号是转义字符，不能直接写 ``:: 做热键，要用扫描码 SC029。）
ToggleQuickSwitch(*) {
    global QuickSwitchEnabled
    if (QuickSwitchEnabled) {
        StopQuickSwitch()
    } else {
        StartQuickSwitch()
    }
}

StopQuickSwitch(*) {
    global QuickSwitchEnabled, btnQuickStart, btnQuickStop
    global Recording, PlayingBack, txtQuickStatus
    WasOn := QuickSwitchEnabled
    SetTimer(AlignGameWindows, 0)
    SetTimer(RecordPoll, 0)
    Recording := false
    PlayingBack := false
    QuickSwitchEnabled := false
    btnQuickStart.Enabled := true
    btnQuickStop.Enabled := false
    txtQuickStatus.Text := "状态：未录制"
    if (WasOn) {
        ShowTempToolTip("快捷切换已停止")
    }
}

; 显示一个提示，3 秒后自动消失（不然提示字会一直留在屏幕上）。
ShowTempToolTip(Text) {
    ToolTip(Text)
    SetTimer(ClearToolTip, -3000)
}

ClearToolTip() {
    ToolTip()
}

; ===== 录鼠标和键盘 / 回放（快捷切换开着的时候才能用）=====
; 录鼠标（每次点下/松开左键/右键的位置和间隔）、键盘（每次按下/松开按键和间隔）。
; 回放按 F4：点一下回放 1 次；按住 F4 大约 2 秒弹出对话框
; 填重复次数（默认 0 = 无限制），确定后 1 秒开始回放，再按 F4 停掉。
; 每遍开始时光标旁边显示统计（回放 1 次显示「回放 1/1」，无限显示「无限回放 第 k 次」）。
RecordPoll() {
    global Recording, RecordEvents, RecordLastTick, RecordLastL, RecordLastR, KeysToRecord, KeyPrevState, txtQuickStatus
    if (!Recording) {
        return
    }
    MouseGetPos(&MX, &MY)
    LDown := GetKeyState("LButton", "P")
    RDown := GetKeyState("RButton", "P")
    Now := A_TickCount
    if (LDown && !RecordLastL) {
        RecordEvents.Push(["LDown", MX, MY, Now - RecordLastTick])
        RecordLastTick := Now
        txtQuickStatus.Text := "状态：正在记录…已录 " RecordEvents.Length " 个动作"
    } else if (!LDown && RecordLastL) {
        RecordEvents.Push(["LUp", MX, MY, Now - RecordLastTick])
        RecordLastTick := Now
        txtQuickStatus.Text := "状态：正在记录…已录 " RecordEvents.Length " 个动作"
    }
    if (RDown && !RecordLastR) {
        RecordEvents.Push(["RDown", MX, MY, Now - RecordLastTick])
        RecordLastTick := Now
        txtQuickStatus.Text := "状态：正在记录…已录 " RecordEvents.Length " 个动作"
    } else if (!RDown && RecordLastR) {
        RecordEvents.Push(["RUp", MX, MY, Now - RecordLastTick])
        RecordLastTick := Now
        txtQuickStatus.Text := "状态：正在记录…已录 " RecordEvents.Length " 个动作"
    }
    RecordLastL := LDown
    RecordLastR := RDown
    ; 键盘：和鼠标一样，状态变了才记一条（按下记 KDown，松开记 KUp）。
    for Key in KeysToRecord {
        Down := GetKeyState(Key, "P")
        Prev := KeyPrevState.Has(Key) ? KeyPrevState[Key] : false
        if (Down && !Prev) {
            RecordEvents.Push(["KDown", Key, 0, Now - RecordLastTick])
            RecordLastTick := Now
            txtQuickStatus.Text := "状态：正在记录…已录 " RecordEvents.Length " 个动作"
        } else if (!Down && Prev) {
            RecordEvents.Push(["KUp", Key, 0, Now - RecordLastTick])
            RecordLastTick := Now
            txtQuickStatus.Text := "状态：正在记录…已录 " RecordEvents.Length " 个动作"
        }
        KeyPrevState[Key] := Down
    }
}

; 5 键：回放中按一下停回放；不回放时按一下开始/停止录制。
ToggleRecord(*) {
    global Recording, RecordEvents, RecordLastTick, RecordLastL, RecordLastR, PlayingBack, KeysToRecord, KeyPrevState, LoadedRecordName, txtQuickStatus
    if (PlayingBack) {
        PlayingBack := false
        ShowTempToolTip("回放已停止")
        return
    }
    if (Recording) {
        Recording := false
        SetTimer(RecordPoll, 0)
        txtQuickStatus.Text := "状态：已录制 " RecordEvents.Length " 个动作，按 F4 回放"
        ShowTempToolTip("已录制 " RecordEvents.Length " 个动作，按 F4 回放")
    } else {
        RecordEvents := []
        LoadedRecordName := ""
        RecordLastTick := A_TickCount
        RecordLastL := GetKeyState("LButton", "P")
        RecordLastR := GetKeyState("RButton", "P")
        ; 键盘先记下当前状态，免得开始录的时候已经按着的键被当成新按下的记进去。
        KeyPrevState := Map()
        for Key in KeysToRecord {
            KeyPrevState[Key] := GetKeyState(Key, "P")
        }
        Recording := true
        SetTimer(RecordPoll, 10)
        txtQuickStatus.Text := "状态：正在记录鼠标和键盘…再按 F5 停止"
        ToolTip("正在记录鼠标和键盘…再按 F5 停止")
    }
}

; F4：点一下回放 1 次；按住大约 2 秒弹出对话框填重复次数
; （默认 0，0 是无限制，填几就回放几次），点确定后 1 秒开始
; 回放；取消就不回放。再按 F4 停掉（F5 也能停）。
F4Handler(*) {
    global Recording, RecordEvents, PlayingBack, txtQuickStatus
    if (Recording) {
        return
    }
    if (PlayingBack) {
        ; 正在回放，按 F4 就停掉（点一下还是按住都一样，立刻停）
        PlayingBack := false
        ToolTip()
        txtQuickStatus.Text := "状态：已录制 " RecordEvents.Length " 个动作，按 F4 回放"
        ShowTempToolTip("回放已停止")
        return
    }
    if (RecordEvents.Length = 0) {
        ShowTempToolTip("没有录制内容，先按 F5 录一段")
        return
    }
    ; 等 F4 松开，最多等 2 秒：2 秒内松开是点一下，超过 2 秒是按住。
    ; 回放用一次性定时器另起一个线程跑，这个热键线程立刻返回、空出来，
    ; 回放中再按 F4 才能再进本函数走到上面的停止分支（同一热键同时
    ; 只能跑一个线程，线程被回放占住时，后按的 F4 会被直接吞掉）。
    Released := KeyWait("F4", "T2")
    if (Released) {
        SetTimer(() => PlayRecording(1), -1)
    } else {
        ; 按住超过 2 秒：弹框问重复次数，默认 0（0 = 无限制）。
        ; 取消就不回放；填的不是 0 或正整数也不回放。
        IB := InputBox("重复次数（0 = 无限制，填几就回放几次）", "回放次数", "w320 h130", "0")
        if (IB.Result = "Cancel") {
            return
        }
        TimesText := Trim(IB.Value)
        if (!RegExMatch(TimesText, "^\d+$")) {
            ShowTempToolTip("次数无效，未回放（请输入 0 或正整数）")
            return
        }
        Times := Integer(TimesText)
        ToolTip(Times = 0 ? "无限回放，1 秒后开始" : "回放 " Times " 次，1 秒后开始")
        Sleep(1000)
        SetTimer(() => PlayRecording(Times), -1)
    }
}

; 把录下来的鼠标动作执行 Count 遍（Count=0 是无限次，直到再按 F4 停掉）。
; 间隔按录的时候一样（最长 30 秒）。
; 有限次时每遍开始显示「回放 k/N」，无限时显示「无限回放 第 k 次」。
PlayRecording(Count) {
    global RecordEvents, PlayingBack, txtQuickStatus
    if (PlayingBack) {
        return
    }
    PlayingBack := true
    FinishedAll := true
    Round := 0
    Loop {
        Round++
        if (Count > 0 && Round > Count) {
            break
        }
        if (!PlayingBack) {
            FinishedAll := false
            break
        }
        if (Count > 0) {
            CountText := Round "/" Count
            ToolTip("回放 " CountText)
            txtQuickStatus.Text := "状态：正在回放 " CountText "…按 F4 停止"
        } else {
            ToolTip("无限回放 第 " Round " 次")
            txtQuickStatus.Text := "状态：无限回放 第 " Round " 次…按 F4 停止"
        }
        for Ev in RecordEvents {
            if (!PlayingBack) {
                FinishedAll := false
                break
            }
            Sleep(Min(Ev[4], 30000))
            if (!PlayingBack) {
                FinishedAll := false
                break
            }
            if (Ev[1] = "LDown") {
                MouseMove(Ev[2], Ev[3], 0)
                Click("Down")
            } else if (Ev[1] = "LUp") {
                MouseMove(Ev[2], Ev[3], 0)
                Click("Up")
            } else if (Ev[1] = "RDown") {
                MouseMove(Ev[2], Ev[3], 0)
                Click("Right Down")
            } else if (Ev[1] = "RUp") {
                MouseMove(Ev[2], Ev[3], 0)
                Click("Right Up")
            } else if (Ev[1] = "KDown") {
                try {
                    Send("{" Ev[2] " Down}")
                } catch {
                }
            } else if (Ev[1] = "KUp") {
                try {
                    Send("{" Ev[2] " Up}")
                } catch {
                }
            }
        }
        if (!PlayingBack) {
            FinishedAll := false
            break
        }
    }
    PlayingBack := false
    txtQuickStatus.Text := "状态：已录制 " RecordEvents.Length " 个动作，按 F4 回放"
    if (FinishedAll) {
        ToolTip()
        ShowTempToolTip("回放完成")
    } else {
        ; 中途停掉：松开可能还按着的修饰键和鼠标键，免得卡住。
        try {
            Send("{LShift Up}{RShift Up}{LCtrl Up}{RCtrl Up}{LAlt Up}{RAlt Up}")
            Click("Up")
            Click("Right Up")
        } catch {
        }
    }
    ; 中途停掉的，F4/F5 那边已经显示了「回放已停止」，这里不碰提示。
}

; ===== 已保存的录制 =====
; 一个录制一个文件，存在脚本目录下的 records 文件夹里，文件名就是录制的名字。
; 文件里一行一个动作：类型,参数1,参数2,间隔（和内存里的 RecordEvents 对应）。
; 鼠标：LDown/LUp/RDown/RUp,X,Y,间隔
; 键盘：KDown/KUp,按键名,0,间隔

; 刷新下拉框里的录制列表（读 records 文件夹里的 .txt 文件名）。
RefreshRecordList() {
    global cmbRecords, RecordsDir
    cmbRecords.Delete()
    if (!DirExist(RecordsDir)) {
        return
    }
    Loop Files, RecordsDir "\*.txt" {
        Name := SubStr(A_LoopFileName, 1, -4)
        cmbRecords.Add([Name])
    }
}

; 保存：把当前内存里的录制写成文件。名字从下拉框里输（新名字就是新建，
; 已有的名字会问要不要覆盖）。
SaveRecord(*) {
    global RecordEvents, RecordsDir, cmbRecords, txtQuickStatus, LoadedRecordName
    if (RecordEvents.Length = 0) {
        MsgBox("没有录制内容，先按 F5 录一段。", "保存录制", "OK Icon!")
        return
    }
    Name := Trim(cmbRecords.Text)
    if (Name = "") {
        MsgBox("先在下拉框里输一个名字，再点保存。", "保存录制", "OK Icon!")
        return
    }
    if (RegExMatch(Name, '[\\/:*?"<>|]')) {
        MsgBox("名字里不能有 \ / : * ? `" < > | 这些字符。", "保存录制", "OK Icon!")
        return
    }
    DirCreate(RecordsDir)
    Path := RecordsDir "\" Name ".txt"
    if (FileExist(Path)) {
        Result := MsgBox("已经有叫「" Name "」的录制了，要覆盖吗？", "保存录制", "YesNo Icon?")
        if (Result = "No") {
            return
        }
    }
    Text := ""
    for Ev in RecordEvents {
        Text .= Ev[1] "," Ev[2] "," Ev[3] "," Ev[4] "`n"
    }
    try {
        if (FileExist(Path)) {
            FileDelete(Path)
        }
        FileAppend(Text, Path, "UTF-8")
    } catch as Err {
        MsgBox("保存失败：" Err.Message, "保存录制", "OK Icon!")
        return
    }
    LoadedRecordName := Name
    RefreshRecordList()
    cmbRecords.Text := Name
    txtQuickStatus.Text := "状态：已保存「" Name "」，共 " RecordEvents.Length " 个动作"
}

; 读取：把下拉框里选中的文件读进内存，按 F4 就能回放，不用再录。
LoadRecord(*) {
    global RecordEvents, RecordsDir, cmbRecords, txtQuickStatus, LoadedRecordName, Recording, PlayingBack
    if (Recording || PlayingBack) {
        MsgBox("正在录制或回放，先停掉再读取。", "读取录制", "OK Icon!")
        return
    }
    Name := Trim(cmbRecords.Text)
    if (Name = "") {
        MsgBox("先在下拉框里选一个录制，或者输一个已有的名字。", "读取录制", "OK Icon!")
        return
    }
    Path := RecordsDir "\" Name ".txt"
    if (!FileExist(Path)) {
        MsgBox("没有叫「" Name "」的录制。", "读取录制", "OK Icon!")
        return
    }
    try {
        Text := FileRead(Path, "UTF-8")
    } catch as Err {
        MsgBox("读取失败：" Err.Message, "读取录制", "OK Icon!")
        return
    }
    NewEvents := []
    Loop Parse, Text, "`n", "`r" {
        Line := Trim(A_LoopField)
        if (Line = "") {
            continue
        }
        Parts := StrSplit(Line, ",")
        if (Parts.Length < 4) {
            continue
        }
        Type := Parts[1]
        try {
            if (Type = "LDown" || Type = "LUp" || Type = "RDown" || Type = "RUp") {
                NewEvents.Push([Type, Integer(Parts[2]), Integer(Parts[3]), Integer(Parts[4])])
            } else if (Type = "KDown" || Type = "KUp") {
                NewEvents.Push([Type, Parts[2], 0, Integer(Parts[4])])
            }
        } catch {
            continue
        }
    }
    if (NewEvents.Length = 0) {
        MsgBox("「" Name "」里没有有效的动作。", "读取录制", "OK Icon!")
        return
    }
    RecordEvents := NewEvents
    LoadedRecordName := Name
    txtQuickStatus.Text := "状态：已读取「" Name "」，共 " RecordEvents.Length " 个动作，按 F4 回放"
}

; 删除：删掉下拉框里选中的文件（内存里的录制还在，按 F4 还能回放）。
DeleteRecord(*) {
    global RecordsDir, cmbRecords, LoadedRecordName
    Name := Trim(cmbRecords.Text)
    if (Name = "") {
        MsgBox("先在下拉框里选一个录制。", "删除录制", "OK Icon!")
        return
    }
    Path := RecordsDir "\" Name ".txt"
    if (!FileExist(Path)) {
        MsgBox("没有叫「" Name "」的录制。", "删除录制", "OK Icon!")
        return
    }
    Result := MsgBox("确定要删除「" Name "」吗？", "删除录制", "YesNo Icon?")
    if (Result = "No") {
        return
    }
    try {
        FileDelete(Path)
    } catch as Err {
        MsgBox("删除失败：" Err.Message, "删除录制", "OK Icon!")
        return
    }
    if (LoadedRecordName = Name) {
        LoadedRecordName := ""
    }
    cmbRecords.Text := ""
    RefreshRecordList()
    ShowTempToolTip("已删除「" Name "」")
}

; ===== 功能 4：账号登陆 =====
; 刷新三个桌面选择框里的账号列表（读 accounts 文件夹里的 .txt 文件名，不读内容）。
; 每个框的最后一行固定是空行（选它 = 这个桌面不登陆）；刷新前选的账号
; 还在就选回去，已经被删了就回到空行。
RefreshAccountList() {
    global cmbAcc1, cmbAcc2, cmbAcc3, AccountsDir
    Names := []
    if (DirExist(AccountsDir)) {
        Loop Files, AccountsDir "\*.txt" {
            Names.Push(SubStr(A_LoopFileName, 1, -4))
        }
    }
    Names.Push("")
    for Cmb in [cmbAcc1, cmbAcc2, cmbAcc3] {
        Prev := Trim(Cmb.Text)
        Cmb.Delete()
        Cmb.Add(Names)
        Pick := Names.Length
        if (Prev != "") {
            for I, N in Names {
                if (N = Prev) {
                    Pick := I
                    break
                }
            }
        }
        Cmb.Choose(Pick)
    }
}

; 读账号文件：返回 [登陆密码, 二次密码]（没有第 2 行时二次密码是空串）。
; 文件不存在或读失败返回空数组。
ReadAccountFile(Name) {
    global AccountsDir
    Path := AccountsDir "\" Name ".txt"
    if (!FileExist(Path)) {
        return []
    }
    try {
        Text := FileRead(Path, "UTF-8")
    } catch {
        return []
    }
    Lines := StrSplit(Text, "`n", "`r")
    Pwd := Lines.Length >= 1 ? Trim(Lines[1]) : ""
    Pwd2 := Lines.Length >= 2 ? Trim(Lines[2]) : ""
    return [Pwd, Pwd2]
}

; ===== 新增账号对话框 =====
; 点「新增」弹这个对话框：账号、密码、二次密码都在这里填，三个都填好点保存
; 才写入 accounts 文件。对话框开着时主窗口禁用（模态）；校验不过只弹框说明、
; 对话框不关，改完再点保存。取消、按 Esc、点 X 都不保存。
AddDlg := ""
AddEdtName := ""
AddEdtPwd := ""
AddEdtPwd2 := ""
AddSavedName := ""

AddAccount(*) {
    global MyGui, AddDlg, AddEdtName, AddEdtPwd, AddEdtPwd2, AddSavedName, cmbAcc1
    if (IsObject(AddDlg)) {
        AddDlg.Show()
        return
    }
    AddSavedName := ""
    Dlg := Gui("+Owner" MyGui.Hwnd " -MinimizeBox -MaximizeBox", "新增账号")
    AddDlg := Dlg
    Dlg.Add("Text", "x10 y14 w64", "账号：")
    AddEdtName := Dlg.Add("Edit", "x74 y12 w206")
    Dlg.Add("Text", "x10 y46 w64", "密码：")
    AddEdtPwd := Dlg.Add("Edit", "x74 y44 w206 +Password")
    Dlg.Add("Text", "x10 y78 w64", "二次密码：")
    AddEdtPwd2 := Dlg.Add("Edit", "x74 y76 w206 +Password")
    BtnOk := Dlg.Add("Button", "x74 y110 w96 h28 Default", "保存")
    BtnOk.OnEvent("Click", AddDialogSave)
    BtnCancel := Dlg.Add("Button", "x184 y110 w96 h28", "取消")
    BtnCancel.OnEvent("Click", AddDialogCancel)
    Dlg.OnEvent("Close", AddDialogCancel)
    Dlg.OnEvent("Escape", AddDialogCancel)
    MyGui.Opt("+Disabled")
    Dlg.Show("w296 h150")
    AddEdtName.Focus()
    while (IsObject(AddDlg)) {
        Sleep(50)
    }
    if (AddSavedName != "") {
        RefreshAccountList()
        cmbAcc1.Choose(AddSavedName)
        ShowTempToolTip("已保存账号「" AddSavedName "」")
    }
}

; 对话框里点「保存」：三个框逐个校验，都过了才写文件并关对话框。
AddDialogSave(*) {
    global AccountsDir, AddEdtName, AddEdtPwd, AddEdtPwd2, AddSavedName
    Name := Trim(AddEdtName.Value)
    Pwd := AddEdtPwd.Value
    Pwd2 := Trim(AddEdtPwd2.Value)
    if (Name = "") {
        MsgBox("账号还没填。", "新增账号", "OK Icon!")
        return
    }
    if (RegExMatch(Name, '[\\/:*?"<>|]')) {
        MsgBox("账号名里不能有 \ / : * ? `" < > | 这些字符。", "新增账号", "OK Icon!")
        return
    }
    if (Pwd = "" || Pwd2 = "") {
        MsgBox("密码和二次密码都要填，缺一个保存不了。", "新增账号", "OK Icon!")
        return
    }
    if (!RegExMatch(Pwd2, "^\d+$")) {
        MsgBox("二次密码只能是数字。", "新增账号", "OK Icon!")
        return
    }
    Path := AccountsDir "\" Name ".txt"
    if (FileExist(Path)) {
        Result := MsgBox("已经有账号「" Name "」了，要用这次填的密码和二次密码覆盖吗？", "新增账号", "YesNo Icon?")
        if (Result = "No") {
            return
        }
    }
    try {
        DirCreate(AccountsDir)
        if (FileExist(Path)) {
            FileDelete(Path)
        }
        FileAppend(Pwd . "`n" . Pwd2, Path, "UTF-8-RAW")
    } catch as Err {
        MsgBox("保存失败：" Err.Message, "新增账号", "OK Icon!")
        return
    }
    AddSavedName := Name
    CloseAddDialog()
}

AddDialogCancel(*) {
    CloseAddDialog()
}

CloseAddDialog() {
    global AddDlg, MyGui
    if (IsObject(AddDlg)) {
        AddDlg.Destroy()
        AddDlg := ""
    }
    MyGui.Opt("-Disabled")
}

; 「删除」删的是桌面1框里选中的账号（三个框选的是同一批账号文件，
; 删除是删文件，跟桌面无关，固定拿桌面1的框当准）。
DeleteAccount(*) {
    global AccountsDir, cmbAcc1
    Name := Trim(cmbAcc1.Text)
    if (Name = "") {
        MsgBox("先在桌面1的下拉框里选一个账号。", "删除账号", "OK Icon!")
        return
    }
    Path := AccountsDir "\" Name ".txt"
    if (!FileExist(Path)) {
        MsgBox("没有叫「" Name "」的账号。", "删除账号", "OK Icon!")
        return
    }
    Result := MsgBox("确定要删除账号「" Name "」吗？`n（密码和二次密码都会一起删掉）", "删除账号", "YesNo Icon?")
    if (Result = "No") {
        return
    }
    try {
        FileDelete(Path)
    } catch as Err {
        MsgBox("删除失败：" Err.Message, "删除账号", "OK Icon!")
        return
    }
    RefreshAccountList()
    ShowTempToolTip("已删除账号「" Name "」")
}

; 终止进行中的登陆（Esc、全部停止、其他功能启动都会调用）。
; 登陆流程在下一个等待点发现标志变了就退出。
StopLogin(*) {
    global LoginRunning
    if (!LoginRunning) {
        return
    }
    LoginRunning := false
    ToolTip()
}

; 点“登陆”：三个框里选了账号的桌面，按桌面 1→2→3 依次登陆
; （选空行 = 那个桌面不登陆）。开始前先逐个校验选中的账号文件，
; 免得登到一半才发现某个账号文件有问题。某个桌面登陆出错只记下来、
; 继续登下一个，全部登完再一起弹框汇总（只登一个桌面时和以前一样，
; 出错弹完整的说明、没等到界面也和以前一样静默结束）；按 Esc
; 取消整个序列。全部登完切回开始时所在的桌面。
LoginAccount(*) {
    global LoginRunning, cmbAcc1, cmbAcc2, cmbAcc3
    global QuickSwitchEnabled, DesktopRunning, TwoRunning, RightRunning
    global DesktopCount, GetCurrentDesktopNumberProc
    Targets := []
    for Idx, Cmb in [cmbAcc1, cmbAcc2, cmbAcc3] {
        Name := Trim(Cmb.Text)
        if (Name = "") {
            continue
        }
        Info := ReadAccountFile(Name)
        if (Info.Length = 0) {
            MsgBox("桌面" Idx "选的「" Name "」没有账号文件，先点「新增」添加账号。", "账号登陆", "OK Icon!")
            return
        }
        if (Info[1] = "") {
            MsgBox("accounts\" Name ".txt 第 1 行（密码）是空的。", "账号登陆", "OK Icon!")
            return
        }
        Targets.Push([Idx, Name, Info[1], Info[2]])
    }
    if (Targets.Length = 0) {
        MsgBox("三个桌面都没选账号（都选了空行），不登陆。", "账号登陆", "OK Icon!")
        return
    }
    ; 同一个账号不能在两个桌面上重复登陆：选重了就弹窗拦下，不开始。
    ; Targets 里每条是数组 [桌面号, 账号, 密码, 二次密码]，按位置取。
    Loop Targets.Length {
        I := A_Index
        Loop Targets.Length - I {
            J := I + A_Index
            if (Targets[I][2] = Targets[J][2]) {
                MsgBox("桌面" Targets[I][1] "和桌面" Targets[J][1] "选了同一个账号「" Targets[I][2] "」，同一个账号不能重复登陆，请改掉一个再点登陆。", "账号登陆", "OK Icon!")
                return
            }
        }
    }
    ; 功能互斥：启动登陆前先停掉其他所有功能（和其他功能一样的规矩）。
    ; 快捷切换先记下开没开：登陆结束时按原样恢复（2026-11-05 她选的方案）。
    WasQuickSwitch := QuickSwitchEnabled
    StopDesktopPolling()
    StopClickLoops()
    StopQuickSwitch()
    ; 记下开始时所在的桌面，全部登完再切回去。
    StartDesktop := -1
    if (GetCurrentDesktopNumberProc) {
        try {
            StartDesktop := DllCall(GetCurrentDesktopNumberProc, "Int")
        }
    }
    LoginRunning := true
    Failures := []
    LoggedDesks := []
    for T in Targets {
        Desk := T[1]
        Name := T[2]
        if (!LoginRunning) {
            break
        }
        LogFind("login: desktop " Desk " account=" Name)
        DeskFailed := ""
        try {
            if (DesktopCount > 0 && Desk - 1 >= DesktopCount) {
                throw Error("一共只有 " DesktopCount " 个桌面，没有桌面" Desk "。")
            }
            GoToDesktopAndWait(Desk - 1)
            LoginSleep(500)
            ; 验桌面号：切换偶尔会不生效（调用了却没切过去，或者切得
            ; 太慢、等待超时），而每个桌面都有游戏窗口，光验「当前
            ; 桌面有窗口」拦不住在错桌面登陆。必须核对当前桌面号就
            ; 是目标桌面：对不上先重试切一次，还对不上就跳过这个
            ; 桌面报错，绝不在错桌面上登陆。
            CurDesk := CurrentDesktopNum()
            if (CurDesk >= 0 && CurDesk != Desk - 1) {
                LogFind("login: switch to desktop " Desk " did not take (still on desktop " (CurDesk + 1) "), retrying")
                GoToDesktopAndWait(Desk - 1)
                LoginSleep(500)
                CurDesk := CurrentDesktopNum()
            }
            if (CurDesk >= 0 && CurDesk != Desk - 1) {
                throw Error("没能切到桌面" Desk "（现在还在桌面" (CurDesk + 1) "），这个桌面跳过。")
            }
            if (CurDesk >= 0) {
                LogFind("login: on desktop " Desk " (verified)")
            }
            ; 再验这个桌面上有没有游戏窗口：DoLogin 第 1 步在当前桌面
            ; 找不到窗口时，会退到「任意桌面的同名窗口」，依次登陆时
            ; 那样会把账号登进别的桌面的客户端，所以这里先验过。
            if (!ActivateGameByTitle()) {
                throw Error("桌面" Desk "上没找到游戏窗口，这个桌面跳过。")
            }
            if (!DoLogin(Name, T[3], T[4]) && Targets.Length > 1) {
                DeskFailed := "5 秒内没等到二次密码或登陆确认"
            }
            LoggedDesks.Push(Desk)
        } catch as Err {
            if (Err.Message = "LoginAborted") {
                break
            }
            DeskFailed := (Targets.Length = 1) ? Err.Message : StrSplit(Err.Message, "`n")[1]
            LogFind("login FAILED desktop " Desk ": " Err.Message)
        }
        if (DeskFailed != "") {
            Failures.Push("桌面" Desk "「" Name "」：" DeskFailed)
        }
    }
    ; 收尾：全部登完后，依次回到每个登陆过的桌面（登陆时抛错跳过
    ; 的不在 LoggedDesks 里，不去），把游戏窗口里的「关闭」（英文
    ; 版是 Close）点掉——每个桌面最多找 8 秒，找不到就跳过；
    ; 做完再往下切回开始的桌面。中途按了 Esc（LoginRunning 被
    ; 清），这里也停。
    if (LoginRunning && LoggedDesks.Length > 0) {
        try {
            for Desk in LoggedDesks {
                if (!LoginRunning) {
                    break
                }
                ClickCloseButton(Desk)
            }
        } catch as Err2 {
            if (Err2.Message != "LoginAborted") {
                throw Err2
            }
        }
    }
    Aborted := !LoginRunning
    LoginRunning := false
    ToolTip()
    if (StartDesktop >= 0) {
        GoToDesktopAndWait(StartDesktop)
    }
    if (Failures.Length > 0) {
        Summary := ""
        for F in Failures {
            Summary .= (Summary = "" ? "" : "`n") F
        }
        LogFind("login: finished with " Failures.Length " failure(s)")
        MsgBox(Summary, "账号登陆", "OK Icon!")
    } else if (Aborted) {
        LogFind("login: cancelled")
    } else {
        LogFind("login: all done")
    }
    ; 登陆前快捷切换是开着的，就自动开回来——省得每次登完再手动重开。
    ; 登陆期间要是已经手动开回来了、或者已经开起了别的功能，就不重复动。
    if (WasQuickSwitch && !QuickSwitchEnabled && !DesktopRunning && !TwoRunning && !RightRunning) {
        LogFind("login: quick switch was on before login, restored")
        StartQuickSwitch()
    }
}

; 收尾点「关闭」：切到指定桌面，在那个桌面的游戏窗口里找
; 「关闭」二字（图案 CloseBtnText）或英文「Close」（图案
; CloseBtnENText）——两个是「或」关系，哪个先找到点哪个；
; 8 秒内都没找到就记日志跳过。切换后先核对桌面号（和登陆
; 时同一道验）：对不上重试切一次，还对不上就跳过这个桌面
; ——不在错桌面上乱点。
ClickCloseButton(Desk) {
    global CloseBtnText, CloseBtnENText, GameWinX, GameWinY, GameWinW, GameWinH
    GoToDesktopAndWait(Desk - 1)
    LoginSleep(300)
    CurDesk := CurrentDesktopNum()
    if (CurDesk >= 0 && CurDesk != Desk - 1) {
        LogFind("login: close-click switch to desktop " Desk " did not take (still on desktop " (CurDesk + 1) "), retrying")
        GoToDesktopAndWait(Desk - 1)
        LoginSleep(300)
        CurDesk := CurrentDesktopNum()
    }
    if (CurDesk >= 0 && CurDesk != Desk - 1) {
        LogFind("login: close-click skipped desktop " Desk " (could not switch to it)")
        return
    }
    ; 只在这个桌面的游戏窗口里找（她 2026-11-08 定的范围）：先按
    ; 标题激活游戏窗口、刷新它的位置和大小；这个桌面上没有游戏
    ; 窗口就跳过。
    if (!ActivateGameByTitle()) {
        LogFind("login: close-click skipped desktop " Desk " (no game window)")
        return
    }
    X1 := GameWinX
    Y1 := GameWinY
    X2 := GameWinX + GameWinW
    Y2 := GameWinY + GameWinH
    Start := A_TickCount
    Loop {
        if (FindPattern(CloseBtnText, X1, Y1, X2, Y2, &CX, &CY)) {
            LoginClick(CX, CY)
            LogFind("login: close clicked on desktop " Desk " at (" CX "," CY ")")
            return
        }
        if (FindPattern(CloseBtnENText, X1, Y1, X2, Y2, &CX, &CY)) {
            LoginClick(CX, CY)
            LogFind("login: close clicked (EN) on desktop " Desk " at (" CX "," CY ")")
            return
        }
        if (A_TickCount - Start >= 8000) {
            LogFind("login: no close button on desktop " Desk " within 8s")
            return
        }
        LoginSleep(250)
    }
}

; 可被取消的等待：每 50ms 看一次标志，被取消就抛 LoginAborted 退出整个流程。
LoginSleep(Ms) {
    global LoginRunning
    End := A_TickCount + Ms
    while (A_TickCount < End) {
        if (!LoginRunning) {
            throw Error("LoginAborted")
        }
        Sleep(Min(50, End - A_TickCount))
    }
    if (!LoginRunning) {
        throw Error("LoginAborted")
    }
}

; 登陆进度不再显示在界面上（2026-11-06 去掉了功能 4 的状态行），改记到日志，
; 登陆出问题时对着 fenix_Find_Log.txt 里 login: 开头的行查。
LoginStatus(Msg) {
    LogFind("login: " Msg)
}

; 点一个位置：先移过去稍停一下再点，点完也留一点间隔给客户端反应。
LoginClick(X, Y) {
    MouseMove(X, Y, 0)
    LoginSleep(80)
    Click()
    LoginSleep(120)
}

; 清空输入框里已有的内容（点进框后，光标到末尾再连按退格）。
LoginClearField() {
    Send("{End}{BackSpace 24}")
    LoginSleep(150)
}

; 整串一次输进去（SendText 是 {Text} 模式：特殊字符按字面输入），不逐字敲
; ——逐字加间隔那套慢好几秒，这个客户端整串输没丢过字。
LoginType(Str) {
    if (Str != "") {
        SendText(Str)
    }
}

; 游戏窗口的矩形（激活窗口时记下的）；没记到就用整个屏幕。
LoginRegion(&X1, &Y1, &X2, &Y2) {
    global GameWinX, GameWinY, GameWinW, GameWinH
    if (GameWinW > 0 && GameWinH > 0) {
        X1 := GameWinX
        Y1 := GameWinY
        X2 := GameWinX + GameWinW
        Y2 := GameWinY + GameWinH
    } else {
        X1 := 0
        Y1 := 0
        X2 := A_ScreenWidth
        Y2 := A_ScreenHeight
    }
}

; 在游戏窗口里找图案，最多等 TimeoutMs 毫秒（每 0.25 秒找一次），找到返回 true。
LoginFindWait(Text, &CX, &CY, TimeoutMs, E1 := "", E0 := "") {
    Start := A_TickCount
    CX := 0
    CY := 0
    Loop {
        LoginSleep(1)
        LoginRegion(&X1, &Y1, &X2, &Y2)
        if (FindPattern(Text, X1, Y1, X2, Y2, &CX, &CY, E1, E0)) {
            return true
        }
        if (A_TickCount - Start >= TimeoutMs) {
            return false
        }
        LoginSleep(250)
    }
}

; 找登陆确认对话框（中文「是」或英文 Yes），找到就点掉并返回 true；
; 没找到返回 false。等二次密码时每轮也先调它一次：没有二次密码时
; 确认框会直接出现，不先找就会干等键盘、白等好几秒。
ClickLoginConfirmIfPresent() {
    LoginRegion(&X1, &Y1, &X2, &Y2)
    if (FindPattern(ConfirmYesText, X1, Y1, X2, Y2, &YX, &YY)) {
        LogFind("login: confirm 'yes' at (" YX "," YY "), clicked, done")
        LoginStatus("确认登陆…")
        LoginSleep(300)
        LoginClick(YX, YY)
        return true
    }
    if (FindPattern(ConfirmYesENText, X1, Y1, X2, Y2, &YX, &YY)) {
        LogFind("login: confirm 'yes' (EN) at (" YX "," YY "), clicked, done")
        LoginStatus("确认登陆…")
        LoginSleep(300)
        LoginClick(YX, YY)
        return true
    }
    return false
}

; 登陆主流程。出错抛 Error（消息就是弹给用户看的原因）。
; 返回 true = 点到了登陆确认；false = 二次密码和确认框都没等到（各等最多 5 秒）
; （依次登陆多个桌面时，调用方靠这个区分这个桌面走没走完）。
DoLogin(Name, Pwd, Pwd2) {
    LogFind("login: start account=" Name " hasSecondPwd=" (Pwd2 != "" ? "yes" : "no"))

    ; 1. 激活客户端窗口（先按标题 + DLL 找当前桌面的那个，不行再按标题找任意一个）
    LoginStatus("激活客户端…")
    if (!ActivateGameByTitle()) {
        hWnd := WinExist(GameTitle)
        if (!hWnd) {
            throw Error("没找到标题是「" GameTitle "」的客户端窗口，请先打开游戏客户端。")
        }
        WinActivate("ahk_id " hWnd)
        SaveGameWinRect(hWnd)
    }
    LoginSleep(300)

    ; 2. 找 Login 按钮（界面是否到了登陆画面）
    LoginStatus("查找登陆界面…")
    if (!LoginFindWait(LoginBtnText, &BX, &BY, 8000)) {
        throw Error("没找到登陆界面（没认出 Login 按钮）。`n请确认客户端停在账号登陆画面，窗口没被挡住；"
            . "仍然不行就重新用 FindText 截一张 Login 字样，替换脚本里的 LoginBtnText。")
    }
    LogFind("login: Login button at (" BX "," BY ")")

    ; 3. 输账号、Tab、输密码、点 Login（每步之间留间隔，防止客户端反应不过来）
    LoginStatus("输入账号和密码…")
    LoginClick(BX + LoginAccountDX, BY + LoginAccountDY)
    LoginSleep(200)
    LoginClearField()
    LoginType(Name)
    LoginSleep(250)
    Send("{Tab}")
    LoginSleep(250)
    LoginClearField()
    LoginType(Pwd)
    LoginSleep(400)
    LoginStatus("点击 Login…")
    LoginClick(BX, BY)

    ; 4. 等后续界面（2026-11-07 她定的时限：等二次密码最多 5 秒，
    ; 不再是 30 秒）：有二次密码就先等键盘出现，最多等 5 秒，出现了
    ; 就输完；然后等登陆确认对话框，最多等 5 秒，出现就点「是」，
    ; 点完本次运行就结束——不检测登陆状态、不报结果。等键盘的每轮
    ; 先找一次确认框：没有二次密码时确认框会直接出现，不先找就会
    ; 干等键盘、白等好几秒。什么都没等到也直接结束（一样不判断、
    ; 不显示），返回 false 让依次登陆知道这个桌面没走完。
    if (Pwd2 != "") {
        PinStart := A_TickCount
        Loop {
            if (ClickLoginConfirmIfPresent()) {
                return true
            }
            if (TryEnterSecondPassword(Name, Pwd2)) {
                break
            }
            if (A_TickCount - PinStart >= 5000) {
                LogFind("login: no pin keypad within 5s")
                break
            }
            LoginSleep(300)
        }
    }
    CStart := A_TickCount
    Loop {
        if (ClickLoginConfirmIfPresent()) {
            return true
        }
        if (A_TickCount - CStart >= 5000) {
            LogFind("login: nothing appeared within 5s, stop")
            return false
        }
        LoginSleep(300)
    }
}

; 二次密码（不用黄字锚点）：先把鼠标挪开，再用 DigitText 图案在游戏窗口里找
; 密码用到的每个数字的命中位置，按键盘格距（36x36）拼成一整盘才开始点
; （见 HuntPinKeypad）——拼不成盘就一个都不点。细节都写进 fenix_Find_Log.txt。
; 返回 true = 已输完二次密码并点了“输入”；false = 这一轮没找到键盘。
TryEnterSecondPassword(Name, Pwd2) {
    global SecEnterText, PinBoxOff, PinEnterOff, SecEnterENText, PinBoxOffEN, PinEnterOffEN
    if (!RegExMatch(Pwd2, "^\d+$")) {
        throw Error("accounts\" Name ".txt 第 2 行的二次密码只能是数字。")
    }
    Need := Map()
    Loop Parse, Pwd2 {
        Need[A_LoopField] := true
    }
    ; 鼠标先停到左上方黄金点，别悬停在键盘上把格子弄变色、影响采样
    MouseMove(Round(A_ScreenWidth * 0.382), 200, 0)
    if (!HuntPinKeypad(Need, &Cells, &C1X, &C1Y)) {
        return false
    }
    ; 先辨认是不是英文客户端（必须在点数字之前找：输完密码 Enter 会点亮变色，
    ; 未点亮的灰字图案就找不到了）。找到 Enter 灰字 = 英文版。
    EEX := C1X + PinEnterOffEN[1]
    EEY := C1Y + PinEnterOffEN[2]
    IsEN := FindPattern(SecEnterENText, EEX - 80, EEY - 45, EEX + 80, EEY + 45, &TX, &TY)
    LogFind("login: client is " (IsEN ? "EN" : "CN"))
    BoxOff := IsEN ? PinBoxOffEN : PinBoxOff
    LoginStatus("输入二次密码…")
    LoginSleep(300)
    ; 先点右边的长方形密码框，再按二次密码的顺序点数字
    LoginClick(C1X + BoxOff[1], C1Y + BoxOff[2])
    LoginSleep(400)
    Loop Parse, Pwd2 {
        P := Cells[A_LoopField]
        LoginClick(P[1], P[2])
        LoginSleep(250)
    }
    if (IsEN) {
        ; 英文版没有点亮图案可等：等它点亮一会儿，直接按位置点 Enter
        LoginStatus("点击“Enter”…")
        LoginSleep(600)
        LogFind("login: EN client, click 'enter' by grid offset at (" EEX "," EEY ")")
        LoginClick(EEX, EEY)
        return true
    }
    ; 输完后“输入”按钮会变亮，在它该在的位置附近等它亮；一直没亮就按位置点一下
    LoginStatus("点击“输入”…")
    EX := C1X + PinEnterOff[1]
    EY := C1Y + PinEnterOff[2]
    if (FindWaitInRect(SecEnterText, &FX, &FY, EX - 80, EY - 45, EX + 80, EY + 45, 4000)) {
        LogFind("login: bright 'enter' at (" FX "," FY ")")
        LoginClick(FX, FY)
    } else {
        LogFind("login: bright 'enter' NOT found, click by grid offset")
        LoginClick(EX, EY)
    }
    return true
}

; 在指定矩形里等一个图案出现（登陆流程专用，等待可被 Esc 中断）。
FindWaitInRect(Text, &CX, &CY, X1, Y1, X2, Y2, TimeoutMs) {
    Start := A_TickCount
    Loop {
        if (FindPattern(Text, X1, Y1, X2, Y2, &CX, &CY)) {
            return true
        }
        if (A_TickCount - Start >= TimeoutMs) {
            return false
        }
        LoginSleep(200)
    }
}

; 找二次密码键盘：用 DigitText 图案（从她逐个截的数字图生成的）在整个游戏窗口里
; 逐个数字找命中，再按格距拼图。命中最少的数字最可信，拿它当锚：把它轮流当作
; 10 个格子中的每一个，推出整盘的原点，再看其余每个密码数字是不是都恰好落在
; 一个还没被占的格子上。全部落得上才算找到这盘键盘；拼不成，一个键都不点。
; 成功时 Cells 是 数字->[点击X, 点击Y]，C1X/C1Y 是第 1 格中心
; （密码框和“输入”按钮的位置都从它推）。
HuntPinKeypad(Need, &Cells, &C1X, &C1Y) {
    global DigitText, PinErr1, PinErr0, PinDigitOff, PinCellOff, PinHuntNote
    LoginRegion(&X1, &Y1, &X2, &Y2)
    ByDigit := Map()
    Counts := ""
    for D, _ in Need {
        FX := 0
        FY := 0
        Matches := ""
        try Matches := FindText(&FX, &FY, X1, Y1, X2, Y2, PinErr1, PinErr0, DigitText[D])
        List := []
        if (IsObject(Matches)) {
            for _, M in Matches {
                List.Push({X: M.mx + PinDigitOff[D][1], Y: M.my + PinDigitOff[D][2], Bad: false})
                if (List.Length >= 30) {
                    break
                }
            }
        }
        ByDigit[D] := List
        Counts .= D ":" List.Length " "
        if (List.Length = 0) {
            ; 快速失败：有一个数字一个命中都没有，键盘肯定不在，
            ; 不用再扫剩下的数字（键盘不在时一轮只扫一遍窗口）。
            LogFind("login: pin hunt matches " Counts "(stopped early)")
            PinHuntNote := "命中 " Counts "（数字 " D " 一个都没找到）"
            return false
        }
    }
    LogFind("login: pin hunt matches " Counts)
    ; 标注每个命中是不是被别的数字图案在同一位置也认出来了（串认的命中会被抢认，
    ; 真命中不会——见 PinCellContested），放数字时优先用没被抢认的。
    for D, _ in Need {
        for _, M in ByDigit[D] {
            M.Bad := PinCellContested(M.X, M.Y, D)
        }
    }
    ; 命中数从少到多排顺序：先放最可信的，锚也用第一个
    Order := []
    for D, _ in Need {
        Order.Push(D)
    }
    Loop Order.Length - 1 {
        I := A_Index
        Loop Order.Length - I {
            J := A_Index
            if (ByDigit[Order[J + 1]].Length < ByDigit[Order[J]].Length) {
                Tmp := Order[J]
                Order[J] := Order[J + 1]
                Order[J + 1] := Tmp
            }
        }
    }
    AnchorD := Order[1]
    AnchorList := []
    for _, M in ByDigit[AnchorD] {
        if (!M.Bad) {
            AnchorList.Push(M)
        }
    }
    for _, M in ByDigit[AnchorD] {
        if (M.Bad) {
            AnchorList.Push(M)
        }
    }
    for _, A in AnchorList {
        Loop 10 {
            K := A_Index - 1
            OX := A.X - PinCellOff[K + 1][1]
            OY := A.Y - PinCellOff[K + 1][2]
            if (OX < 4 || OY < 4 || OX + 108 > A_ScreenWidth || OY + 144 > A_ScreenHeight) {
                continue
            }
            Placed := Map()
            Placed[AnchorD] := [A.X, A.Y]
            UsedCells := Map()
            UsedCells[K] := true
            OK := true
            for _, D in Order {
                if (D = AnchorD) {
                    continue
                }
                Pick := ""
                Loop 2 {
                    WantBad := (A_Index = 2)
                    for _, M in ByDigit[D] {
                        if (M.Bad != WantBad) {
                            continue
                        }
                        Col := Round((M.X - OX) / 36)
                        Row := Round((M.Y - OY) / 36)
                        if (Col < 0 || Col > 2 || Row < 0 || Row > 3) {
                            continue
                        }
                        if (Abs(M.X - (OX + Col * 36)) > 4 || Abs(M.Y - (OY + Row * 36)) > 4) {
                            continue
                        }
                        CellIdx := (Row < 3) ? (Row * 3 + Col) : 9
                        if (Row = 3 && Col != 0) {
                            continue
                        }
                        if (UsedCells.Has(CellIdx)) {
                            continue
                        }
                        Pick := [M, CellIdx]
                        break
                    }
                    if (Pick != "") {
                        break
                    }
                }
                if (Pick = "") {
                    OK := false
                    break
                }
                Placed[D] := [Pick[1].X, Pick[1].Y]
                UsedCells[Pick[2]] := true
            }
            if (OK) {
                Cells := Placed
                C1X := OX
                C1Y := OY
                Desc := ""
                for D, _ in Need {
                    Desc .= D "@(" Placed[D][1] "," Placed[D][2] ") "
                }
                LogFind("login: pin keypad OK, origin=(" OX "," OY ") " Desc)
                PinHuntNote := "命中 " Counts "拼图成功"
                return true
            }
        }
    }
    PinHuntNote := "命中 " Counts "但拼不成一盘"
    LogFind("login: pin hunt: no constellation fits")
    return false
}

; 一个位置是不是也被别的数字的图案认出来了：在它周围一小块地方逐个图案试，
; 哪个图案的命中中心落到这同一个位置（±4），就算被抢认。
; 为什么管用：3 的图案会认错 8 的格子（3 的笔画是 8 的一部分，背景只差几个点），
; 但那个格子会被 8 自己的图案满分认出；反过来真格子不会被任何别的图案认出
; （在 2.jpg、3.jpg 和实屏采样上逐个量过）。所以串认的命中必然被抢认，真命中不会。
PinCellContested(CX, CY, SelfD) {
    global DigitText, PinErr1, PinErr0, PinDigitOff
    Loop Parse, "0123456789" {
        E := A_LoopField
        if (E = SelfD) {
            continue
        }
        FX := 0
        FY := 0
        Matches := ""
        try Matches := FindText(&FX, &FY, CX - 24, CY - 24, CX + 24, CY + 24, PinErr1, PinErr0, DigitText[E])
        if (IsObject(Matches)) {
            for _, M in Matches {
                if (Abs(M.mx + PinDigitOff[E][1] - CX) <= 4 && Abs(M.my + PinDigitOff[E][2] - CY) <= 4) {
                    return true
                }
            }
        }
    }
    return false
}

; ===== 快捷键 =====
; F11 = 桌面轮询 开启 / 停止（再启动从桌面 1 重新开始）
; F12 = 取点时是取点键；平时是开箱子 开启 / 停止（开启时用上次的模式）
F11::ToggleDesktop()
F12::F12Handler()
SC029::ToggleQuickSwitch()

; F12 的分工：取点成功后的 2 秒内按了没反应（防误触）；
; 正在取点就取点；否则当开箱子的开关用。
F12Handler() {
    global CaptureTarget, CaptureTick
    if (CaptureTick && A_TickCount - CaptureTick < 2000) {
        return
    }
    if (CaptureTarget != 0) {
        FinishCapture()
        return
    }
    ToggleClickHotkey()
}

; 取点时按 Esc 取消（只在取点期间生效）
#HotIf CaptureTarget != 0
Esc::CancelCapture()
#HotIf

; 账号登陆进行中按 Esc 取消登陆（只在登陆期间生效）
#HotIf LoginRunning
Esc::StopLogin()
#HotIf

; 快捷切换桌面的键盘：只在开关打开时生效（打开脚本时默认开），
; 关了 F1/F2/F3 就是正常的功能键，不会切桌面。
#HotIf QuickSwitchEnabled
F1::GoToDesktop(0)
F2::GoToDesktop(1)
F3::GoToDesktop(2)
F4::F4Handler()
F5::ToggleRecord()
#HotIf
