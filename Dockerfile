# MinerU 4.x ONNX + Intel GPU (WebGPU/Vulkan) — 非 NVIDIA 路线
# 基底: Ubuntu 24.04 (mesa-vulkan-drivers 25.x, 支持 Intel Arc/Battlemage 等新核显)
# BASE_IMAGE 可通过 --build-arg 覆盖（国内可用 docker.1ms.run 等镜像加速）
#
# 模型两种就位方式（--build-arg MODELS= 选择）：
#   local    本地已有模型目录时秒建：--build-context models=<模型目录>
#   download 默认：构建时从 ModelScope 下载（约 1.9GB，耗时视网络）
ARG BASE_IMAGE=ubuntu:24.04
ARG MODELS=download
FROM ${BASE_IMAGE} AS base

ENV DEBIAN_FRONTEND=noninteractive

# ---- 国内镜像源（容器无 IPv6 用 USTC IPv4；apt 必须走 HTTP——基础镜像尚无 ca-certificates）----
RUN sed -i -e 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.ustc.edu.cn/ubuntu/|g' \
           -e 's|http://security.ubuntu.com/ubuntu/|http://mirrors.ustc.edu.cn/ubuntu/|g' \
           /etc/apt/sources.list.d/ubuntu.sources \
    && printf '[global]\nindex-url = https://mirrors.ustc.edu.cn/pypi/simple\n' > /etc/pip.conf

# Vulkan/Intel GPU 驱动 + 系统依赖 + 中文字体
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3-pip \
    libvulkan1 mesa-vulkan-drivers \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    fonts-noto-cjk curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# MinerU 基础包 = WebUI + ONNX 小模型运行时 + llama.cpp VLM（不带 torch/vllm）
RUN pip3 install --no-cache-dir --break-system-packages -U "mineru>=4.0,<5"

# 模型源 ModelScope（国内快），小模型后端 ONNX，设备 auto（启动时按 iGPU 校准）
ENV MINERU_MODEL_SOURCE=modelscope \
    MINERU_MODEL_SMALL_BACKEND=onnx \
    MINERU_MODEL_ONNX_DEVICE=auto

# ---- 模型就位：双模式（BuildKit 按需构建，选 download 时不会解析 local）----
# 方式一（MODELS=local）：从 --build-context models=<目录> 直接复制，秒级完成
FROM base AS models-local
COPY --from=models . /root/.mineru/models/

# 方式二（MODELS=download，默认）：构建时从 ModelScope 下载全集（约 1.9GB）
FROM base AS models-download
RUN mineru-kit models download --tier standard --small-backend onnx \
        --vlm-engine llama-cpp -s modelscope

# 选择模式（MODELS 在文件顶部声明）
FROM models-${MODELS} AS final

EXPOSE 7860 8000

CMD ["mineru-kit", "webui", "--server-name", "0.0.0.0", "--server-port", "7860"]