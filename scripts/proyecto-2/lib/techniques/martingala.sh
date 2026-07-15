#!/bin/bash

function martingala(){
    money="$1" 

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
    echo -e "${_texto} 💰 Dinero inicial        : ${_brillo}\$${money}${_endcolor}"
    echo -e "${_texto} 💵 Apuesta inicial       : ${_brillo}\$${initial_bet}${_endcolor}"
    echo -e "${_texto} 💰 Dinero en caja        : ${_brillo}\$$((money - initial_bet))${_endcolor}"
    echo -e "${_texto} 🎯 Selección de apuesta  : ${_brillo}${selection_bet}${_endcolor}"
    echo -e "${_acento}==========================================${_endcolor}\n"

    tput civis
    actual_bet="$initial_bet"

    while true; do
        if [[ "$money" -lt  "$actual_bet" ]];then
            echo -e "\n${_alerta}[!] BANCARROTA. No te alcanza para cubrir la próxima apuesta de \$${actual_bet}.${_endcolor}"
            echo -e "${_texto}[i] Te sobraron \$${money} en la caja. El casino te invita a retirarte.${_endcolor}\n"
            break
        fi

        money=$(("$money" - "$actual_bet"))
        random_number=$(randomNumber)

        if [[ "$random_number" -eq 0 ]]; then
            echo -e "${_alerta}[!] Salió el 0 (Verde). ¡La casa gana! PIERDES. ❌ | Caja actual: \$${money}${_endcolor}"
            actual_bet=$(("$actual_bet" * 2))
        else
            if [[ $(("$random_number" % 2)) -eq 0 ]]; then
                resultado_ruleta="par"
            else
                resultado_ruleta="impar"
            fi

            if [[ "$resultado_ruleta" == "$selection_bet" ]]; then
    
                reward=$(("$actual_bet" * 2))
                money=$(("$money" + "$reward"))
                echo -e "${_texto}[+] Salió el ${_brillo}$random_number ($resultado_ruleta)${_texto}. ¡GANASTE! 💸 | Caja actual: \$${money}${_endcolor}"
                
    
                actual_bet="$initial_bet"
            else
    
                echo -e "${_texto}[-] Salió el ${_alerta}$random_number ($resultado_ruleta)${_texto}. PIERDES. ❌ | Caja actual: \$${money}${_endcolor}"
                actual_bet=$(("$actual_bet" * 2))
            fi
        fi

        sleep 2
    done
    
    tput cnorm
}