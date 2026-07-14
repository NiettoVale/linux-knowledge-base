#!/bin/bash

source "$PROJECT_DIR/lib/colors.sh"
source "$PROJECT_DIR/lib/validators.sh"

function ctrl_c(){
    print_alerta "\n\n[!] Saliendo del programa...\n"
    tput cnorm && exit 1
}

function searchMachine(){
    machine_name="$1"
    machine_colored=$(print_texto "$machine_name")

    if check_machine_exists "$machine_name"; then
        print_brillo "⚡ Buscando la máquina: $machine_colored\n"

        cat "$PROJECT_DIR/data/bundle.js" | \
            awk "/name: \"$machine_name\"/,/resuelta:/" | \
            grep -vE "id:|sku:" | \
            tr -d "," | \
            sed "s/^ *//" | \
            sed "s/^\([^:]*\):/\x1b[38;2;112;0;255m\1\x1b[0m:/"
    else
        print_alerta "\n[✗] La máquina '$machine_name' no existe en el sistema."
    fi
}

function searchIP(){
    ipAddress="$1"
    
    if check_ip_exists "$ipAddress"; then
        print_brillo "⚡ Buscando máquina asociada a la IP: ${_texto}$ipAddress\n"
        machineName=$(
            cat "$PROJECT_DIR/data/bundle.js" | \
                grep "ip: \"$ipAddress\"" -B 3 | \
                grep "name: " | \
                awk 'NF{print $NF}' | \
                tr -d '"' | tr -d ','
        )

        print_texto "[✓] La máquina asociada es: ${_acento}$machineName"
    else
        print_alerta "\n[✗] No se encontró ninguna máquina con la IP: $ipAddress"
    fi
}

function youtubeLink(){
    machine_name="$1"

    if check_machine_exists "$machine_name"; then
        link=$(
            cat "$PROJECT_DIR/data/bundle.js" | \
                awk "/name: \"$machine_name\"/,/resuelta:/" | \
                grep "youtube:" | \
                awk 'NF{print $NF}' | \
                tr -d '"' | tr -d ','
        )

        if [[ -n "$link" ]]; then
            print_texto "${_acento}[✓] Link:${_texto} $link"
        else
            print_alerta "[✗] No se encontró ningún canal de YouTube para esta máquina."
        fi
    else
        print_alerta "\n[✗] La máquina '$machine_name' no existe en el sistema."
    fi
}

function listMachinesDifficulty(){
    difficulty="$1"
    machines=$(cat "$PROJECT_DIR/data/bundle.js" | \
        grep -i "dificultad: \"$difficulty\"" -B 5 | \
        grep "name:" | \
        awk 'NF{print $NF}' | \
        tr -d '"' | tr -d ',' | \
        sort | \
        xargs
    )

    if [[ -n "$machines" ]]; then
        count=$(echo "$machines" | wc -w)

        print_brillo "⚡ Listando máquinas con dificultad: ${_acento}$difficulty ${_texto}($count máquinas encontradas)"
        
        print_linea
       
        echo "$machines" | tr ' ' '\n' | column -c "$(tput cols)"
        
        print_linea
    else
        print_alerta "\n[✗] No se encontraron máquinas con la dificultad: '$difficulty'"
        print_texto "    (Dificultades válidas: Fácil, Media, Difícil, Insane)"
    fi
}

function listMachinesOS(){
    system="$1"
    machines=$(cat "$PROJECT_DIR/data/bundle.js" | \
         grep "so: \"$system\"" -B 5 | \
         grep name | awk 'NF{print $NF}' | \
         tr -d '"' | tr -d ',' | \
         sort | xargs
    )

    if [[ -n "$machines" ]]; then
        count=$(echo "$machines" | wc -w)

        print_brillo "⚡ Listando máquinas para el sistema operativo: ${_acento}$system ${_texto}($count máquinas encontradas)"
        
        print_linea
       
        echo "$machines" | tr ' ' '\n' | column -c "$(tput cols)"
        
        print_linea
    else
        print_alerta "\n[✗] No se encontraron máquinas para el sistema operativo: '$system'"
        print_texto "    (Sistemas Operativos válidos: Linux, Windows)"
    fi
}

function listMachinesOsAndDifficulty(){
    system=$1
    difficulty=$2

    machines=$(cat "$PROJECT_DIR/data/bundle.js" | \
        grep "so: \"$system\"" -B 5 -A 5 | \
        grep "dificultad: \"$difficulty\"" -B 5 -A 4 | \
        grep -vE "id:|sku:" | \
        grep "name: " | \
        awk 'NF{print $NF}'| \
        tr -d '"' | tr -d ',' | \
        sort)

    if [[ -n "$machines" ]]; then
        count=$(echo "$machines" | wc -w)

        # Usamos el rosa neón (_brillo) para la acción principal y violeta (_acento) para destacar las variables
        print_brillo "⚡ Listando máquinas para ${_acento}$system${_brillo} con dificultad ${_acento}$difficulty ${_texto}($count encontradas)"
        
        print_linea
        
        echo "$machines" | tr ' ' '\n' | column -c "$(tput cols)"
        
        print_linea
    else
        # El bloque de error en rojo carmesí (_alerta) con los parámetros destacados
        print_alerta "\n[✗] No se encontraron máquinas para S.O. '${_texto}$system${_alerta}' y dificultad '${_texto}$difficulty${_alerta}'"
        
        # Alineamos los consejos abajo con sangría limpia usando el gris por defecto (_texto)
        print_texto "\n    💡 Valores sugeridos:"
        print_texto "       • S.O.         : Linux, Windows"
        print_texto "       • Dificultad   : Fácil, Media, Difícil, Insane\n"
    fi
}

function listMachinesSkills(){
    skill="$1"
    machines=$(cat "$PROJECT_DIR/data/bundle.js" | \
        grep "so: \"Linux\"" -B 5 -A 5 | \
        grep -vE "id:|sku:" | \
        grep "skills: .*$skill" -B 4 -A 4 --no-group-separator | \
        grep "name: " | \
        awk 'NF{print $NF}' | \
        tr -d '"' | tr -d ','
    )

    if [[ -n "$machines" ]]; then
        count=$(echo "$machines" | wc -w)

        print_brillo "⚡ Listando máquinas para la skill: ${_acento}$skill ${_texto}($count máquinas encontradas)"
        
        print_linea
       
        echo "$machines" | tr ' ' '\n' | column -c "$(tput cols)"
        
        print_linea
    else
        print_alerta "\n[✗] No se encontraron máquinas para la skill: '$skill'"
    fi
}

function updateFile(){
    tput civis
    print_acento "\n[+] Sincronizando base de datos (bundle.js)..."
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
