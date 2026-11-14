# v2.0.0

[简体中文](#简体中文) · [English](#english)

## 简体中文

- 初音未来主题和本地 Wi-Fi Boost 合为一个软件中心模块，无需激活或支付。
- 修复登录页裁切：完整显示原包联名标题、边框和底部署名；适配桌面、宽屏与手机竖屏。
- 后台完整角色横幅、初音绿和粉红配色；保留 Merlin 布局。
- 功率读数和滑块同时显示 dBm / mW，增加常驻免责声明和顶部“返回软件中心”按钮。
- 每秒更新双频温度曲线、连接数、分频段及合计上下行速率；保留最近两分钟曲线，后台页面暂停采样。
- 本机校准备份与恢复，兼容 NUL 分隔文件；先逐字节还原校验，再生成候选配置。原插件保留本地回滚备份。

验证：10 项离线用例通过；浏览器测试通过 mW 换算、确认/取消、实时速率合计、计数溢出/重置和后台暂停/恢复。已在 RT-AX86U Pro / Merlin `3006.102.9_0` 安装，确认单模块入口、状态、校准文件只读检查、参数预览和真实实时接口；连续接口耗时约 143–151 ms。登录页桌面、宽屏、手机竖屏均无页面错误和横向溢出。

安装前后校准文件 SHA-256 一致。**没有实际执行功率写入或为测试重启路由器；射频效果和写入后重启流程尚未经本次实机验证。** 安装不会自动改变功率。应用或恢复发生变化的配置需用户确认并重启。

## English

- One software-center module for the full Miku theme and local Wi-Fi Boost, without activation or payment.
- Full branded login artwork and responsive portrait layout; a complete character banner above the Merlin toolbar.
- dBm/mW readings, a visible disclaimer, and a top-level Back to Software Center button.
- One-second dual-band temperature history, connected-client counts, per-band and combined upload/download rates; sampling pauses in background tabs.
- Local backup/restore, lossless NUL-profile conversion, and private legacy-plugin rollback backups.

Validation: 10 offline cases passed. Browser fixtures cover unit conversion, confirmation/cancellation, live-rate totals, counter wrap/reset, and background pause/resume. Installed on RT-AX86U Pro with Merlin `3006.102.9_0`; verified module registration, status, read-only profile checks, previews, live telemetry (approximately 143–151 ms per response), and anonymous login layouts on desktop, wide and portrait screens.

The calibration file hash stayed unchanged. **No actual calibration write or test reboot was performed; RF outcomes and the write/reboot path remain unverified on hardware in this release.** Installation preserves existing power settings. Applying changed settings or restoring requires confirmation and a reboot.
