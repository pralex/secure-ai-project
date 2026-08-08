# Secure AI Project

Безопасный dev-стек: **FastAPI бэкенд + React/Vite фронтенд + AI-агент в изолированном Docker-контейнере**.

Проект построен по принципу минимума прав: агент видит только исходники, не имеет доступа к секретам, базе данных и сети.

## Стек

| Компонент   | Технологии                                    |
|-------------|-----------------------------------------------|
| Backend     | Python 3.11, FastAPI, Uvicorn (hot-reload)    |
| Frontend    | React 18, TypeScript, Vite 5                  |
| Database    | PostgreSQL 16 (внутренняя сеть, без проброса) |
| AI-агент    | opencode в изолированном контейнере           |
| LLM         | Ollama (локальный инференс) или любой провайдер |

## Быстрый старт

```bash
./init.sh
```

Скрипт выполнит:
1. Проверку зависимостей (Docker, Compose).
2. Создание `.env` из `.env.example` (если нет) и простановку UID/GID.
3. Проверку прав доступа на каталоги.
4. Подготовку каталогов данных агента (`agent/data/*`).
5. Сборку и запуск всех сервисов.

После запуска:

- Backend: `http://localhost:8000` (endpoints `/` и `/health`)
- Frontend: `http://localhost:5173`
- Агент: `docker compose run --rm opencode-agent opencode`

### Переменные окружения (`.env`)

См. `.env.example`:

| Переменная          | Назначение                             |
|---------------------|----------------------------------------|
| `POSTGRES_USER/PASSWORD/DB` | доступ к базе данных          |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` | ключи облачных провайдеров (опционально) |
| `OLLAMA_BASE_URL`   | адрес локального Ollama (с `/v1`)      |
| `UID`/`GID`         | uid/gid владельца (для проброса в контейнеры) |

> `.env` в `.gitignore` — секреты не попадают в git.

## Структура

```
├── backend/app/          # FastAPI приложение (main.py — endpoints / и /health)
├── frontend/src/         # React приложение (main.tsx → App.tsx)
├── agent/                # контейнер AI-агента
│   ├── Dockerfile
│   ├── opencode.json     # конфиг opencode (провайдер Ollama)
│   └── data/             # персистентные данные (НЕ в git)
│       ├── opencode/     # БД сессий, auth.json (/connect ключи)
│       ├── config/       # конфиг и плагины opencode
│       ├── state/        # model.json — последняя выбранная модель
│       └── cache/        # каталог моделей, LSP-бинарники
├── AGENTS.md             # инструкции для агента (что ему доступно и запрещено)
├── create-project.sh     # создание нового проекта из этого шаблона
└── init.sh               # инициализация и запуск стека
```

## AI-агент

Агент изолирован:

- Видит только `backend/app`, `frontend/src`, `opencode.json`, `AGENTS.md`.
- Лишён capabilities, сети наружу нет, запускается без root.
- Инструкции работы — в `AGENTS.md` (монтируется в `/workspace`).

Сессии, выбор модели и ключи `/connect` переживают пересоздание контейнеров
(данные лежат на хосте в `agent/data/`, а не в эфемерной ФС контейнера).

Полезные команды:

```bash
# продолжить последнюю сессию
docker compose run --rm opencode-agent opencode run -c "..."

# список сессий
docker compose exec opencode-agent opencode session list

# запуск TUI
docker compose run --rm opencode-agent opencode
```

## Новый проект из этого шаблона

```bash
./create-project.sh "Мой проект" /path/to/new-project
cd /path/to/new-project
./init.sh
```

Скрипт копирует только закоммиченное состояние (без `.env`, `.git`, `agent/data/`),
транслитерирует имя проекта и обновляет `AGENTS.md`. Контейнеры именуются
автоматически по имени папки проекта, поэтому несколько копий не конфликтуют.

Проект также можно опубликовать как GitHub-шаблон (Settings → Template repository)
и создавать копии через "Use this template".

## Бэкап данных агента

Вся персистентная часть агента — в одном каталоге:

```bash
tar -czf agent-backup.tgz agent/data
```

## Примечания

- Dev-окружение: backend и frontend перезапускаются при изменении файлов (hot-reload).
- Тестов в репозитории пока нет.
