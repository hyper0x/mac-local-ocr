# mac-local-ocr

> **macOS 本地 OCR 工具** —— 零云依赖、纯本地运行、隐私安全
> 三件套：**Apple Vision** · **RapidOCR**（rapidocr）· **Tesseract**

一个开箱即用的 Agent Skill：`mac-ocr`（安装 / 体检）+ 独立识别命令 `vision-ocr`（Apple Vision），让 AI Agent（或人）在 macOS 上**从 0 搭建**一套本地 OCR 工具，识别图片 / 截图 / 扫描件中的文字，中文优先。

---

## 特性

- 🍎 **Apple Vision**：系统内置框架，**零第三方依赖**，M1 原生加速，完全本地
- 🚀 **RapidOCR**：PP-OCR 模型（持续更新），中文识别强，onnxruntime 轻量推理
- 🧩 **Tesseract**：通用兜底，含**标准版**中文语言包（简体 / 繁体 / 竖排）
- 🔒 **纯本地**：所有识别不联网、不上云，隐私安全
- 🌏 **国内友好**：模型 / 语言包下载内置 GitHub 镜像自动切换（ghfast.top / gh-proxy.com），直连超时不怕
- 🛠 **命令分工**：`mac-ocr` 安装 / 体检（纯 Python 单文件，仅标准库）；识别用独立命令 `vision-ocr`（Apple Vision，setup 自动部署到 PATH）

---

## 快速开始

### 方式一：skills CLI 安装（Agent Skills 生态）

```bash
npx skills add hyper0x/mac-local-ocr
```

装好后进入 skill 目录（全局默认 `~/.agents/skills/mac-local-ocr`），执行：

```bash
./scripts/mac-ocr setup      # 一键安装三件套（幂等，缺什么装什么）
./scripts/mac-ocr check      # 体检，看缺啥
```

### 方式二：手动 clone

```bash
git clone https://github.com/hyper0x/mac-local-ocr.git
cd mac-local-ocr

./scripts/mac-ocr setup
./scripts/mac-ocr check
```

> 前置：需要 [Homebrew](https://brew.sh) 和 [uv](https://docs.astral.sh/uv/)。

### 管理命令 `mac-ocr`（安装 / 体检）

| 子命令 | 作用 |
|---|---|
| `mac-ocr check` | 体检三件套就绪状态 |
| `mac-ocr setup [--force] [--mirror-url <镜像>]` | 一键安装/修复（`--force` 强制重下语言包） |

**识别命令**（setup 自动部署到 `~/.local/bin`，PATH 内任意目录可用）：

| 命令 | 作用 |
|---|---|
| `vision-ocr <图片> [选项]` | Apple Vision 识别（独立命令，见下方使用指南） |

**安装路径**（setup 时会打印将要安装到哪）：

- Python venv（pyobjc）-> `~/.local/share/mac-ocr/venv`
  高级用法：`export MAC_OCR_VENV_DIR=<目录>` 可覆盖（setup / 识别 / 体检同源读取）

兼容性：`mac-ocr` / `vision-ocr` 在 AI agent 等自动化环境执行时，环境可能注入 `--bypass=platform/agent/task` 形式的确认参数（三段式，每段为字母数字或 `._-`），本命令自动静默接受，不影响使用。

---

## 使用指南

### 按场景选工具

| 场景 | 工具 | 命令 |
|---|---|---|
| 日常 / 隐私 / 轻量 | **Apple Vision** | `vision-ocr 图片.png` |
| 中文 / 多语言强识别 | **rapidocr** | `rapidocr -img 图片.png` |
| 通用 / 英文 / 竖排 | **tesseract** | `tesseract 图片.png stdout -l chi_sim` |

### Apple Vision

```bash
vision-ocr img.png                     # 中文+英文（默认 zh-Hans）
vision-ocr img.png --lang zh-Hant      # 繁体
vision-ocr img.png --lang en-US        # 仅英文
vision-ocr img.png --json              # JSON（文本+置信度+坐标）
vision-ocr img.png --level accurate    # 精确模式
vision-ocr img.png --debug             # 输出带检测框的图片
```

### rapidocr（RapidOCR / PP-OCR）

```bash
rapidocr -img img.png   # 输出文本+置信度+坐标+耗时
```

### tesseract

```bash
tesseract 图片.png stdout -l chi_sim        # 简体
tesseract 图片.png stdout -l chi_tra        # 繁体
tesseract 图片.png stdout -l chi_sim_vert   # 简体竖排
tesseract 图片.png stdout -l chi_tra_vert   # 繁体竖排
```

---

## 从 0 搭建（分步教程）

### 0. 前置

#### 0.1 安装 Homebrew

macOS 的包管理器，`mac-ocr setup` 用它安装 Tesseract：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

装完验证：

```bash
brew --version
```

> 国内网络提示：官方安装脚本走 GitHub，可能较慢或超时；可参考 [Homebrew 镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/) 用国内镜像加速。

#### 0.2 安装 uv

Python 包与环境管理工具，`mac-ocr setup` 用它搭建 Apple Vision 的 venv 并安装 OCR 引擎依赖：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

装完重开终端后验证：

```bash
uv --version
```

> uv 官方安装脚本默认装到 `~/.local/bin` 并自动写 shell 配置；若 `uv` 命令未找到，把 `export PATH="$HOME/.local/bin:$PATH"` 加入你的 shell 配置文件（`~/.zshrc` / `~/.bashrc` / `~/.config/fish/config.fish` 等，按实际使用的 shell 选）。

### 1. Tesseract + 中文语言包

```bash
brew install tesseract                 # 自带 eng（英文）
./scripts/mac-ocr setup                # 自动下载标准版中文语言包
```

语言包说明：tesseract 中文模型自 2018 年后官方未重训，`tesseract-lang` 的 685MB 语言包是 fast 版。本项目 `mac-ocr setup` 只下载**标准版**（chi_sim / chi_tra / 竖排，共约 100MB），放到 `/opt/homebrew/share/tessdata/`。

> 网络提示：国内直连 GitHub raw 常超时。`mac-ocr setup` 内置 `ghfast.top` / `gh-proxy.com` 镜像自动切换；如需指定：`./scripts/mac-ocr setup --mirror-url https://gh-proxy.com`（或环境变量 `MAC_OCR_MIRROR_URL=...`）。

### 2. Apple Vision

```bash
./scripts/mac-ocr setup                # 自动：uv venv + pyobjc（Apple Vision 引擎）
```

原理：用 pyobjc 桥接系统 Vision 框架，`VNRecognizeTextRequest` 识别，完全本地、零第三方 OCR 依赖。`mac-ocr` 本体仅用 Python 标准库（系统 python3 即可跑 setup/check）；识别命令 `vision-ocr` 自动用 venv python 运行引擎。

### 3. rapidocr

```bash
./scripts/mac-ocr setup                # 自动：uv tool install rapidocr --with onnxruntime
```

> 坑：`uv tool install rapidocr` 默认不带推理引擎，运行报
> `ImportError: onnxruntime is not installed`。务必带 `--with onnxruntime`（`mac-ocr setup` 已内置）。

---

## 作为 Agent Skill 使用

本仓库即一个标准 Agent Skill（结构见下），将 `SKILL.md` 所在目录放入你的 skill 目录即可被 agent 自动识别、触发式调用：

```
.
├── SKILL.md                  # Skill 入口：触发词、用法、选型、踩坑
├── README.md                 # 本文档
└── scripts/
    ├── mac-ocr               # 安装/体检（Python 单文件）：setup / check
    └── vision-ocr            # Apple Vision 识别（独立命令，Python 单文件）
```

### 给 agent 的选型规则

```
用户要识别图片/截图/扫描件文字
  ├─ 日常/轻量/隐私 → vision-ocr 图片.png
  ├─ 中文/多语言强  → rapidocr
  ├─ 英文/竖排/通用 → tesseract
  └─ 环境缺失      → 先 mac-ocr check，再按提示 mac-ocr setup
```

---

## FAQ

**Q: 为什么不用 PaddleOCR 全家桶？**
A: PaddleOCR 完整版需安装 paddlepaddle 深度学习框架（数百 MB + 高内存）。本项目用 RapidOCR（同一套 PP-OCR 模型 + onnxruntime），轻量得多；要最轻就用 Apple Vision（零依赖）。

**Q: `mac-ocr` 和 `vision-ocr` 什么关系？**
A: 两者分工：`mac-ocr` 负责**安装 / 体检**（setup / check，覆盖三件套）；`vision-ocr` 是**独立识别命令**（Apple Vision），由 `mac-ocr setup` 自动部署到 `~/.local/bin`（PATH 内），识别直接用 `vision-ocr`，不经过 mac-ocr。rapidocr / tesseract 是成熟独立 CLI（各有完整参数体系，如 `rapidocr -img`、`tesseract --psm/-l`），**保留原生命令直接用**，不重复造轮子。按场景选工具：日常轻量用 `vision-ocr`，中文/多语言用 `rapidocr`，英文/竖排用 `tesseract`。

**Q: tesseract 中文识别有空格（`简 体 中 文`）？**
A: 正常现象，tesseract 中文输出字间带空格，不是 bug；处理时去掉空格即可。

**Q: 敏感图片能用吗？**
A: 本项目全部本地识别，不上云。但注意：**下载模型/语言包时不要走第三方代理下载敏感文件**；模型本身是公开文件无风险。

---

## 卸载 / 清理

各组件独立安装，按需单独清理：

```bash
rm ~/.local/bin/vision-ocr                    # 全局识别命令（软链）
rm -rf ~/.local/share/mac-ocr                 # Apple Vision venv（pyobjc）
uv tool uninstall rapidocr                    # rapidocr（含 onnxruntime）
brew uninstall tesseract                      # Tesseract（如不再需要）
rm /opt/homebrew/share/tessdata/chi_*.traineddata   # 本项目下载的 4 个中文语言包
                                              # （Intel Mac 路径为 /usr/local/share/tessdata）
```

---

## License

MIT
