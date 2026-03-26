#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

_read_key() {
    local prompt="$1"
    local var_name="$2"
    local input=""
    local char
    tput cnorm 2>/dev/null
    echo -en "${BLUE}➜${NC}  ${YELLOW}${prompt}${NC} \033[32m"
    while IFS= read -r -s -n1 char; do
        if [[ -z "$char" ]]; then
            break
        elif [[ "$char" == $'\x7f' ]] || [[ "$char" == $'\x08' ]]; then
            if [[ -n "$input" ]]; then
                input="${input%?}"
                echo -en "\b \b"
            fi
        elif [[ "$char" == $'\x1b' ]]; then
            local _seq=""
            while IFS= read -r -s -n1 -t 0.1 _sc; do
                _seq+="$_sc"
                [[ "$_sc" =~ [A-Za-z~] ]] && break
            done
        else
            input+="$char"
            echo -en "$char"
        fi
    done
    echo -en "\033[0m"
    echo
    printf -v "$var_name" '%s' "$input"
}

clear
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo -e "        DFC Manager — Установка"
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo

_read_key "Введите ключ доступа:" ACCESS_KEY
echo

if [ -z "$ACCESS_KEY" ]; then
    echo -e "${RED}Ключ не может быть пустым.${NC}"
    exit 1
fi

echo -e "Проверка ключа..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${ACCESS_KEY}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/DanteFuaran/dfc-manager/contents/dfc-manager.sh")

if [ "$STATUS" != "200" ]; then
    echo -e "${RED}Неверный ключ или нет доступа.${NC}"
    exit 1
fi

echo -e "${GREEN}Ключ принят. Загрузка...${NC}"
echo

SCRIPT=$(curl -s \
    -H "Authorization: token ${ACCESS_KEY}" \
    -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/DanteFuaran/dfc-manager/contents/dfc-manager.sh")

if [ -z "$SCRIPT" ]; then
    echo -e "${RED}Ошибка загрузки скрипта.${NC}"
    exit 1
fi

export DFC_ACCESS_KEY="$ACCESS_KEY"
echo "$SCRIPT" | bash
