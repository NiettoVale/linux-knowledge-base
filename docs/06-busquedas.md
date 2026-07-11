# Búsquedas en Linux: find, locate y xargs

## Introducción

Una de las tareas más recurrentes tanto en la administración de sistemas como en el reconocimiento local durante un ejercicio de pentesting es la búsqueda de archivos que cumplan determinadas condiciones: un nombre concreto, un propietario específico, un permiso inusual, un tamaño fuera de lo común, o una fecha de modificación reciente. Linux ofrece principalmente dos herramientas para esta tarea, `find` y `locate`, que si bien persiguen el mismo objetivo general, funcionan de manera radicalmente distinta por dentro, lo cual condiciona en qué escenario conviene usar cada una. A esto se suma `xargs`, una utilidad que, aunque no forma parte de la búsqueda en sí, resulta indispensable para poder actuar de forma eficiente sobre los resultados que `find` devuelve.

## find: búsqueda en tiempo real sobre el sistema de archivos

El comando `find` recorre en el momento de su ejecución, de forma recursiva, el árbol de directorios indicado, evaluando cada archivo y directorio que encuentra contra los criterios especificados. Esto lo convierte en una herramienta más lenta que su alternativa `locate` (especialmente al recorrer todo el sistema de archivos desde la raíz), pero con una ventaja decisiva: sus resultados siempre reflejan el estado real y actual del sistema, sin depender de ninguna base de datos previamente indexada que pueda estar desactualizada. Su sintaxis general sigue la estructura `find <directorio_de_inicio> <opciones> <criterio_de_búsqueda>`, donde el directorio de inicio puede ser `/` (todo el sistema), `.` (el directorio actual) o `~` (el directorio personal del usuario), entre otras rutas posibles.

### Búsqueda por nombre

El criterio más básico y frecuente de búsqueda es el nombre del archivo, mediante la opción `-name`. Es importante tener presente que esta búsqueda distingue entre mayúsculas y minúsculas por defecto; cuando esa distinción no interesa, existe la variante `-iname`, que ignora las mayúsculas.

```bash
# Busca ficheros llamados exactamente "passwd" en todo el sistema,
# descartando los mensajes de error de "Permiso denegado"
find / -name passwd 2>/dev/null

# Búsqueda insensible a mayúsculas/minúsculas
find / -iname PASSWD 2>/dev/null

# Uso de comodines: busca todo lo que empiece por "dex"
find / -name "dex*" 2>/dev/null

# Busca todos los archivos con extensión .txt a partir del directorio actual
find . -name "*.txt"

# Busca archivos que NO coincidan con un patrón, de dos formas equivalentes
find . -not -name "*.log"
find . \! -name "*.log"
```

### Búsqueda por tipo

La opción `-type` permite filtrar exclusivamente por la naturaleza del elemento encontrado, lo cual resulta esencial para evitar ruido innecesario en los resultados cuando solo interesa un tipo concreto de objeto. Los valores más habituales son `f` (archivo regular), `d` (directorio), `l` (enlace simbólico), `c` (dispositivo de caracteres) y `b` (dispositivo de bloque).

```bash
# Lista todos los directorios del sistema
find / -type d 2>/dev/null

# Busca únicamente archivos regulares llamados "passwd",
# descartando directorios o enlaces simbólicos con ese nombre
find / -type f -name passwd 2>/dev/null

# Busca directorios que pertenezcan a un grupo determinado
find / -type d -group <grupo> 2>/dev/null

# Busca ficheros (no directorios) que pertenezcan a un grupo determinado
find / -type f -group <grupo> 2>/dev/null
```

### Búsqueda por propietario y permisos

Estas opciones son de las más relevantes desde una perspectiva ofensiva, ya que permiten localizar rápidamente archivos propiedad de un usuario concreto (típicamente `root`) que además presenten alguna condición de permiso interesante para un posible abuso.

```bash
# Busca todos los archivos y directorios propiedad del usuario root
find / -user root 2>/dev/null

# Busca todos los archivos y directorios propiedad de un grupo concreto
find / -group classroom 2>/dev/null

# Busca ficheros con permiso EXACTO 644
find / -perm 644 2>/dev/null

# El guion antes del número indica "al menos estos permisos activados";
# devuelve archivos que tengan como mínimo el permiso 644, aunque tengan más
find / -perm -644 2>/dev/null

# Busca en todo el sistema ficheros con el permiso especial SUID activado.
# 4000 es el valor octal correspondiente al bit SUID
find / -perm 4000 2>/dev/null

# Forma más robusta de buscar SUID: -perm -4000 con el guion detecta
# el bit SUID esté o no acompañado de otros permisos adicionales,
# a diferencia de -perm 4000 que exige una coincidencia exacta
find / -perm -4000 2>/dev/null

# Combinación habitual en un checklist de privesc: SUID + tipo archivo
find / -perm -4000 -type f 2>/dev/null

# Búsqueda del bit SGID (valor octal 2000)
find / -perm -2000 -type f 2>/dev/null

# Búsqueda de archivos propiedad de root sobre los que el usuario
# actual tiene capacidad de escritura, aunque no sea su propietario
find / -user root -writable 2>/dev/null

# Búsqueda de archivos o directorios propiedad de root que sean
# ejecutables por el usuario actual
find / -user root -executable 2>/dev/null

# Igual que el anterior, pero filtrando únicamente ficheros (no directorios)
find / -user root -executable -type f 2>/dev/null

# Busca archivos que NO pertenecen a ningún usuario o grupo válido
# del sistema (archivos "huérfanos"), habitual tras eliminar una cuenta
find / -nouser -o -nogroup 2>/dev/null
```

### Búsqueda por tamaño

La opción `-size` permite filtrar archivos según su tamaño, empleando un sufijo que indica la unidad de medida: `b` para bloques de 512 bytes (valor por defecto si no se especifica ninguna letra), `c` para bytes exactos, `k` para kilobytes, `M` para megabytes y `G` para gigabytes.

```bash
# Busca archivos con un tamaño EXACTO de 10 megabytes
find / -size 10M 2>/dev/null

# El signo + indica "mayor que": archivos de más de 5 gigabytes
find / -size +5G 2>/dev/null

# El signo - indica "menor que": archivos de menos de 100 kilobytes
find / -size -100k 2>/dev/null

# Rango combinado: archivos de entre 1 y 10 megabytes
find / -size +1M -size -10M 2>/dev/null
```

### Búsqueda por fecha

Linux mantiene tres marcas de tiempo distintas por cada archivo, y `find` permite filtrar en función de cualquiera de ellas: `-atime` (tiempo de acceso, la última vez que el archivo fue leído), `-mtime` (tiempo de modificación, la última vez que cambió su contenido) y `-ctime` (tiempo de cambio, la última vez que cambiaron sus metadatos, como permisos o propietario, sin que necesariamente haya cambiado el contenido). Estas opciones se expresan en días, y también admiten los signos `+` y `-` con la misma lógica que en `-size`. Para mayor precisión existen además las variantes en minutos: `-amin`, `-mmin` y `-cmin`.

```bash
# Archivos accedidos exactamente hace 1 día
find / -atime 1 2>/dev/null

# Archivos modificados hace MÁS de 2 días
find / -mtime +2 2>/dev/null

# Archivos cuyos metadatos cambiaron hace MENOS de 1 día
find / -ctime -1 2>/dev/null

# Archivos modificados en el último minuto (útil para detectar
# manipulaciones recientes durante una investigación forense)
find / -mmin -1 2>/dev/null

# Archivos modificados más recientemente que un archivo de referencia,
# muy útil para detectar cambios posteriores a un evento conocido
find / -newer /var/log/auth.log 2>/dev/null
```

### Otras opciones útiles

```bash
# Busca archivos y directorios completamente vacíos
find / -empty 2>/dev/null

# Elimina directamente cada archivo encontrado que coincida
# con el criterio de búsqueda (usar con extrema precaución)
find . -name "*.tmp" -delete

# Limita la profundidad de la búsqueda: -maxdepth 1 busca solo
# en el directorio indicado, sin descender a subdirectorios
find /etc -maxdepth 1 -name "*.conf"

# -mindepth exige un nivel mínimo de profundidad antes de evaluar
find / -mindepth 2 -maxdepth 3 -name "*.log" 2>/dev/null

# Combina varios criterios con "y" lógico (comportamiento por defecto)
find / -type f -user root -perm -4000 2>/dev/null

# Combina criterios con "o" lógico explícito
find / \( -name "*.php" -o -name "*.jsp" \) 2>/dev/null
```

## -exec: ejecutar comandos directamente desde find

Más allá de listar resultados, `find` permite ejecutar un comando sobre cada elemento encontrado mediante la opción `-exec`, sin depender de herramientas externas. La sintaxis exige que la instrucción termine con `{}` (que se sustituye por la ruta de cada resultado) seguido de `\;` (que marca el final del comando a ejecutar, una vez por cada archivo encontrado) o de `+` (que agrupa todos los resultados en una única invocación del comando, de forma más eficiente).

```bash
# Ejecuta "ls -l" sobre cada archivo encontrado, uno por uno
find / -name passwd -exec ls -l {} \; 2>/dev/null

# Igual que el anterior, pero agrupando todos los resultados
# en una sola invocación de ls, mucho más eficiente
find / -name passwd -exec ls -l {} + 2>/dev/null

# Elimina cada archivo .bak encontrado, pidiendo confirmación
# individual gracias a la variante -ok en lugar de -exec
find . -name "*.bak" -ok rm {} \;
```

## xargs: paralelismo y construcción dinámica de comandos

`xargs` es una utilidad que toma la entrada estándar (típicamente una lista de líneas de texto, como las que produce `find`) y la convierte en argumentos para otro comando, invocándolo con ellos. A diferencia de `-exec` con `\;`, que lanza una nueva instancia del comando por cada resultado, `xargs` por defecto agrupa tantos argumentos como sea posible en una sola invocación (de forma similar a `-exec ... +`), lo cual reduce drásticamente el número de procesos lanzados cuando hay muchos resultados. Además, `xargs` permite paralelizar la ejecución de comandos mediante la opción `-P`, indicando cuántos procesos se desean ejecutar simultáneamente, algo que `find -exec` no ofrece de forma nativa.

```bash
# Aplica "ls -l" a cada línea que devuelve find, agrupando
# los resultados en la menor cantidad de invocaciones posible
find / -name passwd 2>/dev/null | xargs ls -l

# Salida de ejemplo
-rw-r--r-- 1 root root     92 abr 19  2025 /etc/pam.d/passwd
-rw-r--r-- 1 root root   2870 jul 11 10:09 /etc/passwd
-rwsr-xr-x 1 root root 118168 abr 19  2025 /usr/bin/passwd
-rw-r--r-- 1 root root    625 ene 26  2025 /usr/share/bash-completion/completions/passwd
-rw-r--r-- 1 root root    360 abr 19  2025 /usr/share/lintian/overrides/passwd

# Ejecuta el comando con 4 procesos en paralelo simultáneamente,
# acelerando notablemente tareas sobre listas largas de archivos
find / -name "*.log" 2>/dev/null | xargs -P 4 -I {} gzip {}

# -I {} define un marcador de posición explícito para insertar
# cada línea de entrada en cualquier punto del comando, no solo al final
find . -name "*.txt" | xargs -I {} mv {} {}.backup

# -0 en conjunto con "find ... -print0" es la forma segura de manejar
# nombres de archivo que contienen espacios o caracteres especiales,
# ya que separa los resultados por el carácter nulo en lugar de saltos de línea
find / -name "*.conf" -print0 2>/dev/null | xargs -0 ls -l
```

> **Nota de seguridad sobre `xargs`:** cuando los nombres de archivo pueden contener espacios, saltos de línea u otros caracteres especiales, usar `find ... | xargs comando` sin la combinación `-print0` / `-0` puede provocar que `xargs` interprete incorrectamente los nombres, partiéndolos en varios argumentos y ejecutando el comando sobre rutas que no existen o, en el peor de los casos, sobre rutas no intencionadas. Esta combinación es especialmente relevante en scripts de automatización que procesan directorios controlados por usuarios no confiables.

## locate: búsqueda instantánea mediante base de datos indexada

A diferencia de `find`, el comando `locate` no recorre el sistema de archivos en el momento de la búsqueda, sino que consulta una base de datos previamente generada (habitualmente `/var/lib/mlocate/mlocate.db`), la cual se actualiza de forma periódica mediante una tarea programada, o manualmente mediante el comando `updatedb`. Esto hace que `locate` sea considerablemente más rápido que `find` para búsquedas en todo el sistema, a cambio de una desventaja importante: si un archivo fue creado o eliminado después de la última actualización de la base de datos, `locate` no reflejará ese cambio, pudiendo mostrar archivos que ya no existen, u omitir archivos recién creados.

```bash
# Instalación del paquete que provee locate en distribuciones basadas en Debian
sudo apt install mlocate

# Actualiza manualmente la base de datos utilizada por locate
sudo updatedb

# Búsqueda básica: cualquier ruta que CONTENGA el término buscado
locate passwd

# Búsqueda por nombre exacto de archivo, usando -r (regex) y el
# símbolo $ para anclar el final de la ruta
locate -r passwd$

# Ignora la distinción entre mayúsculas y minúsculas
locate -i PASSWD

# Muestra únicamente la cantidad total de coincidencias, sin listarlas
locate -c passwd

# Muestra únicamente los archivos que existen realmente en este momento,
# descartando entradas obsoletas de la base de datos
locate -e passwd

# Suprime mensajes de error (por ejemplo, por falta de permisos de lectura)
locate -q passwd

# Limita el número de resultados devueltos
locate -n 10 passwd
```

> **Nota de seguridad sobre `locate`:** la base de datos de `mlocate` se genera habitualmente con privilegios de `root`, pero incorpora un mecanismo de control de acceso que respeta, en la mayoría de las distribuciones modernas, los permisos reales del sistema de archivos al mostrar resultados a un usuario sin privilegios (evitando así que `locate` filtre rutas que dicho usuario no podría ver de otra forma). Aun así, conviene no asumir ciegamente este comportamiento en todas las distribuciones o configuraciones, y verificar puntualmente si la base de datos ha sido generada con la utilidad correcta (`updatedb` respetando `PRUNE_BIND_MOUNTS` y las exclusiones configuradas en `/etc/updatedb.conf`).

## Implicaciones de seguridad y checklist de enumeración

Durante la fase de enumeración local de un ejercicio de pentesting o una auditoría de hardening, `find` se convierte en una de las herramientas más utilizadas, ya que buena parte de las técnicas clásicas de escalada de privilegios en Linux se detectan precisamente combinando las opciones descritas en este documento. Un flujo de enumeración típico suele incluir, como mínimo, la búsqueda de binarios con el bit SUID o SGID activado, la búsqueda de archivos y directorios propiedad de `root` sobre los que el usuario actual tiene permiso de escritura (lo cual puede permitir modificar un script ejecutado posteriormente con privilegios elevados, por ejemplo desde una tarea programada), y la búsqueda de archivos de configuración o credenciales con nombres característicos, como `id_rsa`, `.env`, `config.php` o `backup`.

```bash
# Checklist rápido de enumeración de privesc apoyado en find

# 1. Binarios con SUID activado
find / -perm -4000 -type f 2>/dev/null

# 2. Binarios con SGID activado
find / -perm -2000 -type f 2>/dev/null

# 3. Archivos propiedad de root escribibles por el usuario actual
#    (posible vector si un proceso de root los lee o ejecuta después)
find / -user root -writable 2>/dev/null

# 4. Directorios completos donde el usuario actual tiene escritura
find / -writable -type d 2>/dev/null

# 5. Claves privadas SSH potencialmente accesibles
find / -name "id_rsa" -o -name "*.pem" 2>/dev/null

# 6. Archivos de backup o configuración con posibles credenciales
find / \( -name "*.bak" -o -name "*.env" -o -name "config*.php" \) 2>/dev/null
```

Es importante remarcar que, en este tipo de enumeración, el uso sistemático de `2>/dev/null` no es meramente estético: al recorrer todo el sistema de archivos desde la raíz con un usuario sin privilegios, `find` generará inevitablemente una gran cantidad de errores de "Permiso denegado" al intentar descender a directorios restringidos (como los directorios personales de otros usuarios o ciertas rutas dentro de `/proc`), y descartar el error estándar permite que la salida quede limpia y legible, mostrando únicamente los resultados realmente encontrados.

## Tabla resumen: flags más útiles de find

| Flag                                 | Función                                                                                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `-name "patrón"`                     | Busca por nombre exacto o con comodines, distinguiendo mayúsculas.                                                                       |
| `-iname "patrón"`                    | Igual que `-name`, ignorando mayúsculas/minúsculas.                                                                                      |
| `-type f/d/l`                        | Filtra por tipo: archivo, directorio o enlace simbólico.                                                                                 |
| `-user usuario`                      | Filtra por propietario del archivo.                                                                                                      |
| `-group grupo`                       | Filtra por grupo propietario del archivo.                                                                                                |
| `-perm 4000` / `-perm -4000`         | Filtra por permisos exactos / al menos esos permisos (SUID = `4000`, SGID = `2000`, sticky = `1000`).                                    |
| `-writable`                          | Archivos/directorios sobre los que el usuario actual tiene permiso de escritura.                                                         |
| `-executable`                        | Archivos/directorios sobre los que el usuario actual tiene permiso de ejecución.                                                         |
| `-size +N[c\|k\|M\|G]`               | Filtra por tamaño (mayor, menor o exacto según el signo).                                                                                |
| `-mtime`/`-atime`/`-ctime ±N`        | Filtra por fecha de modificación, acceso o cambio de metadatos, en días.                                                                 |
| `-mmin`/`-amin`/`-cmin ±N`           | Igual que las anteriores, pero en minutos.                                                                                               |
| `-newer archivo`                     | Elementos modificados más recientemente que un archivo de referencia.                                                                    |
| `-empty`                             | Archivos y directorios vacíos.                                                                                                           |
| `-nouser` / `-nogroup`               | Archivos huérfanos, sin usuario o grupo válido asociado.                                                                                 |
| `-maxdepth N` / `-mindepth N`        | Limita la profundidad máxima/mínima de recursión.                                                                                        |
| `-delete`                            | Elimina cada resultado encontrado (usar con precaución).                                                                                 |
| `-exec cmd {} \;` / `-exec cmd {} +` | Ejecuta un comando sobre cada resultado, uno por uno o agrupados.                                                                        |
| `-print0`                            | Separa los resultados con carácter nulo, para uso seguro con `xargs -0`.                                                                 |
| `2>/dev/null`                        | No es una flag de `find`, pero es imprescindible para descartar errores de permiso denegado durante una enumeración de sistema completo. |

## Tabla resumen: flags más útiles de locate

| Flag           | Función                                                                 |
| -------------- | ----------------------------------------------------------------------- |
| `-r "patrón$"` | Búsqueda mediante expresión regular (útil para anclar nombres exactos). |
| `-i`           | Ignora mayúsculas/minúsculas.                                           |
| `-c`           | Devuelve solo el número de coincidencias, sin listarlas.                |
| `-e`           | Muestra únicamente archivos que existen realmente en este momento.      |
| `-q`           | Suprime mensajes de error durante la búsqueda.                          |
| `-n N`         | Limita el número de resultados devueltos.                               |

## Tabla resumen: flags más útiles de xargs

| Flag    | Función                                                                                            |
| ------- | -------------------------------------------------------------------------------------------------- |
| `-I {}` | Define un marcador de posición para insertar cada línea de entrada en cualquier punto del comando. |
| `-P N`  | Ejecuta hasta N procesos en paralelo simultáneamente.                                              |
| `-0`    | Interpreta la entrada separada por carácter nulo (usar junto a `find -print0`).                    |
| `-n N`  | Limita cuántos argumentos se pasan por cada invocación del comando.                                |
| `-p`    | Pide confirmación antes de ejecutar cada comando construido.                                       |
