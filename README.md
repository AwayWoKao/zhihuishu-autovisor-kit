# 智慧树刷课工具包 (zhihuishu-autovisor-kit)

智慧树（知到）网课**自动播放 + 一键加课**工具包。核心自动化程序是开源项目
[Autovisor](https://github.com/CXRunfree/Autovisor)（作者 **CXRunfree**），本仓库**不包含**它的程序本体，
而是提供一套更省事的部署与使用外壳：

- **一键部署** `setup.ps1`：自动从官方 Release 下载并配置好（内置多个加速镜像回退，国内网络可用）
- **剪贴板加课**：复制课程链接 → 双击启动器 → 自动写入清单并去重
- **多课程顺序刷**：一次配置，按清单依次刷完
- **自动续播**：自动播放、自动切下一章、自动关闭防挂机弹题、静音、指定倍速

> 之所以不把程序本体放进仓库：一是作者未标注开源许可（默认保留所有权利），二是 38MB 二进制会让仓库永久膨胀。
> 请到 [Autovisor 项目页](https://github.com/CXRunfree/Autovisor) 支持原作者。

---

## 快速开始

```powershell
# 1. 克隆仓库
git clone https://github.com/AwayWoKao/zhihuishu-autovisor-kit.git
cd zhihuishu-autovisor-kit

# 2. 一键部署(下载官方 Autovisor 并放好启动器)
powershell -ExecutionPolicy Bypass -File setup.ps1
```

也可以直接下载本仓库的 ZIP 解压后，右键 `setup.ps1` → **使用 PowerShell 运行**。

3. 进入生成的 `Autovisor` 目录，**双击 `启动刷课.bat`**
4. 浏览器登录智慧树 → 打开要刷的**课程视频播放页** → 复制地址栏链接（形如
   `https://studyvideoh5.zhihuishu.com/stuStudy?recruitAndCourseId=...`）
5. 再次双击 `启动刷课.bat`（自动读取剪贴板）→ 回车启动

**多门课**：多个链接分行复制到剪贴板，一次全部加入；重复链接自动去重。

---

## 仓库结构

```
zhihuishu-autovisor-kit/
├─ setup.ps1           # 一键部署: 下载官方 Autovisor + 放入启动器
├─ 启动刷课.bat         # 双击入口(调用 add-course.ps1)
├─ add-course.ps1      # 启动器: 读剪贴板加课、去重、启动/重启
├─ config.ini.example  # 配置模板(留空即可, 首次启动手动登录一次)
└─ README.md
```

部署完成后 `Autovisor/` 目录结构：

```
Autovisor/
├─ Autovisor.exe       # 核心程序(第三方, 来自官方 Release)
├─ config.ini          # 你的配置
├─ 启动刷课.bat / add-course.ps1
├─ data/cookies.json   # 登录凭证(本地保存, 请勿外传)
├─ logs/               # 运行日志
└─ internal/ resources/ packages/   # 运行时与依赖
```

---

## config.ini 常用项

| 配置项 | 默认 | 说明 |
| --- | --- | --- |
| `URL1..URLn` | 空 | 课程清单，按顺序依次刷；一般由启动器自动写入 |
| `username` / `password` | 空 | 填写可实现全自动登录；留空则首次手动登录一次（推荐扫码） |
| `limitSpeed` | 1.0 | 播放倍速，最高 1.8。部分学校超倍速不计时长，1.0 最稳 |
| `limitMaxTime` | 0 | 单门课限制时长（分钟），0 = 不限制 |
| `enableHideWindow` | False | True = 窗口移出屏幕，可后台刷（最小化会导致进度不涨，不要用最小化） |
| `soundOff` | True | 静音播放（浏览器自动播放要求静音） |
| `enableAutoCaptcha` | True | 自动过登录滑块验证 |

---

## 注意事项

- **不要最小化**浏览器窗口：会停止渲染、时长不增长。想后台刷就开 `enableHideWindow`
- **电脑不要睡眠**，否则进度停止
- 弹题会被自动关闭，但不是实时检测；长时间卡住时重启程序即可
- `data/cookies.json` 是你的登录凭证，**不要提交到任何仓库或发给别人**
- 杀毒软件可能对未签名程序误报，加入信任区即可

## 常见问题

**Q: 报错 `Connection closed while reading from the driver`，日志里 `node.exe` APPCRASH？**

这是内置 Playwright 驱动（Node.js）在启动瞬间崩溃。实测排查结论：
文件哈希与官方发行版一致（非损坏、非杀软拦截），但**在个别具体路径下启动即崩**——
同一个文件换目录或改名后完全正常。处理办法：**换一个目录重新部署**（例如 `D:\zhs`），
或删掉目录后重新运行 `setup.ps1`。

**Q: 卡在加载播放页 / 识别不到课时？**

多为新版页面结构未适配（例如带 AI 角标的课程）。目前支持智慧共享课、翻转课、融合共享课；
纯 PPT/PDF 章节没有视频，需要手动切到视频章节。

**Q: 登录时一直等待？**

`[course-url]` 要填**课程播放页**地址（能直接看到视频的页面），不要填课程首页。

---

## 免责声明

- 本项目仅为**个人学习与浏览器自动化技术研究**之用；请在使用前确认符合你所在学校、平台的规定
- 使用自动化工具刷课可能违反平台服务条款，并可能导致学习记录异常，**风险由使用者自负**
- 核心程序 [Autovisor](https://github.com/CXRunfree/Autovisor) 版权归原作者 **CXRunfree** 所有，
  本仓库不分发其程序本体，请遵守原项目的许可与要求
