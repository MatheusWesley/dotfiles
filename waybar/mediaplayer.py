#!/usr/bin/env python3
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
from gi.repository.Playerctl import Player
import argparse
import logging
import sys
import signal
import json
import os
from typing import List

logger = logging.getLogger(__name__)

# Função para manipular sinal de interrupção (Ctrl+C)
def signal_handler(sig, frame):
    logger.info("Sinal recebido para parar, saindo")
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)


class PlayerManager:
    def __init__(self, selected_player=None, excluded_player=[]):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()
        self.manager.connect("name-appeared", lambda *args: self.on_player_appeared(*args))
        self.manager.connect("player-vanished", lambda *args: self.on_player_vanished(*args))

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
        self.selected_player = selected_player
        self.excluded_player = excluded_player.split(',') if excluded_player else []

        self.init_players()

    # Função para inicializar os players
    def init_players(self):
        for player in self.manager.props.player_names:
            if player.name in self.excluded_player:
                continue
            if self.selected_player is not None and self.selected_player != player.name:
                logger.debug(f"{player.name} não é o player filtrado, ignorando")
                continue
            self.init_player(player)

    # Executa o loop principal
    def run(self):
        logger.info("Iniciando loop principal")
        self.loop.run()

    # Função para inicializar um player específico
    def init_player(self, player):
        logger.info(f"Inicializando novo player: {player.name}")
        player = Playerctl.Player.new_from_name(player)
        player.connect("playback-status", self.on_playback_status_changed, None)
        player.connect("metadata", self.on_metadata_changed, None)
        self.manager.manage_player(player)
        self.on_metadata_changed(player, player.props.metadata)

    # Retorna todos os players gerenciados
    def get_players(self) -> List[Player]:
        return self.manager.props.players

    # Escreve a saída para o Waybar
    def write_output(self, text, player):
        logger.debug(f"Escrevendo saída: {text}")
        output = {"text": text, "class": "custom-" + player.props.player_name, "alt": player.props.player_name}
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    # Limpa a saída
    def clear_output(self):
        sys.stdout.write("\n")
        sys.stdout.flush()

    # Callback para mudanças no status de reprodução
    def on_playback_status_changed(self, player, status, _=None):
        logger.debug(f"Status de reprodução alterado para o player {player.props.player_name}: {status}")
        self.on_metadata_changed(player, player.props.metadata)

    # Função para obter o primeiro player em reprodução
    def get_first_playing_player(self):
        players = self.get_players()
        logger.debug(f"Obtendo o primeiro player em reprodução de {len(players)} players")
        if len(players) > 0:
            for player in players[::-1]:
                if player.props.status == "Playing":
                    return player
            return players[0]
        else:
            logger.debug("Nenhum player encontrado")
            return None

    # Mostra o player mais importante atualmente
    def show_most_important_player(self):
        logger.debug("Mostrando o player mais importante")
        current_player = self.get_first_playing_player()
        if current_player is not None:
            self.on_metadata_changed(current_player, current_player.props.metadata)
        else:
            self.clear_output()

    # Callback para mudanças nos metadados do player
    def on_metadata_changed(self, player, metadata, _=None):
        logger.debug(f"Metadados alterados para o player {player.props.player_name}")
        player_name = player.props.player_name
        artist = player.get_artist()
        title = player.get_title()
        title = title.replace("&", "&amp;")

        # Escolha do ícone conforme o player
        icon = "" if player_name == "spotify" else ""
        track_info = f"{icon} {title}" if title else icon

        # Mostrar status de reprodução
        if track_info:
            if player.props.status == "Playing":
                track_info = " " + track_info
            else:
                track_info = " " + track_info

        current_playing = self.get_first_playing_player()
        if current_playing is None or current_playing.props.player_name == player.props.player_name:
            self.write_output(track_info, player)
        else:
            logger.debug(f"Outro player {current_playing.props.player_name} está em reprodução, ignorando")

    # Callback para quando um player aparece
    def on_player_appeared(self, _, player):
        logger.info(f"Player apareceu: {player.name}")
        if player.name in self.excluded_player:
            logger.debug("Novo player apareceu, mas está na lista de exclusão, ignorando")
            return
        if player is not None and (self.selected_player is None or player.name == self.selected_player):
            self.init_player(player)
        else:
            logger.debug("Novo player apareceu, mas não é o player selecionado, ignorando")

    # Callback para quando um player desaparece
    def on_player_vanished(self, _, player):
        logger.info(f"Player {player.props.player_name} desapareceu")
        self.show_most_important_player()

# Função para analisar argumentos de linha de comando
def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="count", default=0)
    parser.add_argument("-x", "--exclude", help="Lista separada por vírgulas de players a serem excluídos")
    parser.add_argument("--player", help="Define o player que será escutado")
    parser.add_argument("--enable-logging", action="store_true")
    return parser.parse_args()

# Função principal
def main():
    arguments = parse_arguments()
    if arguments.enable_logging:
        logfile = os.path.join(os.path.dirname(os.path.realpath(__file__)), "media-player.log")
        logging.basicConfig(filename=logfile, level=logging.DEBUG, format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")

    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    logger.info("Criando gerenciador de players")
    if arguments.player:
        logger.info(f"Filtrando para o player: {arguments.player}")
    if arguments.exclude:
        logger.info(f"Excluindo player {arguments.exclude}")

    player = PlayerManager(arguments.player, arguments.exclude)
    player.run()

# Adiciona comandos de controle de mídia
if __name__ == "__main__":
    main()
    if len(sys.argv) > 1:
        command = sys.argv[1]
        if command == "next":
            subprocess.call(["playerctl", "next"])
        elif command == "previous":
            subprocess.call(["playerctl", "previous"])
        elif command == "status":
            subprocess.call(["playerctl", "status"])
