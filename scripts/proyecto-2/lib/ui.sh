#!/bin/bash

function helpPanel(){
    echo -e "${_titulo}=== SIMULADOR DE RULETA - CASINO SECURE ===${_endcolor}
    ${_acento}[+] Uso:${_endcolor} ${_texto}./ruleta -m <dinero> -t <tecnica>${_endcolor}

        ${_acento}[+] Opciones:${_endcolor}
            ${_brillo}-m <monto>${_endcolor}     ${_texto}Presupuesto inicial de tu billetera (Ej: 1000)${_endcolor}
            ${_brillo}-t <tecnica>${_endcolor}   ${_texto}Estrategia a simular (martingala | reverse_labouchere)${_endcolor}
            ${_brillo}-h${_endcolor}             ${_texto}Muestra este panel de ayuda${_endcolor}

        ${_acento}[+] Ejemplos:${_endcolor}
            ${_texto}./ruleta -m 500 -t martingala${_endcolor}
            ${_texto}./ruleta -m 1500 -t reverse_labouchere${_endcolor}
    "
}

function presentation(){
    echo -e "${_brillo}"
    cat << "EOF"
  ____        _      _        
 |  _ \ _   _| | ___| |_ __ _ 
 | |_) | | | | |/ _ \ __/ _` |
 |  _ <| |_| | |  __/ || (_| |
 |_| \_\__,_|_|\___|\__\__,_|
EOF
    echo -e "${_acento}     [ CASINO SECURE - BASH EDITION ]"
    echo -e "${_texto}==========================================${_endcolor}\n"
}