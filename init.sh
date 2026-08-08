#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Инициализация безопасного проекта...${NC}"

# Проверка зависимостей
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker не найден.${NC}"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose не найден.${NC}"
    exit 1
fi

# Определяем UID/GID (без export, т.к. UID readonly в bash)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo -e "${GREEN}👤 UID: $CURRENT_UID, GID: $CURRENT_GID${NC}"

# Создаём .env если нет
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Создан .env из шаблона. ЗАПОЛНИ СЕКРЕТЫ!${NC}"
fi

# Записываем UID/GID в .env (compose читает автоматически)
sed -i "s/^UID=.*/UID=$CURRENT_UID/" .env
sed -i "s/^GID=.*/GID=$CURRENT_GID/" .env

# Проверяем секреты
if grep -q "change_me" .env; then
    echo -e "${RED}❌ Пароль БД не изменён! Измени POSTGRES_PASSWORD в .env${NC}"
    exit 1
fi

# === ПРОВЕРКА ПРАВ ДОСТУПА ===
NEED_CHOWN=false

for dir in ./backend ./frontend; do
    if [ -d "$dir" ]; then
        DIR_UID=$(stat -c '%u' "$dir")
        DIR_GID=$(stat -c '%g' "$dir")
        
        if [ "$DIR_UID" != "$CURRENT_UID" ] || [ "$DIR_GID" != "$CURRENT_GID" ]; then
            echo -e "${YELLOW}⚠️  $dir принадлежит UID:$DIR_UID GID:$DIR_GID (нужен $CURRENT_UID:$CURRENT_GID)${NC}"
            NEED_CHOWN=true
        fi
    fi
done

if [ "$NEED_CHOWN" = true ]; then
    echo -e "${YELLOW}📁 Исправление прав доступа (требуется sudo)...${NC}"
    sudo chown -R $CURRENT_UID:$CURRENT_GID ./backend ./frontend
    echo -e "${GREEN}✅ Права исправлены${NC}"
else
    echo -e "${GREEN}✅ Права доступа уже корректны${NC}"
fi

# Готовим каталоги данных агента: Docker сам создаст их как root,
# и тогда агент (uid 1000) не сможет туда писать (EACCES)
mkdir -p agent/data/opencode agent/data/config agent/data/state agent/data/cache

# Останавливаем старые контейнеры
echo -e "${GREEN}🛑 Остановка старых контейнеров...${NC}"
docker compose down --remove-orphans 2>/dev/null || true

# Собираем и запускаем
echo -e "${GREEN}🚀 Сборка и запуск инфраструктуры...${NC}"
docker compose up -d --build

# Ждём готовности
echo -e "${YELLOW}⏳ Ожидание готовности сервисов...${NC}"
sleep 5

# Статус
echo -e "${GREEN}📊 Статус контейнеров:${NC}"
docker compose ps

echo ""
echo -e "${GREEN}✅ Проект готов!${NC}"
echo -e "📝 Backend:  ${YELLOW}http://localhost:8000${NC}"
echo -e "🎨 Frontend: ${YELLOW}http://localhost:5173${NC}"
echo -e "🤖 Агент:    ${YELLOW}docker compose run --rm opencode-agent opencode${NC}"
