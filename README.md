# mac-local-ocr

> **macOS 本地 OCR 工具** —— 零云依赖、纯本地运行、隐私安全
> 三件套：**Apple Vision**（vision-ocr）· **RapidOCR**（rapidocr）· **Tesseract**

一个开箱即用的 Agent Skill + **统一命令行**，让 AI Agent（或人）在 macOS 上**从 0 搭建**一套本地 OCR 工具，识别图片 / 截图 / 扫描件中的文字，中文优先。

---

## 特性

- 🍎 **Apple Vision**：系统内置框架，**零第三方依赖**，M1 原生加速，完全本地
- 🚀 **RapidOCR**：PP-OCR 模型（持续更新），中文识别强，onnxruntime 轻量推理
- 🧩 **Tesseract**：通用兜底，含**标准版**中文语言包（简体 / 繁体 / 竖排）
- 🔒 **纯本地**：所有识别不联网、不上云，隐私安全
- 🌏 **国内友好**：模型 / 语言包下载内置 GitHub 镜像自动切换（ghfast.top / gh-proxy.com），直连超时不怕
- 🛠 **统一命令**：`mac-ocr` 一个命令搞定安装 / 体检 / 识别（纯 Python 单文件，仅标准库）

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

### 统一命令 `mac-ocr`

| 子命令 | 作用 |
|---|---|
| `mac-ocr check` | 体检三件套就绪状态 |
| `mac-ocr setup [--force] [--mirror-url <镜像>] [--bin-dir <目录>] [--venv-dir <目录>]` | 一键安装/修复（`--force` 强制重下语言包） |
| `mac-ocr ocr <图片> [选项]` | Apple Vision 识别（等价旧 vision-ocr） |

**安装路径**（默认中性化，setup 时会打印将要安装到哪）：

| 内容 | 默认 | 修改方式 |
|---|---|---|
| 兼容命令 `vision-ocr` | `~/.local/bin/` | `--bin-dir <目录>` 或环境变量 `MAC_OCR_BIN_DIR` |
| Python venv（pyobjc） | `~/.local/share/mac-ocr/venv` | `--venv-dir <目录>` 或环境变量 `MAC_OCR_VENV_DIR` |

```bash
./scripts/mac-ocr setup --bin-dir ~/bin --venv-dir ~/.venvs/mac-ocr
export MAC_OCR_BIN_DIR=~/bin MAC_OCR_VENV_DIR=~/.venvs/mac-ocr   # 自定义路径需写入 ~/.zshrc 供识别/体检使用
```

兼容性：`mac-ocr 图片.png` 省略子命令时自动按 `ocr` 处理；在 AI agent 等自动化环境执行时，环境可能注入 `--bypass=platform/agent/task` 形式的确认参数（三段式，每段为字母数字或 `._-`），本命令自动静默接受，不影响使用。

---

## 使用指南

### 按场景选工具

| 场景 | 工具 | 命令 |
|---|---|---|
| 日常 / 隐私 / 轻量 | **vision-ocr** | `mac-ocr ocr 图片.png` |
| 中文 / 多语言强识别 | **rapidocr** | `rapidocr -img 图片.png` |
| 通用 / 英文 / 竖排 | **tesseract** | `tesseract 图片.png stdout -l chi_sim` |

### vision-ocr（Apple Vision）

```bash
mac-ocr ocr img.png                  # 中文+英文（默认 zh-Hans）
mac-ocr ocr img.png --lang zh-Hant   # 繁体
mac-ocr ocr img.png --lang en-US     # 仅英文
mac-ocr ocr img.png --json           # JSON（文本+置信度+坐标）
mac-ocr ocr img.png --level accurate # 精确模式
mac-ocr ocr img.png --debug          # 输出带检测框的图片
```

> `mac-ocr setup` 会生成兼容命令 `vision-ocr`（默认装到 `~/.local/bin/`），习惯旧写法可直接 `vision-ocr img.png`。

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

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# uv
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 1. Tesseract + 中文语言包

```bash
brew install tesseract                 # 自带 eng（英文）
./scripts/mac-ocr setup                # 自动下载标准版中文语言包
```

语言包说明：tesseract 中文模型自 2018 年后官方未重训，`tesseract-lang` 的 685MB 语言包是 fast 版。本项目 `mac-ocr setup` 只下载**标准版**（chi_sim / chi_tra / 竖排，共约 100MB），放 `/opt/homebrew/share/tessdata/`。

> 网络提示：国内直连 GitHub raw 常超时。`mac-ocr setup` 内置 `ghfast.top` / `gh-proxy.com` 镜像自动切换；如需指定：`./scripts/mac-ocr setup --mirror-url https://gh-proxy.com`（或环境变量 `MAC_OCR_MIRROR_URL=...`）。

### 2. vision-ocr（Apple Vision）

```bash
./scripts/mac-ocr setup                # 自动：uv venv + pyobjc + 生成 vision-ocr 兼容命令
```

原理：用 pyobjc 桥接系统 Vision 框架，`VNRecognizeTextRequest` 识别，完全本地、零第三方 OCR 依赖。`mac-ocr` 本体仅用 Python 标准库（系统 python3 即可跑 setup/check），识别时自动用 venv python 运行引擎。

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
    └── mac-ocr               # 统一命令行（Python 单文件）：setup / check / ocr
```

### 给 agent 的选型规则

```
用户要识别图片/截图/扫描件文字
  ├─ 日常/轻量/隐私 → mac-ocr ocr 图片.png
  ├─ 中文/多语言强  → rapidocr
  ├─ 英文/竖排/通用 → tesseract
  └─ 环境缺失      → 先 mac-ocr check，再按提示 mac-ocr setup
```

---

## FAQ

**Q: 为什么不用 PaddleOCR 全家桶？**
A: PaddleOCR 完整版需安装 paddlepaddle 深度学习框架（数百 MB + 高内存）。本项目用 RapidOCR（同一套 PP-OCR 模型 + onnxruntime），轻量得多；要最轻就用 vision-ocr（零依赖）。

**Q: 为什么统一成一个命令？**
A: 之前是 `setup.sh` + `ocr-check.sh` + `vision_ocr.py` 三个脚本三种职责。现统一为 `mac-ocr` 单文件 Python：安装 / 体检 / 识别一个命令搞定，公开使用者只需记一个命令。OCR 引擎必须用 Python（Apple Vision 框架无 shell 接口），所以全项目归一为 Python。

**Q: tesseract 中文识别有空格（`简 体 中 文`）？**
A: 正常现象，tesseract 中文输出字间带空格，不是 bug；处理时去掉空格即可。

**Q: 敏感图片能用吗？**
A: 本项目全部本地识别，不上云。但注意：**下载模型/语言包时不要走第三方代理下载敏感文件**；模型本身是公开文件无风险。

---

## License

MIT
