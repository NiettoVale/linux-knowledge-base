#!/bin/bash

money=0
technique=""

while getopts "m:t:h" arg; do
    case $arg in
        m) money="$OPTARG" ;;
        t) technique="$OPTARG" ;;
        h) helpPanel; exit 0 ;;
        *) helpPanel; exit 1 ;;
    esac
done

if [[ $money -eq 0 ]] || [[ -z "$technique" ]];then
    print_alerta "[✗] Error: Faltan parámetros obligatorios.\n"
    helpPanel
    exit 1
fi