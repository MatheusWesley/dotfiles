#!/usr/bin/env bash

# Variáveis de configuração
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FIELDS=SSID,SECURITY    # Adicionado BARS e RATE para mostrar força do sinal e velocidade
POSITION=3
YOFF=20
XOFF=-40
WOFI_WIDTH=400
MAX_LINES=8

# Carrega configurações personalizadas
if [ -r "$DIR/config" ]; then
    source "$DIR/config"
elif [ -r "$HOME/.config/wofi/wifi" ]; then
    source "$HOME/.config/wofi/wifi"
else
    echo "AVISO: arquivo de configuração não encontrado! Usando valores padrão."
fi

# Força uma nova varredura de redes WiFi disponíveis
nmcli device wifi rescan || true

# Obtém a lista de redes WiFi
LIST=$(nmcli --fields "$FIELDS" device wifi list | sed '/^--/d')
RWIDTH=$(($(echo "$LIST" | head -n 1 | awk '{print length($0); }')*20))
LINENUM=$(echo "$LIST" | wc -l)

# Obtém conexões conhecidas e estado atual
KNOWNCON=$(nmcli connection show)
WIFI_STATE=$(nmcli -fields WIFI g)
CURRSSID=$(LANGUAGE=C nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}')

# Destaca a rede atual
if [[ -n $CURRSSID ]]; then
    HIGHLINE=$(echo "$LIST" | awk -F "[  ]{2,}" '{print $1}' | awk '{print NR}' "$CURRSSID")
fi

# Ajusta número de linhas do menu
if [ "$LINENUM" -gt "$MAX_LINES" ] && [[ "$WIFI_STATE" =~ "enabled" ]]; then
    LINENUM=$MAX_LINES
elif [[ "$WIFI_STATE" =~ "disabled" ]]; then
    LINENUM=1
fi

# Define texto do botão toggle
TOGGLE="Ativar WiFi"
if [[ "$WIFI_STATE" =~ "enabled" ]]; then
    TOGGLE="Desativar WiFi"
fi

# Mostra menu wofi com opções
CHENTRY=$(echo -e "$TOGGLE\nConexão Manual\n$LIST" | uniq -u | \
    wofi -i -d \
    --prompt "Selecione uma rede WiFi: " \
    --lines "$MAX_LINES" \
    --width "$WOFI_WIDTH")

# Extrai SSID selecionado
CHSSID=$(echo "$CHENTRY" | sed 's/\s\{2,\}/\|/g' | awk -F "|" '{print $1}')

# Processa a escolha do usuário
case "$CHENTRY" in
    "Conexão Manual")
        # Entrada manual de SSID e senha
        MSSID=$(echo "Digite o SSID da rede (SSID,senha)" | \
            wofi -d "Conexão Manual: " --lines 1)
        MPASS=$(echo "$MSSID" | awk -F "," '{print $2}')
        
        if [ -z "$MPASS" ]; then
            nmcli dev wifi con "$MSSID"
        else
            nmcli dev wifi con "$MSSID" password "$MPASS"
        fi
        ;;
        
    "Ativar WiFi")
        nmcli radio wifi on
        ;;
        
    "Desativar WiFi")
        nmcli radio wifi off
        ;;
        
    *)
        # Conecta à rede selecionada
        if [ "$CHSSID" = "*" ]; then
            CHSSID=$(echo "$CHENTRY" | sed 's/\s\{2,\}/\|/g' | awk -F "|" '{print $3}')
        fi
        
        if echo "$KNOWNCON" | grep -q "$CHSSID"; then
            nmcli con up "$CHSSID"
        else
            if [[ "$CHENTRY" =~ "WPA2" ]] || [[ "$CHENTRY" =~ "WEP" ]]; then
                WIFIPASS=$(echo "Pressione Enter se a conexão já estiver salva" | \
                    wofi -P -d \
                    --prompt "Senha:" \
                    --lines 1 \
                    --location "$POSITION" \
                    --yoffset "$YOFF" \
                    --xoffset "$XOFF" \
                    --width "$RWIDTH")
            fi
            nmcli dev wifi con "$CHSSID" password "$WIFIPASS"
        fi
        ;;
esac
