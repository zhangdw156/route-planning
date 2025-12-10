# 第一阶段：构建依赖环境
FROM python:3.12-slim AS builder

WORKDIR /app

# 安装 uv
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /bin/

# 设置 uv 环境变量
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# 1. 先复制依赖定义文件 (利用 Docker 缓存)
RUN --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# -----------------------------------------------------------

# 第二阶段：最终运行镜像 (Distroless 风格或纯净 Slim)
# 生产环境运行阶段
FROM python:3.12-slim

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /app

# 复制虚拟环境
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# 复制源码
COPY src/ /app/

# 设置 Python 路径 (这一步其实可以省略，因为 /navigation 默认在路径里，但写上更保险)
ENV PYTHONPATH=/app

# 启动命令
CMD ["uvicorn", "navigation.main:app", "--host", "0.0.0.0", "--port", "8000"]