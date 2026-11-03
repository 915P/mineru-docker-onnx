#!/bin/bash
# MinerU 引擎容器启动脚本 —— api-server(8000) + WebUI(7860) 一体
# 模型已烤进镜像（自包含），宿主只需持久化解析产物输出目录
set -e

CONTAINER=mineru-webui
OUT_DIR="$HOME/.local/share/mineru-output"
mkdir -p "$OUT_DIR"

docker rm -f "$CONTAINER" 2>/dev/null || true

docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  --device /dev/dri/renderD128 \
  --device /dev/dri/card1 \
  -p 7860:7860 -p 8000:8000 \
  --shm-size 4g \
  -v "$OUT_DIR:/output" \
  mineru:onnx \
  sh -c 'mineru-kit api-server --host 0.0.0.0 --port 8000 --tier standard & exec mineru-kit webui --server-name 0.0.0.0 --server-port 7860'

echo "引擎已启动:"
echo "  WebUI:      http://127.0.0.1:7860  (浏览器界面)"
echo "  API Server: http://127.0.0.1:8000  (程序调用)"
echo "  产物输出:   $OUT_DIR"
echo "  停止: docker stop $CONTAINER"