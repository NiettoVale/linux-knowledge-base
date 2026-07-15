#!/bin/bash

function ctrl_c(){
    print_alerta "\n\n[!] Saliendo del programa...\n"
    tput cnorm && exit 1
}


function randomNumber(){
    echo "$(($RANDOM % 37))"
}