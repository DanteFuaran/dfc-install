#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DARKGRAY='\033[1;30m'
NC='\033[0m'

_cancel_exit() {
    trap '' INT TERM
    printf "\r\033[K\033[0m\n"
    echo -e "${RED}Скрипт остановлен пользователем...${NC}"
    echo
    tput cnorm 2>/dev/null
    exit 0
}

trap 'printf "\033[0m"; tput cnorm 2>/dev/null' EXIT
trap '_cancel_exit' INT TERM

_ACCESS_KEY=""
_read_key() {
    local input="" char
    tput cnorm 2>/dev/null
    printf "${BLUE}➜${NC}  ${YELLOW}Введите ключ доступа:${NC} \033[32m"
    while IFS= read -r -s -n1 char; do
        if [[ -z "$char" ]]; then
            break
        elif [[ "$char" == $'\x7f' ]] || [[ "$char" == $'\x08' ]]; then
            if [[ -n "$input" ]]; then
                input="${input%?}"
                printf "\b \b"
            fi
        elif [[ "$char" == $'\x1b' ]]; then
            while IFS= read -r -s -n1 -t 0.1 _sc; do
                [[ "$_sc" =~ [A-Za-z~] ]] && break
            done
            # Чистый Esc (нет дальнейшей последовательности) — выход
            if [[ -z "${_sc:-}" ]]; then
                _cancel_exit
            fi
        else
            input+="$char"
            printf "%s" "$char"
        fi
    done
    printf "\033[0m\n"
    tput civis 2>/dev/null
    _ACCESS_KEY="$input"
}

clear
tput civis 2>/dev/null
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo -e "     🛡️  DFC Manager — Установка"
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo

_spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

while true; do
    printf "\033[s"   # сохранить позицию курсора (перед строкой ввода)
    _read_key
    ACCESS_KEY="$_ACCESS_KEY"

    # Спиннер пока идёт проверка
    _tmpfile=$(mktemp)
    tput civis 2>/dev/null
    ( curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${ACCESS_KEY}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/DanteFuaran/dfc-manager/contents/dfc-manager.sh" \
        > "$_tmpfile" 2>/dev/null
    ) &
    _cpid=$!
    _si=0
    echo
    while kill -0 "$_cpid" 2>/dev/null; do
        printf "\r${GREEN}${_spin[$((_si % 10))]}${NC}  Поиск ключа активации"
        _si=$((_si + 1))
        sleep 0.08
    done
    _STATUS=$(cat "$_tmpfile" 2>/dev/null)
    rm -f "$_tmpfile"
    printf "\r\033[K\033[0m"

    if [ "$_STATUS" = "200" ]; then
        echo -e "${GREEN}✅ Ключ успешно активирован!${NC}"
        tput cnorm 2>/dev/null
        echo
        break
    fi

    echo -e "${RED}✖${NC}  Неверный ключ или нет доступа."
    echo
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    printf "   ${DARKGRAY}${BLUE}Enter${DARKGRAY}: Повторить    ${BLUE}Esc${DARKGRAY}: Выход${NC}"
    tput civis 2>/dev/null

    IFS= read -rsn1 _nav 2>/dev/null || _nav=""
    if [[ "$_nav" == $'\x1b' ]]; then
        _cancel_exit
    fi

    # Enter: восстановить позицию курсора и очистить до конца экрана
    printf "\033[u\033[J"
done

SCRIPT=$(curl -s \
    -H "Authorization: Bearer ${ACCESS_KEY}" \
    -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/DanteFuaran/dfc-manager/contents/dfc-manager.sh")

if [ -z "$SCRIPT" ]; then
    echo -e "${RED}Ошибка загрузки скрипта.${NC}"
    exit 1
fi

export DFC_ACCESS_KEY="$ACCESS_KEY"
_TMP=$(mktemp /tmp/dfc-XXXXXX.sh)
printf '%s\n' "$SCRIPT" > "$_TMP"
_STTY_SAVED=$(stty -g 2>/dev/null || true)
chmod +x "$_TMP"
trap - INT TERM
bash "$_TMP"
_exit=$?
if [ -n "$_STTY_SAVED" ]; then stty "$_STTY_SAVED" 2>/dev/null || stty sane 2>/dev/null || true; else stty sane 2>/dev/null || true; fi
stty echo echoe icanon 2>/dev/null || true
rm -f "$_TMP" 2>/dev/null

