#!/bin/bash
# mac-local-ocr 冒烟测试
# 前提：环境已就绪（mac-ocr setup 已跑过）；本机或 CI 均可跑
# 用法：bash tests/smoke.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
VENV_PY3="${MAC_OCR_VENV_DIR:-$HOME/.local/share/mac-ocr/venv}/bin/python3"
MAC="$ROOT/scripts/mac-ocr"
VO="$ROOT/scripts/vision-ocr"
PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); echo "  ✅ $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }

echo "[1/6] 语法编译"
if python3 -m py_compile "$MAC" "$VO"; then ok "py_compile"; else bad "py_compile"; fi

echo "[2/6] 生成测试图（venv AppKit 渲染）"
cat > "$TMP/mkimg.py" <<'EOF'
import sys
import AppKit
import Foundation

text, out = sys.argv[1], sys.argv[2]
img = AppKit.NSImage.alloc().initWithSize_((900, 300))
img.lockFocus()
AppKit.NSColor.whiteColor().set()
AppKit.NSRectFill(Foundation.NSMakeRect(0, 0, 900, 300))
s = AppKit.NSAttributedString.alloc().initWithString_attributes_(text, {
    AppKit.NSFontAttributeName: AppKit.NSFont.systemFontOfSize_(56),
    AppKit.NSForegroundColorAttributeName: AppKit.NSColor.blackColor()})
s.drawAtPoint_(Foundation.NSMakePoint(50, 120))
img.unlockFocus()
rep = AppKit.NSBitmapImageRep.imageRepWithData_(img.TIFFRepresentation())
rep.representationUsingType_properties_(AppKit.NSBitmapImageFileTypePNG, None).writeToFile_atomically_(out, True)
EOF
if "$VENV_PY3" "$TMP/mkimg.py" "Smoke Test 13579" "$TMP/smoke.png" 2>/dev/null; then
    ok "生成测试图"
else
    bad "生成测试图失败（venv: ${VENV_PY3}）"
    echo "===== 冒烟结果: PASS=$PASS FAIL=$FAIL ====="
    exit 1
fi

echo "[3/6] vision-ocr 识别"
out="$("$VO" "$TMP/smoke.png" 2>/dev/null)"
if [ -n "$out" ] && echo "$out" | grep -q "Smoke"; then
    ok "识别结果含锚点 Smoke（${out}）"
else
    bad "识别结果不含锚点: $out"
fi

echo "[4/6] vision-ocr --json 结构"
if "$VO" "$TMP/smoke.png" --json 2>/dev/null | python3 -c \
    'import json,sys; d=json.load(sys.stdin); assert d and all(k in d[0] for k in ("text","confidence","bbox"))'; then
    ok "JSON 含 text/confidence/bbox"
else
    bad "JSON 结构异常"
fi

echo "[5/6] 错误路径与参数"
"$VO" "$TMP/nope.png" >/dev/null 2>"$TMP/err"; rc=$?
if [ "$rc" -eq 1 ] && grep -q "文件不存在" "$TMP/err"; then
    ok "文件不存在 -> exit 1 + 明确报错"
else
    bad "期望 exit 1 + '文件不存在'，got rc=$rc: $(cat "$TMP/err")"
fi
"$VO" >/dev/null 2>&1
if [ $? -ne 0 ]; then ok "缺参 -> 非零退出"; else bad "缺参应报错"; fi
if "$VO" --version 2>/dev/null | grep -q "vision-ocr"; then ok "--version"; else bad "--version"; fi
if "$VO" "$TMP/smoke.png" --bypass=ci/forge/smoke-test >/dev/null 2>&1; then
    ok "--bypass 注入静默通过"
else
    bad "--bypass 注入应被接受"
fi
"$MAC" vision "$TMP/smoke.png" >/dev/null 2>&1
if [ $? -ne 0 ]; then ok "旧子命令 mac-ocr vision 已移除（报错）"; else bad "mac-ocr vision 应报错"; fi

echo "[6/6] mac-ocr check 退出码"
"$MAC" check >/dev/null 2>&1
if [ $? -eq 0 ]; then ok "check 全绿 -> exit 0"; else bad "check exit != 0（环境未就绪？跑 mac-ocr setup）"; fi

echo
echo "===== 冒烟结果: PASS=$PASS FAIL=$FAIL ====="
[ "$FAIL" -eq 0 ]
