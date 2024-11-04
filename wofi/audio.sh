#!/usr/bin/env bash
# Verifica se o pactl está instalado
command -v pactl >/dev/null 2>&1 || {
  echo "pactl não está instalado. Por favor, instale-o primeiro."
  exit 1
}

# Função para listar dispositivos de saída de áudio (sinks) com descrições amigáveis
list_output_devices() {
  pactl list short sinks | while read -r line; do
    id=$(echo "$line" | awk '{print $1}')
    description=$(pactl list sinks | grep -A60 "^Sink #$id" | grep "node.nick =" | sed 's/.*node.nick = "\(.*\)"/\1/')
    if [ -z "$description" ]; then
      description=$(pactl list sinks | grep -A20 "^Sink #$id" | grep "Description:" | sed 's/Description: //')
    fi
    echo "$id - $description" # Inclui o ID junto com a descrição
  done
}

# Função para listar dispositivos de entrada de áudio (sources) com descrições amigáveis
list_input_devices() {
  pactl list short sources | while read -r line; do
    id=$(echo "$line" | awk '{print $1}')
    description=$(pactl list sources | grep -A60 "^Source #$id" | grep "node.nick =" | sed 's/.*node.nick = "\(.*\)"/\1/')
    if [ -z "$description" ]; then
      description=$(pactl list sources | grep -A20 "^Source #$id" | grep "Description:" | sed 's/Description: //')
    fi
    echo "$id - $description" # Inclui o ID junto com a descrição
  done
}

# Função para definir o dispositivo de saída padrão
set_output_device() {
  local sink_id=$1
  echo "Tentando definir o dispositivo de saída para ID: $sink_id" # Debug
  pactl set-default-sink "$sink_id" && {
    description=$(pactl list sinks | grep -A60 "^Sink #$sink_id" | grep "node.nick =" | sed 's/.*node.nick = "\(.*\)"/\1/')
    if [ -z "$description" ]; then
      description=$(pactl list sinks | grep -A20 "^Sink #$sink_id" | grep "Description:" | sed 's/Description: //')
    fi
    notify-send "🟢 Sucesso" "Dispositivo de saída alterado para <b>$description</b>"
    echo "Dispositivo de saída definido com sucesso."
  } || {
    notify-send "🔴 Erro" "Falha ao alterar dispositivo de saída."
    echo "Falha ao alterar dispositivo de saída."
  }
}

# Função para definir o dispositivo de entrada padrão
set_input_device() {
  local source_id=$1
  echo "Tentando definir o dispositivo de entrada para ID: $source_id" # Debug
  pactl set-default-source "$source_id" && {
    description=$(pactl list sources | grep -A60 "^Source #$source_id" | grep "node.nick =" | sed 's/.*node.nick = "\(.*\)"/\1/')
    if [ -z "$description" ]; then
      description=$(pactl list sources | grep -A20 "^Source #$source_id" | grep "Description:" | sed 's/Description: //')
    fi
    notify-send "Dispositivo de entrada alterado para $description"
    echo "Dispositivo de entrada definido com sucesso."
  } || {
    notify-send "Falha ao alterar dispositivo de entrada."
    echo "Falha ao alterar dispositivo de entrada."
  }
}

# Exibe menu inicial para escolher o tipo de dispositivo
DEVICE_TYPE=$(echo -e "🔊 Saída\n🎤 Entrada\n◀️ Sair" | wofi -n --width 400 --height 300 -d -p "Escolha uma Opção")

# Exibe o menu de dispositivos disponíveis e define o dispositivo selecionado
case "$DEVICE_TYPE" in
"🔊 Saída")
  OUTPUT_DEVICE=$(list_output_devices | wofi -n --dmenu --width 400 --height 300 -d -p "Dispositivos de Saída" | awk '{print $1}')
  if [ -n "$OUTPUT_DEVICE" ]; then
    set_output_device "$OUTPUT_DEVICE"
  else
    notify-send "Nenhum dispositivo de saída selecionado."
  fi
  ;;
"🎤 Entrada")
  INPUT_DEVICE=$(list_input_devices | wofi -n --dmenu --width 400 --height 300 -d -p "Dispositivos de Entrada" | awk '{print $1}')
  if [ -n "$INPUT_DEVICE" ]; then
    set_input_device "$INPUT_DEVICE"
  else
    notify-send "Nenhum dispositivo de entrada selecionado."
  fi
  ;;
"Sair")
  exit 0
  ;;
*)
  notify-send "Opção inválida selecionada."
  ;;
esac
