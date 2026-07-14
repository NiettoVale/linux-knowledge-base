#!/bin/bash

source "$PROJECT_DIR/lib/colors.sh"

function ctrl_c(){
    print_alerta "\n\n[!] Saliendo del programa...\n"
    tput cnorm && exit 1
}

function presentation(){
    print_titulo "=== HTB MACHINES ==="
}

function helpPanel(){
    print_acento "\n[+] Uso:"
    print_texto "    -u                  : Descargar o actualizar ficheros necesarios"
    print_texto "    -m <nombre_maquina> : Buscar una máquina por su nombre"
    print_texto "    -h                  : Mostrar este panel de ayuda"
}

function searchMachine(){
    machine=$(print_texto "$1")
    print_brillo "⚡ Buscando la máquina: $machine\n"

    cat ./scripts/proyecto-1/data/bundle.js | \
        awk "/name: \"$1\"/,/resuelta:/" | \
        grep -vE "id:|sku:" | \
        tr -d "," | \
        sed "s/^ *//" | \
        sed "s/^\([^:]*\):/\x1b[38;2;112;0;255m\1\x1b[0m:/"
}

function updateFile(){
    tput civis
    print_acento "\n[+] Sincronizando base de datos local (bundle.js)..."
    sleep 2
    
    if ! existFile; then
        print_brillo "\n[i] El archivo 'bundle.js' no existe en el sistema. Iniciando descarga..."
        
        if curl -s -X GET "$main_url" | js-beautify | sponge "$PROJECT_DIR/data/bundle.js"; then
            print_acento "\n[✓] Descarga y formateo finalizados con éxito."
        else
            print_alerta "\n[✗] Hubo un error al intentar descargar el archivo."
        fi
    else
        print_texto "\n[i] El archivo 'bundle.js' ya se encuentra en el sistema."
        print_acento "[i] Comprobando integridad y buscando actualizaciones en el servidor..."

        curl -s -X GET "$main_url" | js-beautify | sponge "$PROJECT_DIR/data/bundle_temp.js"

        original_hash=$(sha256sum "$PROJECT_DIR/data/bundle.js" | awk '{print $1}')
        temp_hash=$(sha256sum "$PROJECT_DIR/data/bundle_temp.js" | awk '{print $1}')
        
        if [[ "$original_hash" == "$temp_hash" ]]; then
            print_texto "\n[✓] Tu base de datos ya está en la versión más reciente. No hay cambios."
            
            rm "$PROJECT_DIR/data/bundle_temp.js"
        else
            print_brillo "\n[!] ¡Nueva actualización detectada en el servidor!"
            print_acento "[i] Reemplazando base de datos antigua por la nueva versión..."
            
            rm "$PROJECT_DIR/data/bundle.js" && mv "$PROJECT_DIR/data/bundle_temp.js" "$PROJECT_DIR/data/bundle.js"
            
            print_brillo "[✓] Actualización completada con éxito."
        fi
    fi
    tput cnorm
}

function existFile(){
    if [[ -f "$PROJECT_DIR/data/bundle.js" ]]; then
        return 0
    else
        return 1
    fi
}