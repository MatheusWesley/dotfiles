# Requisitos para Utilização dos Dotfiles

Este arquivo contém as instruções e requisitos mínimos para configurar corretamente os dotfiles disponíveis neste repositório: [GitHub - MatheusWesley/dotfiles](https://github.com/MatheusWesley/dotfiles).

## Programas Necessários

Para garantir o funcionamento adequado das configurações, instale os seguintes programas:

1. **GNU Stow**: Gerenciador de links simbólicos para organizar e aplicar os dotfiles.
2. **Hyprpaper**: Gerenciador de wallpapers para ambientes Hyprland.
3. **Dunst**: Gerenciador de notificações leve e personalizável.
4. **Tmux**: Multiplexador de terminais que permite gerenciar múltiplas sessões de terminal.
5. **Waybar**: Barra superior para ambientes Wayland, compatível com Hyprland.
6. **Wofi**: Lançador de aplicações leve e altamente configurável.
7. **Kitty**: Emulador de terminal rápido e com suporte a gráficos e alta personalização.
8. **Starship**: Prompt de linha de comando personalizável, compatível com diversos terminais.
9. **Flameshot** (opcional): Ferramenta de captura de tela com diversas opções de anotação.
10. **Blueman Manager**: Gerenciador de dispositivos Bluetooth.

> **Observação**: Certifique-se de que todos esses programas estão configurados para iniciar automaticamente, conforme necessário.

## Temas

1. **Catppuccin Mocha**: Tema com paleta de cores suave e agradável, compatível com diversas aplicações, incluindo o Waybar e o Starship.

> **Dica**: Verifique a documentação de cada programa para ajustar o tema Catppuccin Mocha, garantindo uma aparência consistente.

## Configuração dos Dotfiles

Para aplicar as configurações, utilize o **GNU Stow** para criar os links simbólicos automaticamente no diretório de destino:

```bash
stow <nome_da_pasta>
