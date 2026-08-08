FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} appuser && \
    useradd -u ${UID} -g ${GID} -m appuser

COPY pyproject.toml .
COPY app ./app
RUN pip install --no-cache-dir -e . && \
    chown -R appuser:appuser /app

USER appuser

COPY --chown=appuser:appuser . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
