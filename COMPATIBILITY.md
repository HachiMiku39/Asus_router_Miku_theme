# 兼容性 / Compatibility

## 简体中文

v2.1.0 的目标是 **ARMv8 ASUSWRT-Merlin 设备**，不再只允许 RT-AX86U Pro 安装。普通原版 Merlin 需要先有兼容的软件中心；本模块不负责安装软件中心。

安装器检查 CPU/内核信息、软件中心和经典 Merlin 的网页接口。包内没有 ARMv7/ARMv8 型号专用二进制。AArch64/arm64 可直接识别；32 位内核需要 CPU 信息明确为 ARMv8，或设备树指明已识别的 ARMv8 CPU（Cortex-A53/A72）。无法确认时拒绝安装，不通过改机型绕过检测。

各功能分别检测能力：

- **主题**：使用可恢复的网页覆盖，不依赖 Broadcom 无线驱动。不修改型号、CoBrand、无线、路由或防火墙。新 UI4 前端与不同插件的自定义网页尚未逐一验证，不能保证全部控件均已配色。
- **实时监控**：扫描实际存在的 `wl0`–`wl7` 对应接口，依据 `wl*_nband` 和可用的 `wlnband_list` 识别频段。频段顺序不固定；重复 5 GHz / 6 GHz 射频单独显示。关联数合并已配置的虚拟接口并去重；上传/下载按射频驱动计数差值计算。不可读项目显示“暂不可读”，不会伪造为零。计数重置或拓扑变化会重新采样。
- **功率操作**：目前仅适配恰好一组 2.4 GHz + 一组 5 GHz 的 HND 配置。运行时检查 ARMv8、唯一射频映射、HND 挂载工具、校准文件可读、NUL/文本格式的逐字节还原、两个接口与文件内身份一致、已知 `maxp` 字段格式，以及本机备份身份。校验失败则禁用应用和恢复，保留主题及可用监控。
- **三频/四频、6 GHz、其他驱动**：有读数时可监控；功率写入没有适配，页面明确显示只读原因。ARMv8 这一条件不能替代无线芯片和校准格式验证。
- **旧 Wi-Fi Boost**：只在功率兼容检查通过时迁移旧插件。未通过检查的设备保留原插件，避免替代其已有功能。已有私有回滚备份继续保留。

当前实机验证：**RT-AX86U Pro，Merlin `3006.102.9_0`**。其他型号的安装和监控属于按接口检测的理论兼容，仍需要用户设备的实测反馈。模拟测试覆盖频段倒序、三频、6 GHz、接口冲突和不支持的架构；不构成对应硬件的射频效果验证。未在本次测试执行功率写入或为此重启。

参考：[Merlin 网页中的射频发现与标签](https://github.com/RMerl/asuswrt-merlin.ng/blob/main/release/src/router/www/state.js)。实际功能以本机驱动及校准检查结果为准。

## English

v2.1.0 targets **ARMv8 ASUSWRT-Merlin devices**, with an existing compatible software center. Installation no longer uses a model whitelist. The package contains scripts and web assets, not architecture-specific executables. Native AArch64/arm64 and some ARMv8 CPUs running 32-bit kernels are detected through CPU/device-tree evidence.

Capabilities are checked independently:

- The reversible theme requires the expected classic Merlin web interfaces. It does not change the model, CoBrand, network, firewall or radio configuration. UI4 and third-party plugin pages are not fully verified.
- Read-only monitoring discovers existing radio interfaces and band metadata. Reordered radios, multiple 5 GHz radios and 6 GHz have separate cards and graph series. Missing driver readings remain unavailable. Totals include discovered radios; driver counters can be affected by acceleration.
- Calibration writes currently require exactly one 2.4 GHz and one 5 GHz radio with the known Broadcom HND profile/helper interfaces. Interface identity, unique prefixes, format, byte-for-byte round-trip, field schema and device-bound backups are checked. Failed checks disable both apply and restore.
- Tri/quad-band, 6 GHz and other drivers can expose read-only data, but are not supported for calibration writes. Legacy-plugin migration only runs when the power compatibility check passes.

Hardware checks remain limited to **RT-AX86U Pro / Merlin `3006.102.9_0`**. Other devices have theoretical interface-based compatibility, not hardware certification. Fixtures cover reordered/tri-band/6 GHz radios and failure cases. No actual power write or test reboot was performed.

Reference: [Merlin radio discovery and labels](https://github.com/RMerl/asuswrt-merlin.ng/blob/main/release/src/router/www/state.js).
