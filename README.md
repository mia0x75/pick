# Pick 片刻 (Pick Player)

极简 Android TV 视频播放器 —— 直达内容，隐形安全，云端同步。

## 特性

- **极简三行布局**：手风琴预览、最近播放、资源中心
- **隐形安全域**：遥控器暗号 + 蓝牙近场感应解锁隐藏资源
- **云端无缝联动**：WebDAV 多设备进度同步与推片接力

## 技术栈

- Flutter 3.19+
- media_kit (mpv 引擎)
- Hive (本地存储)
- WebDAV / SMB / BLE

## 云端开发模式

本项目采用 **Cloud-Only Development** 模式：
- 本地零 SDK 依赖，仅用于代码编写
- 所有编译、分析、打包通过 GitHub Actions 完成
- 下载 APK 至电视真机测试

## 快速开始

```bash
# 安装依赖
flutter pub get

# 推送代码触发 CI
git push origin main

# 下载构建产物
# 前往 GitHub Actions → Artifacts 下载 APK
```

## CI 触发器

| 事件 | 行为 |
|------|------|
| `push` to main/develop | `flutter analyze` + Debug APK |
| `tag` (v*) | Release APK (签名) + 自动发布 |

## 签名配置

Release 构建需要以下 Secrets：
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`
