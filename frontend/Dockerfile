FROM node:24-alpine AS build

ENV NODE_ENV=development \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    HOME=/home/nodejs

WORKDIR /app

ARG UID=1000
ARG GID=1000

RUN set -eux; \
    if ! getent passwd "$UID" > /dev/null 2>&1; then \
        if getent group "$GID" > /dev/null 2>&1; then \
            GRP=$(getent group "$GID" | cut -d: -f1); \
        else \
            addgroup -g "$GID" -S nodejs; \
            GRP=nodejs; \
        fi; \
        adduser -S -D -H -u "$UID" -G "$GRP" nodejs; \
    fi; \
    mkdir -p /home/nodejs && chown -R "$UID:$GID" /home/nodejs

COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then \
        npm ci --ignore-scripts; \
    else \
        npm install --ignore-scripts; \
    fi && \
    chown -R "${UID}:${GID}" /app

USER ${UID}

COPY --chown=${UID}:${GID} . .

CMD ["npm", "run", "dev"]
