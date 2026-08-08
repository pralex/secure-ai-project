#!/bin/bash
set -euo pipefail

# Создаёт новую копию проекта-шаблона из текущего git-репозитория.
# Использование: ./create-project.sh <имя-проекта> <целевая-директория>
#
# В копию попадает ТОЛЬКО закоммиченное состояние:
#   .env, agent/data/, .git — исключаются автоматически (gitignored).

if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <имя-проекта> <целевая-директория>"
    exit 1
fi

RAW_NAME="$1"
TARGET="$2"

# Приводим имя к безопасному виду: a-z0-9- (с транслитерацией кириллицы, оба регистра)
TRANS=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | sed '
    s/А/a/g; s/Б/b/g; s/В/v/g; s/Г/g/g; s/Д/d/g; s/Е/e/g; s/Ё/e/g;
    s/Ж/zh/g; s/З/z/g; s/И/i/g; s/Й/y/g; s/К/k/g; s/Л/l/g; s/М/m/g;
    s/Н/n/g; s/О/o/g; s/П/p/g; s/Р/r/g; s/С/s/g; s/Т/t/g; s/У/u/g;
    s/Ф/f/g; s/Х/h/g; s/Ц/ts/g; s/Ч/ch/g; s/Ш/sh/g; s/Щ/sch/g;
    s/Ы/y/g; s/Ь//g; s/Ъ//g; s/Э/e/g; s/Ю/yu/g; s/Я/ya/g;
    s/а/a/g; s/б/b/g; s/в/v/g; s/г/g/g; s/д/d/g; s/е/e/g; s/ё/e/g;
    s/ж/zh/g; s/з/z/g; s/и/i/g; s/й/y/g; s/к/k/g; s/л/l/g; s/м/m/g;
    s/н/n/g; s/о/o/g; s/п/p/g; s/р/r/g; s/с/s/g; s/т/t/g; s/у/u/g;
    s/ф/f/g; s/х/h/g; s/ц/ts/g; s/ч/ch/g; s/ш/sh/g; s/щ/sch/g;
    s/ы/y/g; s/ь//g; s/ъ//g; s/э/e/g; s/ю/yu/g; s/я/ya/g;
')
NAME=$(echo "$TRANS" | sed 's/[^a-z0-9-]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')
if [ -z "$NAME" ]; then
    echo "Ошибка: имя проекта пустое или содержит только недопустимые символы: '$RAW_NAME'"
    exit 1
fi

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Ошибка: $SOURCE_DIR не является git-репозиторием."
    exit 1
fi

if [ ! -n "$(git -C "$SOURCE_DIR" log --oneline -1 2>/dev/null)" ]; then
    echo "Ошибка: в репозитории нет коммитов. Сделай первый коммит."
    exit 1
fi

if [ -d "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
    echo "Ошибка: целевая директория '$TARGET' существует и не пуста."
    exit 1
fi

echo "Создание проекта '$NAME' в '$TARGET' из $SOURCE_DIR ..."

mkdir -p "$TARGET"
git -C "$SOURCE_DIR" archive HEAD | tar -x -C "$TARGET"

# Контейнеры именуются Docker'ом автоматически по имени папки проекта,
# поэтому конфликтов между копиями нет — ничего переименовывать не нужно.

# Обновляем заголовок AGENTS.md
AGENTS="$TARGET/AGENTS.md"
if [ -f "$AGENTS" ]; then
    sed -i "1s/.*/# AGENTS.md — ${NAME}/" "$AGENTS"
    sed -i "s/secure-ai-project/${NAME}/g" "$AGENTS"
fi

echo "Готово. Файлы в '$TARGET':"
ls -A "$TARGET"

echo
echo "Дальше:"
echo "  cd '$TARGET'"
echo "  # при необходимости измени секреты в .env"
echo "  ./init.sh"
