# MinerU 4.x ONNX + Intel GPU (WebGPU/Vulkan) — 非 NVIDIA 路线
# 基底: Ubuntu 24.04 (mesa-vulkan-drivers 25.x, 支持 Intel Arc/Battlemage 等新核显)
# BASE_IMAGE 可通过 --build-arg 覆盖（国内可用 docker.1ms.run 等镜像加速）
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

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

EXPOSE 7860 8000

CMD ["mineru-kit", "webui", "--server-name", "0.0.0.0", "--server-port", "7860"]