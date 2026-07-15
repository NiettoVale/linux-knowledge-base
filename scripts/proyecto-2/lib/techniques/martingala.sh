#!/bin/bash

function martingala(){
    # Capturamos el dinero inicial que le pasamos desde bin/ruleta
    local money="$1" 

    echo -ne "\n${_acento}¿Cuánto dinero quieres apostar? ${_endcolor}" && read initial_bet
    
    while ! [[ $initial_bet =~ ^[0-9]+$ ]] || [[ $initial_bet -gt $money ]]; do
        print_alerta "\n[✗] Error: Ingresa un monto numérico válido que no supere tu dinero actual (\$${money}).\n"
        echo -ne "${_acento}¿Cuánto dinero quieres apostar? ${_endcolor}" && read initial_bet
    done

    echo -ne "${_acento}¿A que quieres apostar continuamente (par/impar)? ${_endcolor}" && read selection_bet

    while ! isValidSelection "$selection_bet"; do
        print_alerta "\n[✗] Error: Debes ingresar una selección válida (par/impar).\n"
        echo -ne "${_acento}¿A qué quieres apostar continuamente (par/impar)? ${_endcolor}" && read selection_bet
    done

    clear
    presentation

    echo -e "\n${_acento}==========================================${_endcolor}"
    echo -e "${_texto} 🎲 Técnica actual        : ${_brillo}MARTINGALA${_endcolor}"
    echo -e "${_texto} 💰 Dinero en caja        : ${_brillo}\$${money}${_endcolor}"
    echo -e "${_texto} 💵 Apuesta inicial       : ${_brillo}\$${initial_bet}${_endcolor}"
    echo -e "${_texto} 🎯 Selección de apuesta  : ${_brillo}${selection_bet}${_endcolor}"
    echo -e "${_acento}==========================================${_endcolor}\n"

    tput civis
    while true; do
        random_number=$(randomNumber)
    
        if [[ "$random_number" -eq 0 ]]; then
            echo -e "${_alerta}[!] Salió el 0 (Verde). ¡La casa gana! PIERDES. ❌${_endcolor}"
        else
            if [[ $(("$random_number" % 2)) -eq 0 ]]; then
                resultado_ruleta="par"
            else
                resultado_ruleta="impar"
            fi

            if [[ "$resultado_ruleta" == "$selection_bet" ]]; then
                echo -e "${_texto}[+] Salió el ${_brillo}$random_number ($resultado_ruleta)${_texto}. ¡GANASTE! 💸${_endcolor}"
            else
                echo -e "${_texto}[-] Salió el ${_alerta}$random_number ($resultado_ruleta)${_texto}. PIERDES. ❌${_endcolor}"
            fi
        fi

        sleep 0.4
    done
    
    tput cnorm
}