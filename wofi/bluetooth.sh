#!/usr/bin/env bash

# Configurações do Wofi
WOFI_OPTIONS="--dmenu --width 400 --height 300 --prompt 'Escolha:'"
NOTIFY="notify-send Bluetooth.sh"

# Função para configurar o adaptador Bluetooth e iniciar o agente
setup_bluetooth() {
    echo "Ativando adaptador Bluetooth..."
    bluetoothctl power on
    bluetoothctl agent on
    bluetoothctl default-agent
    bluetoothctl pairable on
    bluetoothctl discoverable on
}

# Função para escanear e listar dispositivos Bluetooth próximos
scan_devices() {
    $NOTIFY "Iniciando escaneamento de dispositivos..."
    bluetoothctl scan on &
    sleep 5  # Aguarda alguns segundos para descobrir os dispositivos

    # Lista dispositivos encontrados e exibe no wofi
    DEVICES=$(bluetoothctl devices | awk '{print $2 " " $3}')
    DEVICE_SELECTED=$(echo "$DEVICES" | wofi --dmenu --width 400 --height 300 --prompt "Selecione um dispositivo:")

    # Verifica se "Esc" foi pressionado
    if [ -z "$DEVICE_SELECTED" ]; then
        $NOTIFY "Nenhum dispositivo selecionado. Voltando ao menu principal..."
        bluetoothctl scan off
        return 1  # Retorna ao menu principal
    fi

    # Extrai o MAC do dispositivo selecionado
    DEVICE_MAC=$(echo "$DEVICE_SELECTED" | awk '{print $1}')
    $NOTIFY "Selecionado: $DEVICE_SELECTED"
    bluetoothctl scan off  # Para o escaneamento
}

# Funções para parear, conectar, desconectar e remover pareamento
pair_device() {
    $NOTIFY "Pareando com o dispositivo $DEVICE_MAC..."
    bluetoothctl pair "$DEVICE_MAC"
    bluetoothctl trust "$DEVICE_MAC"
}

connect_device() {
    $NOTIFY "Conectando ao dispositivo $DEVICE_MAC..."
    bluetoothctl connect "$DEVICE_MAC"
}

disconnect_device() {
    $NOTIFY "Desconectando do dispositivo $DEVICE_MAC..."
    bluetoothctl disconnect "$DEVICE_MAC"
}

remove_device() {
    $NOTIFY "Removendo pareamento do dispositivo $DEVICE_MAC..."
    bluetoothctl remove "$DEVICE_MAC"
}

# Menu principal com opções simplificadas
main_menu() {
    echo -e "Conectar (escaneamento)\nConectar (MAC conhecido)\nDesconectar\nRemover pareamento"
}

# Loop principal que exibe o menu até o usuário sair
while true; do
    # Exibe o menu principal e captura a escolha do usuário
    OPTION=$(main_menu | wofi $WOFI_OPTIONS)

    # Verifica se "Esc" foi pressionado para sair do script
    if [ -z "$OPTION" ]; then
        echo "Saindo do script."
        exit 0
    fi

    # Executa a ação escolhida pelo usuário
    case "$OPTION" in
        "Conectar (escaneamento)")
            setup_bluetooth
            if scan_devices; then
                pair_device
                connect_device
            fi
            ;;
        "Conectar (MAC conhecido)")
            DEVICE_MAC=$(wofi --dmenu --prompt "Digite o MAC:" --width 400 --lines 1)
            # Verifica se "Esc" foi pressionado para voltar ao menu principal
            if [ -z "$DEVICE_MAC" ]; then
                echo "Nenhum MAC inserido. Voltando ao menu principal..."
                continue
            fi
            setup_bluetooth
            pair_device
            connect_device
            ;;
        "Desconectar")
            DEVICE_MAC=$(wofi --dmenu --prompt "Digite o MAC para desconectar:" --width 400 --lines 1)
            if [ -z "$DEVICE_MAC" ]; then
                echo "Nenhum MAC inserido. Voltando ao menu principal..."
                continue
            fi
            disconnect_device
            ;;
        "Remover pareamento")
            DEVICE_MAC=$(wofi --dmenu --prompt "Digite o MAC para remover:" --width 400 --lines 1)
            if [ -z "$DEVICE_MAC" ]; then
                echo "Nenhum MAC inserido. Voltando ao menu principal..."
                continue
            fi
            disconnect_device
            remove_device
            ;;
        *)
            $NOTIFY "Opção inválida ou cancelada. Voltando ao menu principal..."
            ;;
    esac

    echo "Ação concluída."
done
