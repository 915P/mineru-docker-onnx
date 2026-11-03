# mineru-docker-onnx

MinerU 4.x 的 Docker 部署，走 **ONNX / WebGPU（Vulkan）** 路线：不依赖 NVIDIA 显卡，
有 Intel / AMD 现代核显时可自动尝试 GPU 加速，没有也能纯 CPU 跑。
一个容器同时提供 **Gradio WebUI**（浏览器界面）和 **V1 API Server**（供程序调用）。

一份实测记录（含核显校准数据和三个网络坑的成因）：
<https://915p.github.io/blog/20261103-mineru-docker-onnx/>

## 特点

- 官方 Docker 流程面向 NVIDIA GPU，本仓库是非 N 卡环境的替代方案
- 基于 Ubuntu 24.04（`mesa-vulkan-drivers` 25.x，认得 Arrow Lake / Battlemage 等新核显）
- ONNX 设备启动时自动校准：核显跑小模型若不如 CPU，自动回落 CPU（实测数据见博客）
- VLM（standard 档）走 llama.cpp + Vulkan，独立于小模型的设备选择
- 模型持久化在宿主 `~/.mineru-docker`，容器重建不重新下载
- `--restart unless-stopped`，开机自动恢复

## 快速开始

```bash
# 1. 构建镜像（约 2GB；国内网络可加镜像加速参数，见下）
docker build -t mineru:onnx .

# 2. 创建并启动容器
bash run_webui.sh

# 3. 使用
#    WebUI: http://127.0.0.1:7860
#    API:   http://127.0.0.1:8000/v1/health
```

日常启停：

```bash
docker start mineru-webui
docker stop  mineru-webui
```

### 国内网络加速（可选）

基础镜像官方源不通时：

```bash
docker build -t mineru:onnx \
  --build-arg BASE_IMAGE=docker.1ms.run/library/ubuntu:24.04 .
```

Dockerfile 内已将 apt 与 pip 指向中科大镜像源（IPv4 主站，容器内无 IPv6 时也可用）。
若你的网络访问 HuggingFace 不畅，可加环境变量 `MINERU_MODEL_SOURCE=modelscope`（默认已设）。

## 目录说明

| 文件 | 用途 |
|------|------|
| `Dockerfile` | 镜像定义（Ubuntu 24.04 + Vulkan 驱动 + MinerU 基础包） |
| `run_webui.sh` | 一键创建容器（api-server + WebUI 一体，含持久化挂载） |
| `textbook_sample.pdf` | 自制的一页测试稿（标题/列表/表格），用于验证解析效果 |

## 模型与产物位置

| 内容 | 路径 |
|------|------|
| 模型（约 1.9GB，OCR 小模型 + 1.2B VLM） | `~/.mineru-docker/models/` |
| ONNX 设备校准记录 | `~/.mineru-docker/config.yaml.onnx-calibration.json` |
| 容器内输出目录（挂载） | `~/.mineru-docker/output/` |

## 调用 API

```bash
curl http://127.0.0.1:8000/v1/health
# 创建任务 → PUT 上传 → GET /v1/tasks/{id} 轮询 → files[].result_url 下载
```

接口契约见 MinerU 官方文档的 V1 HTTP API / Tasks 章节。

## License

MIT（MinerU 本体遵循其自身许可证，本仓库只包含部署配置）