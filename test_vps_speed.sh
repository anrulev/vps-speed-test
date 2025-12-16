#!/bin/bash
# VPS Speed Test - Main Testing Script
# https://github.com/anrulev/vps-speed-test

# Установка локали для корректной работы с числами
export LC_NUMERIC=C

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Определяем директорию скрипта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/servers.conf"
REPORTS_DIR="$SCRIPT_DIR/reports"

# Создаем директорию для отчетов, если её нет
mkdir -p "$REPORTS_DIR"

# Генерируем имя файла отчета с датой и временем
REPORT_TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$REPORTS_DIR/report_$REPORT_TIMESTAMP.txt"
REPORT_FILE_RAW="$REPORTS_DIR/.report_${REPORT_TIMESTAMP}_raw.txt"

# Записываем заголовок отчета
{
    echo "========================================"
    echo "  VPS Speed Test Report"
    echo "========================================"
    echo ""
    echo "Test Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "System: $(uname -s) $(uname -r)"
    echo "Report File: $REPORT_FILE"
    echo ""
} > "$REPORT_FILE_RAW"

# Перенаправляем вывод в файл и на экран одновременно
exec > >(tee -a "$REPORT_FILE_RAW")
exec 2>&1

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Тест скорости доступа к VPS серверам${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Проверка наличия конфигурационного файла
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Ошибка: Файл конфигурации не найден!${NC}"
    echo -e "${YELLOW}Ожидаемый путь: $CONFIG_FILE${NC}"
    echo -e "\nСоздайте файл servers.conf в формате:"
    echo -e "Название сервера|IP адрес"
    exit 1
fi

# Получение информации о вашем местоположении
echo -e "${CYAN}Получение информации о вашем местоположении...${NC}"
my_ip=$(curl -s ifconfig.me)

# Пробуем получить геолокацию через ipinfo.io (более надежный API)
location_info=$(curl -s "https://ipinfo.io/$my_ip/json")

# Парсим JSON более надежным способом
if command -v jq &> /dev/null; then
    # Если jq установлен, используем его
    my_city=$(echo "$location_info" | jq -r '.city // "Unknown"')
    my_region=$(echo "$location_info" | jq -r '.region // "Unknown"')
    my_country=$(echo "$location_info" | jq -r '.country // "Unknown"')
else
    # Альтернативный парсинг без jq
    my_city=$(echo "$location_info" | sed -n 's/.*"city": *"\([^"]*\)".*/\1/p')
    my_region=$(echo "$location_info" | sed -n 's/.*"region": *"\([^"]*\)".*/\1/p')
    my_country=$(echo "$location_info" | sed -n 's/.*"country": *"\([^"]*\)".*/\1/p')

    # Если парсинг не сработал, пробуем другой формат
    if [ -z "$my_city" ]; then
        my_city=$(echo "$location_info" | grep -o '"city"[^,]*' | head -1 | sed 's/"city"://g' | tr -d '" ')
        my_region=$(echo "$location_info" | grep -o '"region"[^,]*' | head -1 | sed 's/"region"://g' | tr -d '" ')
        my_country=$(echo "$location_info" | grep -o '"country"[^,]*' | head -1 | sed 's/"country"://g' | tr -d '" ')
    fi
fi

# Если все еще пусто, используем простой вывод
if [ -z "$my_city" ] && [ -z "$my_region" ] && [ -z "$my_country" ]; then
    echo -e "${GREEN}Ваш IP:${NC} $my_ip"
    echo -e "${YELLOW}Местоположение не определено${NC}"
else
    echo -e "${GREEN}Ваш IP:${NC} $my_ip"
    echo -e "${GREEN}Ваше местоположение:${NC} $my_city, $my_region, $my_country"
fi

# Загрузка серверов из конфигурационного файла
echo -e "\n${CYAN}Загрузка серверов из конфигурации...${NC}"
servers=()
server_count=0

while IFS= read -r line; do
    # Пропускаем пустые строки и комментарии
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Проверяем формат строки
    if [[ "$line" =~ ^[^|]+\|[0-9.]+$ ]]; then
        servers+=("$line")
        server_count=$((server_count + 1))
    else
        echo -e "${YELLOW}Предупреждение: Неверный формат строки (пропущено): $line${NC}"
    fi
done < "$CONFIG_FILE"

if [ ${#servers[@]} -eq 0 ]; then
    echo -e "${RED}Ошибка: Не найдено ни одного сервера в конфигурации!${NC}"
    exit 1
fi

echo -e "${GREEN}Загружено серверов: $server_count${NC}"
echo -e "\n${BLUE}Начинаем тестирование серверов...${NC}\n"

# Временный файл для результатов
temp_file=$(mktemp)

# Функция для расчета jitter (вариация задержки)
calculate_jitter() {
    local ip=$1
    local ping_times
    ping_times=$(ping -c 10 -W 2000 "$ip" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

    if [ -z "$ping_times" ]; then
        echo "N/A"
        return
    fi

    # Расчет стандартного отклонения (jitter)
    local jitter
    jitter=$(echo "$ping_times" | awk '{sum+=$1; sumsq+=$1*$1} END {printf "%.2f", sqrt(sumsq/NR - (sum/NR)^2)}')
    echo "$jitter"
}

# Функция для тестирования сервера
test_server() {
    local name=$1
    local ip=$2

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Тестирование: $name ($ip)${NC}"

    # 1. Ping тест (20 пакетов для более точных результатов)
    ping_output=$(ping -c 20 -W 2000 $ip 2>/dev/null)
    ping_result=$(echo "$ping_output" | tail -1)

    if [ -z "$ping_result" ]; then
        echo -e "${RED}  ✗ Сервер недоступен${NC}\n"
        echo "9999|$name|$ip|N/A|N/A|N/A|N/A|N/A|N/A|0" >> "$temp_file"
        return
    fi

    # Извлечение статистики ping
    avg_ping=$(echo $ping_result | awk -F '/' '{print $5}')
    min_ping=$(echo $ping_result | awk -F '/' '{print $4}')
    max_ping=$(echo $ping_result | awk -F '/' '{print $6}')
    stddev=$(echo $ping_result | awk -F '/' '{print $7}')

    # Packet loss
    packet_loss=$(echo "$ping_output" | grep -o '[0-9.]*% packet loss' | grep -o '^[0-9.]*')

    # Проверка на 100% потерю пакетов
    if [ -z "$avg_ping" ] || [ -z "$packet_loss" ]; then
        echo -e "${RED}  ✗ Сервер недоступен (100% потеря пакетов)${NC}\n"
        echo "9999|$name|$ip|N/A|N/A|N/A|100.0|N/A|N/A|N/A" >> "$temp_file"
        return
    fi

    echo -e "  ${CYAN}[1/4]${NC} Ping (мин/сред/макс/stddev): ${GREEN}$min_ping${NC}/${BLUE}$avg_ping${NC}/${RED}$max_ping${NC}/${YELLOW}$stddev${NC} ms"
    echo -e "  ${CYAN}[1/4]${NC} Потеря пакетов: ${packet_loss}%"

    # 2. Jitter (вариация задержки)
    jitter=$(calculate_jitter $ip)
    echo -e "  ${CYAN}[2/4]${NC} Jitter (стабильность): $jitter ms"

    # 3. Traceroute (количество хопов)
    echo -ne "  ${CYAN}[3/4]${NC} Traceroute... "
    hops=$(traceroute -m 30 -w 2 $ip 2>/dev/null | grep -c "^ ")
    if [ "$hops" -gt 0 ]; then
        echo -e "${hops} хопов"
    else
        hops="N/A"
        echo -e "недоступно"
    fi

    # 4. TCP Connection time (порт 80)
    echo -ne "  ${CYAN}[4/4]${NC} TCP соединение (порт 80)... "
    tcp_time=$(curl -o /dev/null -s -w '%{time_connect}' --connect-timeout 5 http://$ip 2>/dev/null || echo "N/A")
    if [ "$tcp_time" != "N/A" ] && [ -n "$tcp_time" ]; then
        # Убираем возможные пробелы и переносы строк
        tcp_time=$(echo "$tcp_time" | tr -d '\n\r ')

        # Проверяем что время больше 0 (если 0, значит порт закрыт)
        if awk "BEGIN {exit !($tcp_time > 0)}"; then
            local tcp_calc
            tcp_calc=$(echo "$tcp_time * 1000" | bc -l)
            tcp_time_ms=$(printf "%.2f" "$tcp_calc")
            echo -e "${tcp_time_ms} ms"
        else
            tcp_time_ms="N/A"
            echo -e "${RED}порт закрыт${NC}"
        fi
    else
        tcp_time_ms="N/A"
        echo -e "недоступно"
    fi

    # Конвертируем запятые в точки для вычислений
    avg_ping_calc=$(echo "$avg_ping" | tr ',' '.')
    packet_loss_calc=$(echo "$packet_loss" | tr ',' '.')
    jitter_calc=$(echo "$jitter" | tr ',' '.')

    # Расчет общего балла (чем меньше, тем лучше)
    # Формула: avg_ping + (packet_loss * 10) + (jitter * 2)
    if [ "$jitter" != "N/A" ] && [ "$packet_loss" != "N/A" ]; then
        score=$(echo "$avg_ping_calc + ($packet_loss_calc * 10) + ($jitter_calc * 2)" | bc -l)
    else
        score=$avg_ping_calc
    fi

    # Определение качества соединения (используем awk вместо bc для надежности)
    if awk "BEGIN {exit !($avg_ping_calc < 50 && $packet_loss_calc < 1)}"; then
        quality="${GREEN}★★★ Отлично${NC}"
    elif awk "BEGIN {exit !($avg_ping_calc < 100 && $packet_loss_calc < 2)}"; then
        quality="${YELLOW}★★☆ Хорошо${NC}"
    else
        quality="${RED}★☆☆ Удовлетворительно${NC}"
    fi

    echo -e "  ${BLUE}Оценка:${NC} $quality (общий балл: $(printf '%.2f' $score))"
    echo ""

    # Сохранение результатов для сортировки
    echo "$score|$name|$ip|$min_ping|$avg_ping|$max_ping|$packet_loss|$jitter|$hops|$tcp_time_ms" >> "$temp_file"
}

# Тестирование всех серверов
for server in "${servers[@]}"; do
    IFS='|' read -r name ip <<< "$server"
    test_server "$name" "$ip"
done

# Вывод результатов отсортированных по общему баллу
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}                        ИТОГОВЫЕ РЕЗУЛЬТАТЫ (отсортировано по качеству)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

printf "%-3s %-20s %-16s %8s %8s %8s %8s %7s %6s\n" "#" "Локация" "IP" "Ping(ms)" "Loss%" "Jitter" "Hops" "TCP(ms)" "Оценка"
echo "----------------------------------------------------------------------------------------"

rank=1
sort -t'|' -k1 -n "$temp_file" | while IFS='|' read -r score name ip min_ping avg_ping max_ping packet_loss jitter hops tcp_time; do
    if [ "$score" = "9999" ]; then
        printf "${RED}%-3s %-20s %-16s %8s %8s %8s %8s %7s %s${NC}\n" "❌" "$name" "$ip" "-" "100.0" "-" "-" "-" "НЕДОСТУПЕН"
    else
        # Проверяем что данные валидны
        if [ -z "$avg_ping" ] || [ -z "$packet_loss" ]; then
            continue
        fi

        # Конвертируем для сравнения
        avg_ping_calc=$(echo "$avg_ping" | tr ',' '.')
        packet_loss_calc=$(echo "$packet_loss" | tr ',' '.')

        # Цветовая кодировка по качеству (используем awk вместо bc для надежности)
        if awk "BEGIN {exit !($avg_ping_calc < 50 && $packet_loss_calc < 1)}"; then
            color=$GREEN
        elif awk "BEGIN {exit !($avg_ping_calc < 100 && $packet_loss_calc < 2)}"; then
            color=$YELLOW
        else
            color=$RED
        fi

        # Добавляем медали для топ-3
        if [ $rank -eq 1 ]; then
            medal="🥇"
        elif [ $rank -eq 2 ]; then
            medal="🥈"
        elif [ $rank -eq 3 ]; then
            medal="🥉"
        else
            medal="  "
        fi

        printf "${color}%-3s${NC} %-20s %-16s ${color}%8s${NC} %8s %8s %8s %7s %6.2f\n" \
            "$medal" "$name" "$ip" "$avg_ping" "$packet_loss" "$jitter" "$hops" "$tcp_time" "$score"
    fi
    rank=$((rank + 1))
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Лучший сервер (исключаем недоступные с баллом 9999)
best_server=$(sort -t'|' -k1 -n "$temp_file" | awk -F'|' '$1 < 9999' | head -1)
if [ -n "$best_server" ]; then
    best_name=$(echo "$best_server" | cut -d'|' -f2)
    best_ping=$(echo "$best_server" | cut -d'|' -f5)
    best_loss=$(echo "$best_server" | cut -d'|' -f7)
    best_score=$(echo "$best_server" | cut -d'|' -f1)

    echo -e "${GREEN}🏆 РЕКОМЕНДАЦИЯ:${NC} ${YELLOW}$best_name${NC}"
    echo -e "   Средний ping: ${GREEN}$best_ping ms${NC} | Потеря пакетов: ${GREEN}$best_loss%${NC} | Общий балл: ${GREEN}$(printf '%.2f' $best_score)${NC}"
else
    echo -e "${RED}⚠️  Ни один сервер не доступен${NC}"
fi

echo ""
echo -e "${CYAN}Параметры оценки:${NC}"
echo -e "  • ${CYAN}Ping${NC} - задержка отклика (чем меньше, тем лучше)"
echo -e "  • ${CYAN}Loss%${NC} - процент потерянных пакетов (должно быть 0%)"
echo -e "  • ${CYAN}Jitter${NC} - стабильность соединения (чем меньше, тем лучше)"
echo -e "  • ${CYAN}Hops${NC} - количество промежуточных узлов (меньше = прямее маршрут)"
echo -e "  • ${CYAN}TCP${NC} - скорость установки соединения"
echo -e "  • ${CYAN}Оценка${NC} - общий балл качества (меньше = лучше)"

# Удаление временного файла
rm "$temp_file"

# Очистка ANSI escape кодов из файла и сохранение финального отчета
sed 's/\x1b\[[0-9;]*m//g' "$REPORT_FILE_RAW" > "$REPORT_FILE"
rm "$REPORT_FILE_RAW"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Отчет сохранен: ${YELLOW}$REPORT_FILE${NC}"
echo -e "${GREEN}✓ Все отчеты находятся в: ${YELLOW}$REPORTS_DIR${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
