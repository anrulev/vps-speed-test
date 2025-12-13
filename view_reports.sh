#!/bin/bash

# Определяем директорию скрипта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORTS_DIR="$SCRIPT_DIR/reports"

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}        Управление отчетами VPS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Проверяем наличие отчетов
if [ ! -d "$REPORTS_DIR" ] || [ -z "$(ls -A $REPORTS_DIR/report_*.txt 2>/dev/null)" ]; then
    echo -e "${YELLOW}Отчеты не найдены.${NC}"
    echo -e "Запустите ${GREEN}./test_vps_speed.sh${NC} для создания первого отчета."
    exit 0
fi

# Подсчет отчетов
report_count=$(ls -1 "$REPORTS_DIR"/report_*.txt 2>/dev/null | wc -l | tr -d ' ')
total_size=$(du -sh "$REPORTS_DIR" | awk '{print $1}')

echo -e "${GREEN}Всего отчетов:${NC} $report_count"
echo -e "${GREEN}Занято места:${NC} $total_size\n"

# Функция для отображения меню
show_menu() {
    echo -e "${CYAN}Выберите действие:${NC}"
    echo "  1) Показать список всех отчетов"
    echo "  2) Просмотреть последний отчет"
    echo "  3) Просмотреть конкретный отчет"
    echo "  4) Удалить старые отчеты (старше 30 дней)"
    echo "  5) Удалить все отчеты"
    echo "  0) Выход"
    echo ""
}

# Основной цикл
while true; do
    show_menu
    read -p "Ваш выбор: " choice

    case $choice in
        1)
            echo -e "\n${BLUE}Список отчетов:${NC}"
            ls -lht "$REPORTS_DIR"/report_*.txt | awk '{printf "%s %s %s - %s\n", $6, $7, $8, $9}'
            echo ""
            ;;
        2)
            latest=$(ls -t "$REPORTS_DIR"/report_*.txt | head -1)
            if [ -n "$latest" ]; then
                echo -e "\n${GREEN}Последний отчет:${NC} $(basename $latest)\n"
                cat "$latest"
                echo ""
            else
                echo -e "${YELLOW}Отчеты не найдены${NC}\n"
            fi
            ;;
        3)
            echo -e "\n${CYAN}Доступные отчеты:${NC}"
            ls -1t "$REPORTS_DIR"/report_*.txt | nl
            echo ""
            read -p "Введите номер отчета: " num
            selected=$(ls -1t "$REPORTS_DIR"/report_*.txt | sed -n "${num}p")
            if [ -n "$selected" ]; then
                echo -e "\n${GREEN}Отчет:${NC} $(basename $selected)\n"
                cat "$selected"
                echo ""
            else
                echo -e "${YELLOW}Неверный номер${NC}\n"
            fi
            ;;
        4)
            echo -e "\n${YELLOW}Удаление отчетов старше 30 дней...${NC}"
            find "$REPORTS_DIR" -name "report_*.txt" -mtime +30 -delete
            deleted_count=$(find "$REPORTS_DIR" -name "report_*.txt" -mtime +30 | wc -l | tr -d ' ')
            echo -e "${GREEN}Удалено отчетов: $deleted_count${NC}\n"
            ;;
        5)
            echo -e "\n${YELLOW}Вы уверены, что хотите удалить ВСЕ отчеты? (y/n)${NC}"
            read -p "Ответ: " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                rm -f "$REPORTS_DIR"/report_*.txt
                echo -e "${GREEN}Все отчеты удалены${NC}\n"
            else
                echo -e "${CYAN}Отмена${NC}\n"
            fi
            ;;
        0)
            echo -e "${GREEN}До свидания!${NC}"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Неверный выбор${NC}\n"
            ;;
    esac
done
