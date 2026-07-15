#!/bin/bash

function isValidMoney(){
    money="$1"

    if ! [[ $money =~ ^[0-9]+$ ]]; then
        print_alerta "\n[✗] Error: El presupuesto inicial (-m) debe ser un número entero válido."
        helpPanel
        exit 1
    fi
}