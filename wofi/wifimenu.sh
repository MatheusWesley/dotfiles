#!/usr/bin/env bash

# Variáveis de configuração
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FIELDS=SSID,SECURITY
POSITION=3
YOFF=20
XOFF=-40
WOFI_WIDTH=400
MAX_LINES=14
CHECK_ICON="🟢"
RED_ICON="🔴"

# Fontes
BOLD='\033[1m'
NC='\033[0m'


# Função para atualizar o estado e as variáveis do Wi-Fi
update_wifi_info() {
    # Força uma nova varredura de redes WiFi disponíveis
    nmcli device wifi rescan || true
    WIFI_STATE=$(nmcli -fields WIFI g)
    KNOWNCON=$(nmcli connection show)
    # CURRSSID=$(LANGUAGE=C nmcli -t -f active,ssid dev wifi | awk '$1 == "sim" {print $2}')
    CURRSSID=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1 == "sim" {print $2, $3}')
}

# Função para listar redes WiFi
list_wifi_networks() {
    LIST=$(nmcli --fields "$FIELDS" device wifi list | sed '/^--/d')
    RWIDTH=$(($(echo "$LIST" | head -n 1 | awk '{print length($0); }')*20))
    LINENUM=$(echo "$LIST" | wc -l)

    # Marca a rede atual com um ícone de check
    if [[ -n $CURRSSID ]]; then
        LIST=$(echo "$LIST" | sed "s/^$CURRSSID/$CHECK_ICON $CURRSSID /")
        notify-send "📢 ATENÇÃO 📢" "Rede Atual: <b>🟢 $CURRSSID</b>"
    fi
}



# Função para ajustar o número de linhas do menu
adjust_menu_lines() {
    if [ "$LINENUM" -gt "$MAX_LINES" ] && [[ "$WIFI_STATE" =~ "enabled" ]]; then
        LINENUM=$MAX_LINES
    elif [[ "$WIFI_STATE" =~ "disabled" ]]; then
        LINENUM=1
    fi
}

# Função para definir o texto do botão de ativação/desativação do Wi-Fi
set_toggle_text() {
    TOGGLE="Ativar WiFi"
    if [[ "$WIFI_STATE" =~ "enabled" ]]; then
        TOGGLE="Desativar WiFi"
    fi
}

# Função para exibir o menu Wofi e capturar a escolha
show_menu() {
    CHENTRY=$(echo -e "$TOGGLE\nConexão Manual\n$LIST" | uniq -u | \
        wofi -i -d -n\
        --prompt "Selecione uma rede WiFi: " \
        --lines "$MAX_LINES" \
        --width "$WOFI_WIDTH")
    CHSSID=$(echo "$CHENTRY" | sed 's/\s\{2,\}/\|/g' | awk -F "|" '{print $1}')
}

# Função para processar a escolha do usuário
process_choice() {
    case "$CHENTRY" in
        "Conexão Manual")
            manual_connection
            ;;
        "Ativar WiFi")
            nmcli radio wifi on
            ;;
        "Desativar WiFi")
            nmcli radio wifi off
            ;;
        *)
            connect_to_network
            ;;
    esac
}

# Função para conectar manualmente a uma rede
manual_connection() {
    MSSID=$(echo "Digite o SSID da rede (SSID,senha)" | \
        wofi -n -d "Conexão Manual: " --lines 1)
    MPASS=$(echo "$MSSID" | awk -F "," '{print $2}')
    
    if [ -z "$MPASS" ]; then
        nmcli dev wifi con "$MSSID"
    else
        nmcli dev wifi con "$MSSID" password "$MPASS"
    fi
}

# Função para conectar a uma rede WiFi
connect_to_network() {
    if [ "$CHSSID" = "*" ]; then
        CHSSID=$(echo "$CHENTRY" | sed 's/\s\{2,\}/\|/g' | awk -F "|" '{print $3}')
    fi
    
    if echo "$KNOWNCON" | grep -q "$CHSSID"; then
        nmcli con up "$CHSSID"
    else
        if [[ "$CHENTRY" =~ "WPA2" ]] || [[ "$CHENTRY" =~ "WEP" ]]; then
            WIFIPASS=$(echo "Pressione Enter se a conexão já estiver salva" | \
                wofi -P -d -n \
                --prompt "Senha:" \
                --lines 1 \
                --location "$POSITION" \
                --yoffset "$YOFF" \
                --xoffset "$XOFF" \
                --width "$RWIDTH")
        fi
        nmcli dev wifi con "$CHSSID" password "$WIFIPASS"
    fi
    notify-send "📢 ATENÇÃO 📢" "Nova Rede: <b>🟢 $CURRSSID</b>"
}

# Executa as funções na ordem necessária
update_wifi_info
list_wifi_networks
adjust_menu_lines
set_toggle_text
show_menu
process_choice
