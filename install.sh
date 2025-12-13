#!/bin/bash

# VPS Speed Test - Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/anrulev/vps-speed-test/main/install.sh | bash

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   VPS Speed Test - Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Определение директории установки
INSTALL_DIR="${HOME}/vps-speed-test"

# Проверка наличия git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Ошибка: git не установлен${NC}"
    echo -e "${YELLOW}Установите git:${NC}"
    echo -e "  macOS:          brew install git"
    echo -e "  Ubuntu/Debian:  sudo apt install git"
    echo -e "  CentOS/RHEL:    sudo yum install git"
    exit 1
fi

# Проверка зависимостей
echo -e "${YELLOW}Проверка зависимостей...${NC}"
missing_deps=()

check_command() {
    if ! command -v "$1" &> /dev/null; then
        missing_deps+=("$1")
    else
        echo -e "  ${GREEN}✓${NC} $1"
    fi
}

check_command "curl"
check_command "ping"
check_command "traceroute"
check_command "bc"

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Предупреждение: Следующие утилиты не установлены:${NC}"
    for dep in "${missing_deps[@]}"; do
        echo -e "  ${RED}✗${NC} $dep"
    done
    echo -e "\n${YELLOW}Установите их для полной функциональности.${NC}"
fi

# Проверка наличия jq (опционально)
if command -v jq &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} jq (опционально)"
else
    echo -e "  ${YELLOW}○${NC} jq (опционально, рекомендуется)"
fi

# Удаление старой установки если существует
if [ -d "$INSTALL_DIR" ]; then
    echo -e "\n${YELLOW}Найдена существующая установка в $INSTALL_DIR${NC}"
    read -p "Удалить и переустановить? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}Старая версия удалена${NC}"
    else
        echo -e "${YELLOW}Установка отменена${NC}"
        exit 0
    fi
fi

# Клонирование репозитория
echo -e "\n${BLUE}Клонирование репозитория...${NC}"
git clone https://github.com/anrulev/vps-speed-test.git "$INSTALL_DIR"

# Переход в директорию
cd "$INSTALL_DIR"

# Установка прав на выполнение
chmod +x *.sh

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Установка успешно завершена!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Директория установки:${NC} $INSTALL_DIR\n"

echo -e "${BLUE}Для запуска используйте:${NC}"
echo -e "  ${GREEN}cd $INSTALL_DIR${NC}"
echo -e "  ${GREEN}./test_vps_speed.sh${NC}\n"

echo -e "${BLUE}Просмотр отчетов:${NC}"
echo -e "  ${GREEN}./view_reports.sh${NC}\n"

echo -e "${BLUE}Настройка серверов:${NC}"
echo -e "  ${GREEN}nano servers.conf${NC}\n"

# Опционально: добавление в PATH
echo -e "${YELLOW}Хотите добавить в PATH для быстрого запуска? (y/n)${NC}"
read -p "Ответ: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SHELL_RC="${HOME}/.bashrc"

    # Определение shell
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="${HOME}/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        if [ -f "${HOME}/.bash_profile" ]; then
            SHELL_RC="${HOME}/.bash_profile"
        fi
    fi

    # Добавление в PATH
    if ! grep -q "vps-speed-test" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# VPS Speed Test" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
        echo -e "${GREEN}✓ Добавлено в $SHELL_RC${NC}"
        echo -e "${YELLOW}Выполните: source $SHELL_RC${NC}"
        echo -e "${YELLOW}После этого можно запускать: test_vps_speed.sh из любой директории${NC}"
    else
        echo -e "${YELLOW}PATH уже настроен${NC}"
    fi
fi

echo -e "\n${GREEN}Готово! Приятного использования!${NC}"
