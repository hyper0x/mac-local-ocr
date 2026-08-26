---
name: mac-local-ocr
description: macOS 本地 OCR 工具（文字识别），三件套：Apple Vision（vision-ocr，零依赖）、RapidOCR（rapidocr，PP-OCR 模型）、Tesseract（tesseract，含标准版中文语言包）。当用户需要识别图片/截图/扫描件中的文字、要 OCR 一张图/PDF、或要在 macOS 上从 0 搭建本地 OCR 环境时使用。触发词：OCR、识别图片文字、提取文字、文字识别、vision-ocr、rapidocr、tesseract。
---

# mac-local-ocr — macOS 本地 OCR 工具

## 何时使用

- 用户要识别图片 / 截图 / 扫描件中的文字
- 用户要在 macOS 上搭建或检查本地 OCR 环境
- 关键词：OCR、识别图片文字、提取文字、文字识别

## 统一入口 `mac-ocr`

本项目所有操作统一走一个命令 `<skill目录>/scripts/mac-ocr`（单文件 Python，仅标准库，系统 python3 直接可跑）：

| 子命令 | 作用 |
|---|---|
| `mac-ocr check` | 体检三件套就绪状态 |
| `mac-ocr setup [--force]` | 一键安装/修复三件套（幂等，可重复跑） |
| `mac-ocr ocr <图片>` | Apple Vision 识别（等价旧 vision-ocr） |

> 兼容性：`mac-ocr 图片.png` 省略子命令时自动按 `ocr` 处理；外部环境可能注入额外确认参数，本命令会自动忽略，不影响使用。

## 第一步：检查就绪状态

```bash
<skill目录>/scripts/mac-ocr check
```

缺失的按输出提示补，或直接跑 `mac-ocr setup`。

## 选型（按场景优先）

| 场景 | 工具 | 命令 |
|---|---|---|
| 日常 / 隐私 / 轻量 | **vision-ocr** | `mac-ocr ocr 图片.png` |
| 中文 / 多语言强识别 | **rapidocr** | `rapidocr -img 图片.png` |
| 通用 / 英文 / 批量 / 竖排 | **tesseract** | `tesseract 图片.png stdout -l chi_sim` |
| 扫描版 PDF | pdf skill（底层 pytesseract） | 走 pdf skill |

## 工具用法

### vision-ocr（Apple Vision，零依赖，本地）
```bash
mac-ocr ocr img.png                    # 中文+英文（默认 zh-Hans）
mac-ocr ocr img.png --lang zh-Hant     # 繁体
mac-ocr ocr img.png --lang en-US       # 仅英文
mac-ocr ocr img.png --json             # JSON：文本+置信度+坐标
mac-ocr ocr img.png --level accurate   # 精确模式
mac-ocr ocr img.png --debug            # 输出带检测框的图片
```
> `setup` 会生成兼容命令 `vision-ocr`（默认装到 `~/.local/bin/`），旧习惯直接 `vision-ocr img.png` 也可。

### rapidocr（RapidOCR / PP-OCR 模型，中文强）
```bash
rapidocr -img img.png             # 输出文本+置信度+坐标+耗时
```

### tesseract（通用，自带标准版中文语言包）
```bash
tesseract 图片.png stdout -l chi_sim        # 简体
tesseract 图片.png stdout -l chi_tra        # 繁体
tesseract 图片.png stdout -l chi_sim_vert   # 简体竖排
tesseract 图片.png stdout -l chi_tra_vert   # 繁体竖排
```

## 从 0 搭建（新机器 / 新环境）

完整分步教程见 `README.md`。一键脚本：

```bash
<skill目录>/scripts/mac-ocr setup
```

三部分：
1. **Tesseract**：`brew install tesseract`（自带 eng）+ 标准版中文语言包（chi_sim / chi_tra / 竖排，走国内镜像自动下载，幂等可重复）
2. **vision-ocr**：建专用 venv + 装 pyobjc（Vision/Quartz/Cocoa）+ 生成兼容命令 `vision-ocr`
3. **rapidocr**：`uv tool install rapidocr --with onnxruntime`

## 踩过的坑（务必遵守）

1. **rapidocr 必须带 `--with onnxruntime`**：`uv tool install rapidocr` 默认不装推理引擎，一跑就报
   `ImportError: onnxruntime is not installed`。修复：`uv tool install rapidocr --with onnxruntime`（`mac-ocr setup` 已内置）
2. **国内直连 GitHub raw 超时**：模型/语言包下载走 `ghfast.top` / `gh-proxy.com` 镜像（`mac-ocr setup` 已内置自动切换，可用 `BASE_URL=<镜像>` 覆盖）。敏感文件不要走第三方代理
3. **tesseract 中文模型 2018 年后官方未重训**：中文质量一般；要强中文用 rapidocr 或 vision-ocr
4. **中文识别输出字间带空格**（`简 体 中 文`）是 tesseract 正常格式，不是 bug
