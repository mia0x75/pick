# SKILL.md — Pick 片刻 (Pick Player) 能力清单

## 0. 核心原则 (Core Principles)
- **TV First**: 严禁使用任何依赖触摸交互的逻辑（如 `GestureDetector`, `InkWell.onTap`）。所有交互必须通过 `Focus` 节点的 `onKeyEvent` 或 `KeyboardListener` 完成，响应 `LogicalKeyboardKey.select` / `enter` / `space`。
- **Memory Efficiency**: 电视内存有限。Row 1 的 `VideoController` 必须是全局单例或在失去焦点时立即 `dispose()` 并释放纹理，获取焦点时重新创建。
- **零触摸声明**: 任何 UI 组件不得包含 `onTap`, `onLongPress`, `onPan` 等触摸回调。
- **无常驻导航栏**: 无底部导航栏，无侧边栏（仅设置 End Drawer 例外）。

---

## 1. D-Pad 导航专家

> 熟练使用 `FocusNode`, `FocusTraversalGroup` 确保遥控器操作无死角。

### FocusNode 生命周期
- 每个可交互 Widget 绑定独立 `FocusNode`，在 `dispose` 时释放
- 使用 `FocusScope` 管理焦点子树，避免焦点逃逸
- 焦点事件统一通过 `onKeyEvent` 处理，返回 `KeyEventResult.handled` 或 `ignored`

### 焦点树导航
- 使用 `FocusTraversalGroup` + `ReadingOrderTraversalPolicy` 控制上下左右导航顺序
- 横向行使用 `OrderedTraversalPolicy` 确保水平方向优先
- 纵向列使用默认策略确保垂直方向优先
- **跨行导航**：通过 `FocusTraversalPolicy` 的 `requestFocusForDirection` 精确控制行列切换锚点

### 缩放与高亮动画
- 获取焦点时 `Transform.scale(1.08)` + `BoxShadow`（橙色光晕 `#FF6B35`）
- 失焦时平滑恢复 1.0 + 移除阴影
- 动画时长 150ms，曲线 `Curves.easeOut`

### 自动滚动
- `Scrollable.ensureVisible` 确保焦点项始终在可视区域内
- 滚动动画 200ms，对齐系数 0.5（居中）
- Row 1 展开时调用 `ScrollController.animateTo` 确保聚焦项居中

### 跳过隐藏项
- `FocusNode(skipTraversal: true)` 用于不可见/未解锁的 Widget
- 未解锁的资源卡片不参与焦点树，防止用户感知到隐藏内容

### 遥控器操作无死角检查清单
- [ ] 所有可点击元素均可通过 D-Pad 到达
- [ ] 焦点不会进入空白区域或死胡同
- [ ] 长按/组合键有明确反馈
- [ ] 返回键正确处理页面层级
- [ ] 菜单键 (contextMenu / M) 触发行内操作

---

## 2. 异步流专家

> 处理 WebDAV 分段读取与 `media_kit` 纹理渲染。

### WebDAV 分段读取
- 使用 `webdav_client` 的 `read()` 方法获取 `Stream<List<int>>`
- **缓存策略**：目录列表结果缓存 60s（Hive），文件流直接转发至播放器
- **断线重试**：指数退避重试（最多 3 次），超时 15s
- **分块读取**：大文件按 64KB 分块，避免内存溢出

### media_kit 纹理渲染
- `media_kit` 基于 mpv 引擎，支持 4K HDR 硬解
- 使用 `VideoController` + `Video` Widget 渲染视频纹理
- **硬件加速**：启用 `--hwdec=mediacodec-copy` 实现 Android 硬解
- **字幕支持**：外挂 `.srt` / `.ass` 自动加载（同目录同名文件）
- **音轨切换**：通过 `mpv` 命令 `cycle audio` 切换多音轨

### 流式播放管线
```
WebDAV/SMB/FTP Stream → BufferedStream (预读 5MB) → media_kit Player → Video Widget
```
- 预读缓冲：启动时预加载 5MB，播放中维持 3MB 安全缓冲
- 拖拽跳转：先暂停 → 发送 `seek` 命令 → 清空缓冲 → 从新位置重新预读

### Protocol Handlers 策略
- **浏览文件**：使用 `smb_connector`、`ftpconnect`、`webdav_client` 获取文件树。
- **播放文件**：只要获取了文件的完整路径（如 `smb://user:pass@192.168.1.5/movie.mkv`），直接扔给 `media_kit`。底层 **ffmpeg/mpv** 核心已内置对 SMB、NFS、FTP 的流媒体读取支持。
- **NFS/DLNA**：完全依赖 `media_kit` 内置解析，不额外引入原生插件。

### SMB 协议
- 使用 `smb_connector` 获取目录列表与文件元数据
- **路径映射**：`smb://host/share/path` → 本地缓存树结构
- **认证缓存**：用户名/密码加密后存入 Hive，支持匿名访问

### FTP 协议
- 使用 `ftpconnect` 进行目录列表与文件流读取
- 支持主动/被动模式切换，默认被动模式（PASV）
- 认证信息加密存入 Hive

### NFS 协议
- Flutter 社区无成熟纯 Dart NFS 插件
- **方案**：直接构造 `nfs://` URL 传递给 `media_kit`，利用底层 libmpv/ffmpeg 的原生 NFS 解析能力

### 通用
- 所有网络操作通过 `Stream` 返回，支持取消与进度回调
- 错误统一封装为 `StorageException`（含 `code`, `message`, `recoverable`）

---

## 3. 状态管理

> 维护 `StealthMode` (LOCKED/GLOWING/UNLOCKED) 全局状态。

### 隐私暗号逻辑
- 监听 `LogicalKeyboardKey` 序列。
- 暗号输入状态由全局 `ValueNotifier<StealthMode>` 或 `Riverpod Provider` 管理，**不产生额外的 UI 重绘**。
- 状态变更通过 `notifyListeners()` 触发，UI 仅监听状态流。

### StealthMode 三态机

```
┌─────────┐   长按设置 3s    ┌──────────┐   暗号验证    ┌───────────┐
│ LOCKED  │ ──────────────→ │ GLOWING  │ ────────────→ │ UNLOCKED  │
│  (默认)  │                 │ (待验证)  │               │ (已解锁)   │
└─────────┘                 └──────────┘               └───────────┘
     ↑                          │                           │
     │                          │ 验证失败                   │ 超时 60s
     └──────────────────────────┴───────────────────────────┘
```

| 状态 | 含义 | UI 表现 | 可操作项 |
|------|------|---------|----------|
| `locked` | 默认锁定 | 资源中心隐藏私有节点，设置图标灰色 | 仅三行基础布局 |
| `glowing` | 等待验证 | 设置图标紫色呼吸闪烁，全局监听方向键 | 遥控器暗号输入 |
| `unlocked` | 已解锁 | 资源中心显示私有节点，设置图标常亮橙色 | 全部功能可用 |

### 状态转换触发器
- **locked → glowing**：设置图标长按 ≥ 3s
- **glowing → unlocked**：遥控器暗号正确（默认 ↑↓←→OK）
- **glowing → locked**：暗号错误 3 次 / 用户主动取消 / 超时 30s
- **unlocked → locked**：超时 60s 无操作 / 蓝牙设备远离 / 用户手动上锁

### Riverpod 状态实现
```dart
enum StealthMode { locked, glowing, unlocked }

final stealthProvider = StateNotifierProvider<StealthNotifier, StealthMode>((ref) {
  return StealthNotifier();
});

final nodeProvider = StateNotifierProvider<NodeNotifier, List<StorageNode>>((ref) {
  return NodeNotifier();
});

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, List<FavoriteNode>>((ref) {
  return FavoriteNotifier();
});
```

### 遥控器暗号 (Sequence Keypress)
- **算法**：维护一个固定长度的按键队列（默认 5），每次新按键入队后与预设序列比对
- **超时重置**：两次按键间隔 > 2s 则清空队列
- **默认序列**：`[UP, DOWN, LEFT, RIGHT, ENTER]`（可自定义 4-8 位）

### 蓝牙 RSSI 距离判定
- 使用 `flutter_blue_plus` 扫描指定 BLE 设备
- **RSSI 阈值**：>-60 dBm 视为"近场"（可解锁），<-75 dBm 视为"远场"
- **防抖动**：连续 3 次采样均满足阈值才触发状态变更
- **心跳检测**：每 5s 扫描一次，设备消失 15s 后自动重新上锁

---

## 4. TV UI 适配

> 处理 1080p 屏幕下的 Overscan (边框安全区) 适配。

### UI 规范
- 首页三行布局，行间距固定 `40.h`。
- Row 1 宽度动态变化（Accordion 效果），使用 `Curves.easeOutCubic` 确保动画在低端电视上不卡顿。
- 禁止使用触摸手势，全部替换为焦点/键盘事件。
- 无常驻导航栏。

### 动态背景适配
- **UI 适配基准：1920×1080。**
- 首页背景需根据当前 Focus 项的封面图，利用 `palette_generator` 获取主色调并应用 `BackdropFilter` 实现毛玻璃效果。
- 背景切换动画使用 `AnimatedCrossFade`（300ms），避免焦点快速移动时频繁重绘。
- 实现管线：`FocusNode.hasFocus` → 提取封面 URL → `palette_generator.generate()` → 主色调作为 `BackdropFilter` 的 `ImageFilter.blur` 底色叠加层。

### Overscan 安全区
- 电视屏幕边缘存在 5% 过扫描区域，内容可能被裁切
- **水平安全区**：左右各 96px（基于 1920 宽度 ≈ 5%）
- **垂直安全区**：上下各 54px（基于 1080 高度 ≈ 5%）
- 实现方式：`SafeArea` + 自定义 `EdgeInsets` 组合

### 分辨率适配
- 以 **1920×1080** 为设计基准
- 使用 `flutter_screenutil` 进行等比缩放
- `designSize: const Size(1920, 1080)`
- `minTextAdapt: true` 确保小字号在 TV 上可读
- `splitScreenMode: true` 支持分屏模式

### 字体大小
- TV 观看距离 2-4 米，字体需放大
- 标题 ≥ 22sp，正文 ≥ 16sp，辅助文字 ≥ 14sp
- 使用 `flutter_screenutil` 的 `sp` 单位自动适配

### 焦点指示器
- 焦点边框 2dp 实线，颜色 `#FF6B35`
- 焦点光晕 `BoxShadow` 扩散 16dp，透明度 40%
- 确保在深色背景 (`#0D0D0D`) 下清晰可见

### 布局规范
- **Row 1 (Recently Played)**: 非聚焦 `100.w`，聚焦 `533.w` (16:9)，高 `300.h`
- **Row 2 (Favorites)**: 固定 `200.w × 200.h`
- **Row 3 (Resources)**: 固定 `200.w × 200.h`，末尾固定"+"号
- 行间距 `40.h`

### Performance
- 每行使用 `RepaintBoundary` 包裹，防止行内动画引起整屏重绘
- Row 1 的 `VideoController` 必须是单例或在失去焦点时立即 `dispose()`

---

## 5. 同步机制 (Cloud Sync)

### 数据模型
```json
{
  "device_id": "tv-living-room",
  "progress": {
    "media_id": "webdav://nas/movies/interstellar.mkv",
    "position_sec": 3620,
    "duration_sec": 10140,
    "updated_at": "2024-03-15T20:30:00Z"
  }
}
```

### 合并算法（Last-Write-Wins）
1. 本地与远程进度按 `media_id` 分组
2. 同一 `media_id` 比较 `updated_at`，保留较新记录
3. 冲突时以 `updated_at` 更晚的为准（LWW 策略）
4. 合并后写回 WebDAV 共享文件 `pick_sync.json`

### WebSocket 实时同步
- 电视端启动 WebSocket 服务器（端口 8765）
- 手机端扫码连接后进入极简 Web 编辑页
- 双向实时通信：手机端保存配置 → 电视端自动填充表单
- 断线自动重连（5s 间隔）

### 推片接力 (Relay)
- 手机/其他电视通过 WebSocket 或 WebDAV 写入 relay 请求
- 目标电视检测新 relay 请求
- 弹出"是否播放"通知，确认后直接跳转至指定进度

---

## 6. 云端构建 (GitHub Actions)

- 本地零 SDK，仅保留 `pubspec.yaml` 与代码
- CI 负责 `flutter pub get` → `flutter analyze` → `flutter build apk`
- Release 构建需配置签名 Key（通过 Secrets 注入）

---

## 7. CI/CD 规范
- 每次提交代码后，必须通过 GitHub Actions 验证编译。
- 编译失败时，优先检查 `pubspec.lock` 与原生库依赖（如 `media_kit_libs_video`, `flutter_blue_plus`）。
- 依赖冲突解决顺序：`flutter clean` → `rm pubspec.lock` → `flutter pub get` → 检查 Android `build.gradle` 兼容性。

---

## 8. Android SDK 基准
- **API Level 28 (Android 9)**，兼容鸿蒙 1.0 智慧屏
- `minSdk = 28`, `targetSdk = 34`, `compileSdk = 34`
- 包名：`com.mxu.pick`
