#!/bin/bash

function isValidMoney(){
    money="$1"

    if ! [[ $money =~ ^[0-9]+$ ]]; then
        print_alerta "\n[✗] Error: El presupuesto inicial (-m) debe ser un número entero válido.\n\n"
        helpPanel
        exit 1
    fi
}

function isValidSelection(){
    selection="$1"

    if [[ "$selection" != "par" && "$selection" != "impar" ]];then
        return 1
    else
        return 0
    fi
}