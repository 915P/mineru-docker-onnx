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
- 模型烤进镜像、自包含：容器重建与镜像分发都不再依赖宿主模型目录
- `--restart unless-stopped`，开机自动恢复

## 快速开始

```bash
# 1. 构建镜像（两种方式，见下）
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

### 构建镜像：两种模型就位方式

**A. 本地已有模型（秒级，不走网络）**：机器上已有 MinerU 模型目录时
（例如旧部署的 `~/.mineru-docker/models`），直接复制进镜像：

```bash
docker build --build-arg MODELS=local \
  --build-context models=你的模型目录 \
  -t mineru:onnx .
```

**B. 从零构建（默认）**：构建时从 ModelScope 下载模型全集
（约 1.9GB：ONNX 小模型 + 1.2B VLM），耗时视网络而定：

```bash
docker build -t mineru:onnx .
```

两种方式在基础镜像官方源不通时，都可加国内镜像加速：

```bash
docker build ... --build-arg BASE_IMAGE=docker.1ms.run/library/ubuntu:24.04 .
```

Dockerfile 内已将 apt 与 pip 指向中科大镜像源（IPv4 主站，容器内无 IPv6 时也可用）。
模型源默认 ModelScope（`MINERU_MODEL_SOURCE`），国内可直连。

## 目录说明

| 文件 | 用途 |
|------|------|
| `Dockerfile` | 镜像定义（Ubuntu 24.04 + Vulkan 驱动 + MinerU 基础包） |
| `run_webui.sh` | 一键创建容器（api-server + WebUI 一体，含产物输出挂载） |
| `textbook_sample.pdf` | 自制的一页测试稿（标题/列表/表格），用于验证解析效果 |

## 模型与产物位置

| 内容 | 位置 |
|------|------|
| 模型（约 1.9GB：OCR/Layout/公式/表格小模型 + 1.2B VLM） | **镜像内** `/root/.mineru/models/` |
| ONNX 设备校准记录 | 容器内 `/root/.mineru/`（运行时生成） |
| 解析产物输出（挂载） | 宿主 `~/.local/share/mineru-output/` → 容器 `/output` |

## 调用 API

```bash
curl http://127.0.0.1:8000/v1/health
# 创建任务 → PUT 上传 → GET /v1/tasks/{id} 轮询 → files[].result_url 下载
```

接口契约见 MinerU 官方文档的 V1 HTTP API / Tasks 章节。

## License

MIT（MinerU 本体遵循其自身许可证，本仓库只包含部署配置）