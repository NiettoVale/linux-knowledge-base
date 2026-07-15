#!/bin/bash

function martingala(){
    # Capturamos el dinero inicial que le pasamos desde bin/ruleta
    local money="$1" 

    echo -ne "\n${_acento}¿Cuánto dinero quieres apostar? ${_endcolor}" && read initial_bet
    
    while ! [[ $initial_bet =~ ^[0-9]+$ ]] || [[ $initial_bet -gt $money ]]; do
        print_alerta "\n[✗] Error: Ingresa un monto numérico válido que no supere tu dinero actual (\$${money}).\n"
        echo -ne "${_acento}¿Cuánto dinero quieres apostar? ${_endcolor}" && read initial_bet
    done

    echo -ne "${_acento}¿A que quieres apostar continuamente (par/impar)? ${_endcolor}" && read even_odd

    while ! isValidSelection "$even_odd"; do
        print_alerta "\n[✗] Error: Debes ingresar una selección válida (par/impar).\n"
        echo -ne "${_acento}¿A qué quieres apostar continuamente (par/impar)? ${_endcolor}" && read even_odd
    done

    clear
    presentation

    echo -e "\n${_acento}==========================================${_endcolor}"
    echo -e "${_texto} 🎲 Técnica actual        : ${_brillo}MARTINGALA${_endcolor}"
    echo -e "${_texto} 💰 Dinero en caja        : ${_brillo}\$${money}${_endcolor}"
    echo -e "${_texto} 💰 Apuesta inicial       : ${_brillo}\$${initial_bet}${_endcolor}"
    echo -e "${_texto} 🎲 Seleccionde apuesta   : ${_brillo}${even_odd}${_endcolor}"
    echo -e "${_acento}==========================================${_endcolor}\n"
    
}