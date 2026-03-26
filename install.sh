#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo -e "        DFC Manager — Установка"
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo

echo -e "${YELLOW}Введите ключ доступа:${NC}"
read -rs ACCESS_KEY
echo

if [ -z "$ACCESS_KEY" ]; then
    echo -e "${RED}Ключ не может быть пустым.${NC}"
    exit 1
fi

echo -e "Проверка ключа..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${ACCESS_KEY}" \
    -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/DanteFuaran/dfc-manager/contents/install.sh")

if [ "$STATUS" != "200" ]; then
    echo -e "${RED}Неверный ключ или нет доступа.${NC}"
    exit 1
fi

echo -e "${GREEN}Ключ принят. Загрузка...${NC}"
echo

SCRIPT=$(curl -s \
    -H "Authorization: token ${ACCESS_KEY}" \
    -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/DanteFuaran/dfc-manager/contents/install.sh")

if [ -z "$SCRIPT" ]; then
    echo -e "${RED}Ошибка загрузки скрипта.${NC}"
    exit 1
fi

export DFC_ACCESS_KEY="$ACCESS_KEY"
echo "$SCRIPT" | bash
