#!/bin/bash

function presentation(){
    print_titulo "=== HTB MACHINES ==="
}

function helpPanel(){
    print_acento "\n[+] Uso:"
    print_texto "    -u                  : Descargar o actualizar ficheros necesarios"
    print_texto "    -i <dirección_ip>   : Buscar una máquina por su IP"
    print_texto "    -y <nombre_maquina> : Busca el link de YouTube de una máquina"
    print_texto "    -m <nombre_maquina> : Buscar una máquina por su nombre"
    print_texto "    -h                  : Mostrar este panel de ayuda"
}