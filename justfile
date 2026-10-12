default:
    @just --list

build:
    nix build

flash *parts:
    nix run .#flash -- {{parts}}

settings-reset:
    nix run .#flash-settings-reset

update:
    nix run .#update

update-inputs:
    nix flake update

editor:
    xdg-open https://nickcoutsos.github.io/keymap-editor/
