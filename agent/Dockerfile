FROM ubuntu:24.04

# Устанавливаем базовые инструменты для работы с кодом
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    ripgrep \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем aider (популярный AI-агент для кодинга) как пример
# Можешь заменить на любой другой CLI-агент
RUN pip3 install --no-cache-dir --break-system-packages aider-chat

# Устанавливаем opencode (Go-бинарник, ассет opencode-linux-x64.tar.gz)
RUN curl -fsSL https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-x64.tar.gz -o /tmp/opencode.tar.gz \
    && mkdir -p /tmp/opencode \
    && tar -xzf /tmp/opencode.tar.gz -C /tmp/opencode \
    && find /tmp/opencode -type f -name 'opencode' -exec install -m 0755 {} /usr/local/bin/opencode \; \
    && rm -rf /tmp/opencode /tmp/opencode.tar.gz

ARG UID=1000
ARG GID=1000
RUN set -eux; \
    if ! getent group "$GID" > /dev/null 2>&1; then \
        groupadd -g "$GID" agent; \
    fi; \
    if ! id -u "$UID" > /dev/null 2>&1; then \
        useradd -u "$UID" -g "$GID" -m -s /bin/bash agent; \
    else \
        existing=$(id -nu "$UID"); \
        if [ "$existing" != "agent" ]; then \
            usermod -l agent -d /home/agent -m "$existing"; \
        fi; \
    fi

# Каталоги данных opencode должны принадлежать агенту —
# иначе персистентные тома монтируются root-owned и БД не создаётся.
# "agent:" = пользователь + его первичная группа (группы "agent" может не быть,
# т.к. базовый ubuntu:24.04 уже содержит группу с gid 1000)
RUN mkdir -p /home/agent/.local/share/opencode /home/agent/.config/opencode \
    && chown -R agent: /home/agent

USER agent
WORKDIR /workspace

# По умолчанию запускаем bash, можно переопределить в compose
CMD ["bash"]
