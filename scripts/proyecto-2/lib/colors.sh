#!/bin/bash

# Colores internos
_texto=$'\e[38;2;207;207;207m'
_titulo=$'\e[1m\e[38;2;255;255;255m'
_acento=$'\e[38;2;112;0;255m'
_alerta=$'\e[38;2;255;0;60m'
_brillo=$'\e[38;2;255;0;128m'
_endcolor=$'\e[0m'

# Funciones que auto-aplican el color y lo cierran al final
print_texto() { echo -e "${_texto}$1${_endcolor}"; }
print_titulo() { echo -e "${_titulo}$1${_endcolor}"; }
print_acento() { echo -e "${_acento}$1${_endcolor}"; }
print_alerta() { echo -e "${_alerta}$1${_endcolor}"; }
print_brillo() { echo -e "${_brillo}$1${_endcolor}"; }