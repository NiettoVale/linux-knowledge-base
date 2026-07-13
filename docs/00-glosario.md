# Glosario de Comandos Linux

Este glosario reúne, organizados por categoría, todos los comandos, operadores y conceptos vistos hasta el momento. Sirve como referencia rápida de consulta; para el detalle teórico de cada tema conviene remitirse a los apuntes correspondientes.

## Identidad y privilegios

| Comando / concepto | Descripción                                                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `whoami`           | Muestra el nombre del usuario con el que se está ejecutando la sesión actual.                                                                          |
| `id`               | Muestra el UID, el GID del grupo primario y la lista completa de grupos secundarios a los que pertenece el usuario.                                    |
| `sudo`             | Ejecuta un comando con privilegios de `root`, siempre que el usuario esté autorizado en `/etc/sudoers` (habitualmente por pertenecer al grupo `sudo`). |
| `sudo su`          | Abre una sesión interactiva como `root`.                                                                                                               |
| `exit`             | Cierra la sesión actual del shell (por ejemplo, para salir de una sesión de `root` y volver al usuario original).                                      |
| Privilege token    | Marca temporal que guarda `sudo` tras una autenticación exitosa, para no pedir la contraseña en cada invocación durante un intervalo de tiempo.        |

## Ficheros de usuarios y grupos

| Comando / concepto | Descripción                                                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `/etc/passwd`      | Registro de todas las cuentas del sistema: UID, GID primario, comentario, directorio home y shell por defecto de cada usuario. |
| `/etc/group`       | Registro de todos los grupos del sistema: nombre, GID y miembros secundarios.                                                  |
| `/etc/shadow`      | Almacena los hashes de las contraseñas de los usuarios; solo accesible por `root`.                                             |

## Variables de entorno

| Comando / concepto | Descripción                                                                                                                                                                   |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$PATH`            | Lista de directorios, separados por `:`, en los que el shell busca binarios ejecutables cuando se invoca un comando sin ruta completa. La búsqueda es de izquierda a derecha. |
| `$HOME`            | Ruta absoluta del directorio personal del usuario actual.                                                                                                                     |
| `echo $VAR`        | Imprime por consola el valor de una variable de entorno.                                                                                                                      |

## Navegación y sistema de archivos

| Comando / concepto | Descripción                                                                            |
| ------------------ | -------------------------------------------------------------------------------------- |
| `pwd`              | Muestra la ruta absoluta del directorio de trabajo actual (_Print Working Directory_). |
| `cd`               | Cambia el directorio de trabajo actual.                                                |
| `ls`               | Lista el contenido de un directorio (_List directory_).                                |
| `ls -l`            | Formato detallado: permisos, propietario, grupo, tamaño y fecha.                       |
| `ls -a`            | Incluye archivos y directorios ocultos (los que empiezan con `.`).                     |
| `ls -h`            | Combinado con `-l`, muestra los tamaños en formato legible para humanos (KB, MB, GB).  |
| `.`                | Referencia al directorio actual, usada en rutas relativas.                             |
| `..`               | Referencia al directorio padre, usada en rutas relativas.                              |
| Ruta absoluta      | Ruta que parte siempre desde la raíz `/`, independiente del directorio actual.         |
| Ruta relativa      | Ruta definida en función del directorio de trabajo actual.                             |

## Lectura, búsqueda y filtrado

| Comando / concepto | Descripción                                                                       |
| ------------------ | --------------------------------------------------------------------------------- |
| `cat`              | Lee y muestra por consola el contenido de uno o varios archivos.                  |
| `grep`             | Filtra líneas de texto que coincidan con un patrón o expresión regular.           |
| `grep -n`          | Muestra también el número de línea de cada coincidencia.                          |
| `grep -E`          | Habilita expresiones regulares extendidas.                                        |
| `which`            | Muestra la ruta del binario (o el alias) que se ejecutaría al invocar un comando. |
| `command -v`       | Alternativa portable a `which`, disponible incluso en shells mínimos.             |

## Operadores lógicos y control de flujo

| Operador | Descripción                                                                                                                   |
| -------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `;`      | Concatena comandos: ejecuta uno después del otro, sin importar el resultado del primero.                                      |
| `&&`     | Ejecuta el segundo comando solo si el primero finalizó con éxito (`and` lógico).                                              |
| `\|\|`   | Ejecuta el segundo comando solo si el primero falló (`or` lógico).                                                            |
| `!`      | Operador de negación lógica en el shell.                                                                                      |
| `$?`     | Variable que almacena el código de salida (_exit code_) del último comando ejecutado: `0` es éxito, distinto de `0` es fallo. |

## Redirecciones básicas

| Redirección          | Descripción                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------------- |
| `cmd > file`         | Redirige stdout de `cmd` a un archivo, sobrescribiéndolo.                                       |
| `cmd >> file`        | Redirige stdout a un archivo, agregando al final (append).                                      |
| `cmd 2> file`        | Redirige stderr a un archivo.                                                                   |
| `cmd 2>> file`       | Redirige stderr a un archivo, en modo append.                                                   |
| `cmd &> file`        | Redirige stdout y stderr juntos a un archivo.                                                   |
| `cmd > file 2>&1`    | Forma alternativa de redirigir stdout y stderr al mismo archivo (el orden importa).             |
| `/dev/null`          | Dispositivo virtual que descarta cualquier dato escrito en él; se usa para "silenciar" salidas. |
| `cmd < file`         | Redirige el contenido de un archivo hacia la entrada estándar (stdin) de `cmd`.                 |
| Here-document (`<<`) | Redirige varias líneas de texto como stdin de un comando.                                       |
| Here-string (`<<<`)  | Redirige una única línea de texto como stdin de un comando.                                     |

## Descriptores de archivo y redirecciones avanzadas

| Comando / concepto       | Descripción                                                                               |
| ------------------------ | ----------------------------------------------------------------------------------------- |
| `exec 3< file`           | Abre el descriptor `3` en modo lectura sobre un archivo.                                  |
| `exec 3> file`           | Abre el descriptor `3` en modo escritura.                                                 |
| `exec 3<> file`          | Abre el descriptor `3` en modo lectura y escritura.                                       |
| `exec 3>&-`              | Cierra el descriptor `3`.                                                                 |
| `exec 4>&3`              | Copia el descriptor `3` al `4`.                                                           |
| `echo "x" >&3`           | Escribe a través de un descriptor personalizado.                                          |
| `cat <&3`                | Lee a través de un descriptor personalizado.                                              |
| `/dev/tcp/host/puerto`   | Ruta especial de bash para abrir una conexión TCP sin herramientas externas.              |
| `/dev/udp/host/puerto`   | Ruta especial de bash para abrir una conexión UDP sin herramientas externas.              |
| `(cmd1; cmd2) > file`    | Agrupa comandos en una subshell y redirige su salida conjunta.                            |
| `{ cmd1; cmd2; } > file` | Agrupa comandos en la shell actual (sin subshell) y redirige su salida conjunta.          |
| `<(cmd)`                 | Sustitución de procesos: expone la salida de `cmd` como si fuera un archivo.              |
| `cmd1 >(cmd2)`           | Sustitución de procesos en escritura: `cmd2` recibe como stdin lo que `cmd1` le envía.    |
| `tee`                    | Escribe la salida de un comando en un archivo y, simultáneamente, la muestra en pantalla. |
| `\|`                     | Pipe: redirige stdout de un comando como stdin del siguiente.                             |
| `\|&`                    | Redirige stdout y stderr de un comando como stdin del siguiente (bash 4.0+).              |

## Gestión de archivos y permisos

| Comando / concepto | Descripción                                                                                                      |
| ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `touch`            | Crea un archivo vacío, o actualiza su fecha de modificación si ya existe.                                        |
| `rm`               | Elimina un archivo.                                                                                              |
| `rm -r`            | Elimina un directorio y todo su contenido de forma recursiva.                                                    |
| `chmod`            | Modifica los permisos (lectura, escritura, ejecución) de un archivo o directorio, en notación simbólica u octal. |
| `chown`            | Cambia el propietario y/o el grupo propietario de un archivo o directorio (`chown usuario:grupo archivo`).       |
| `chgrp`            | Cambia únicamente el grupo propietario de un archivo o directorio.                                               |

## Usuarios y grupos (administración)

| Comando / concepto | Descripción                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| `useradd`          | Crea un nuevo usuario en el sistema. Con `-d` se define su directorio home y con `-s` su shell por defecto.              |
| `passwd`           | Asigna o cambia la contraseña de un usuario.                                                                             |
| `groupadd`         | Crea un nuevo grupo en el sistema.                                                                                       |
| `usermod`          | Modifica atributos de un usuario existente; con `-a -G grupo` lo agrega a un grupo secundario sin quitarlo de los demás. |
| User private group | Grupo creado automáticamente con el mismo nombre que el usuario al ejecutar `useradd`.                                   |

## Notación y permisos especiales

| Comando / concepto               | Descripción                                                                                                                                                                                                    |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Notación simbólica               | Representa los permisos con letras (`rwx`), agrupadas en tres bloques: propietario, grupo y otros.                                                                                                             |
| Notación octal                   | Representa los permisos con números del 0 al 7 por bloque, sumando `4` (lectura), `2` (escritura) y `1` (ejecución).                                                                                           |
| `chmod u+x`, `g-w`, `o+r`        | Sintaxis simbólica de `chmod`: `u`/`g`/`o` (categoría), `+`/`-` (agregar/quitar), `r`/`w`/`x` (permiso).                                                                                                       |
| SUID (`chmod u+s` / `4xxx`)      | El archivo se ejecuta con los privilegios de su propietario, sin importar quién lo invoque. Se muestra como `s`/`S` en el bloque del propietario.                                                              |
| SGID (`chmod g+s` / `2xxx`)      | El archivo se ejecuta con los privilegios de su grupo propietario; en directorios, los archivos creados heredan el grupo del directorio. Se muestra como `s`/`S` en el bloque del grupo.                       |
| Sticky bit (`chmod +t` / `1xxx`) | En un directorio, solo el propietario de cada archivo y `root` pueden borrarlo o renombrarlo, aunque otros tengan permiso de escritura. Se muestra como `t`/`T` en el bloque de otros. Ejemplo típico: `/tmp`. |

## Atributos de bajo nivel: chattr y lsattr

| Comando / concepto           | Descripción                                                                                                                                     |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `lsattr`                     | Lista los atributos de bajo nivel asignados a un archivo o directorio (a nivel de inodo).                                                       |
| `chattr`                     | Modifica los atributos de bajo nivel de un archivo o directorio.                                                                                |
| `chattr +i`                  | Atributo inmutable: impide modificar, renombrar, eliminar o enlazar el archivo, incluso para `root`.                                            |
| `chattr +a`                  | Atributo de solo-anexado: permite agregar contenido al final del archivo, pero no modificar ni eliminar lo existente.                           |
| `chattr +d`                  | Excluye el archivo de las copias de seguridad realizadas con `dump`.                                                                            |
| `chattr +u`                  | Intenta preservar el contenido de un archivo eliminado para una posible recuperación posterior (soporte limitado).                              |
| `chattr +j`                  | Fuerza que los cambios se registren primero en el journal antes de escribirse en el archivo (ext3/ext4).                                        |
| `chattr +S`                  | Fuerza escritura síncrona a disco de cada cambio, priorizando integridad sobre rendimiento.                                                     |
| `e`, `E`, `I` (solo lectura) | Atributos gestionados automáticamente por el kernel/filesystem (extents, cifrado, indexado htree); visibles con `lsattr` pero no configurables. |

## Linux Capabilities

| Comando / concepto          | Descripción                                                                                                                                                                       |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Capability                  | Privilegio específico del kernel, extraído del conjunto monolítico de `root`, que puede asignarse de forma independiente a un proceso o binario (principio de mínimo privilegio). |
| `getcap`                    | Consulta las capabilities asignadas a un binario (`getcap archivo`) o, recursivamente, a todo un árbol de directorios (`getcap -r /`).                                            |
| `setcap`                    | Asigna o retira capabilities sobre un binario (`setcap cap_net_raw+ep archivo`; `setcap -r archivo` para quitarlas todas).                                                        |
| `capsh`                     | Inspecciona (`--print`) o decodifica (`--decode=valor`) las capabilities del shell/proceso actual.                                                                                |
| Permitted (P)               | Techo de capabilities que un proceso puede llegar a activar en su conjunto Effective.                                                                                             |
| Effective (E)               | Capabilities que el kernel evalúa activamente para autorizar o denegar una operación en este momento.                                                                             |
| Inheritable (I)             | Capabilities que un proceso puede transmitir a los programas que ejecute vía `exec()`.                                                                                            |
| Bounding                    | Techo global: ninguna capability puede añadirse a P/E/I si no está en este conjunto.                                                                                              |
| Ambient                     | Permite que ciertas capabilities sobrevivan a un `exec()` hacia un binario sin `setcap` propio (usado por `systemd`).                                                             |
| `cap_setuid` / `cap_setgid` | Permiten invocar `setuid()`/`setgid()` y cambiar el UID/GID efectivo del proceso a voluntad (incluido `root`).                                                                    |
| `cap_dac_override`          | Permite saltarse los permisos de lectura/escritura/ejecución de cualquier archivo del sistema.                                                                                    |
| `cap_dac_read_search`       | Permite saltarse los permisos de lectura y de búsqueda en directorios sobre cualquier archivo.                                                                                    |
| `cap_chown` / `cap_fowner`  | Permiten cambiar el propietario o los permisos de cualquier archivo del sistema.                                                                                                  |
| `cap_sys_ptrace`            | Permite usar `ptrace()` sobre cualquier proceso, incluyendo inspeccionar/modificar procesos de `root`.                                                                            |
| `cap_sys_admin`             | Capability muy amplia y poco granular ("la nueva root"); incluye montar sistemas de archivos arbitrarios, entre muchas otras operaciones administrativas.                         |
| `cap_sys_module`            | Permite cargar/descargar módulos del kernel (`insmod`/`rmmod`); equivale a ejecución de código en anillo 0.                                                                       |
| `cap_net_bind_service`      | Permite vincularse a puertos por debajo del 1024 sin ser `root`; uso legítimo habitual en servidores web.                                                                         |
| `cap_setfcap`               | Permite asignar capabilities a otros archivos mediante `setcap`, pudiendo autoconcederse privilegios adicionales.                                                                 |
| GTFOBins                    | Catálogo curado de binarios Unix legítimos abusables bajo SUID, `sudo` o capabilities (gtfobins.github.io).                                                                       |

## Sistema de directorios (FHS)

| Directorio    | Descripción                                                                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `/`           | Directorio raíz; punto de partida de todo el árbol de archivos del sistema.                                                           |
| `/bin`        | Binarios esenciales disponibles para todos los usuarios (`ls`, `cat`, `bash`); en sistemas modernos suele ser un enlace a `/usr/bin`. |
| `/boot`       | Archivos necesarios para el arranque: kernel, initramfs y gestor de arranque (GRUB).                                                  |
| `/dev`        | Representación de los dispositivos de hardware como archivos (`/dev/sda`, `/dev/null`, `/dev/tcp/...`).                               |
| `/etc`        | Archivos de configuración del sistema y de los programas instalados (`passwd`, `sudoers`, `ssh`, `crontab`).                          |
| `/home`       | Directorios personales de los usuarios (excepto `root`).                                                                              |
| `/lib`        | Bibliotecas compartidas (`.so`) necesarias para los binarios de `/bin` y `/sbin`.                                                     |
| `/mnt`        | Punto de montaje manual y temporal para dispositivos de almacenamiento.                                                               |
| `/media`      | Punto de montaje automático para medios extraíbles (USB, CD-ROM).                                                                     |
| `/opt`        | Software opcional de terceros, fuera del gestor de paquetes de la distribución.                                                       |
| `/proc`       | Sistema de archivos virtual con información en tiempo real de procesos y del kernel (`/proc/<pid>/status`, `/proc/cpuinfo`).          |
| `/root`       | Directorio personal del usuario `root`.                                                                                               |
| `/sbin`       | Binarios de administración, pensados para ejecutarse con privilegios de `root`.                                                       |
| `/srv`        | Datos servidos por servicios de servidor instalados en la máquina.                                                                    |
| `/tmp`        | Archivos temporales, con escritura abierta a todos los usuarios y protegido por sticky bit.                                           |
| `/usr`        | Grueso del software instalado en el sistema; contenido de solo lectura y compartible.                                                 |
| `/var`        | Datos variables: logs (`/var/log`), colas de trabajos, cachés de paquetes.                                                            |
| `/sys`        | Sistema de archivos virtual con la vista jerárquica del kernel, dispositivos y drivers.                                               |
| `/lost+found` | Directorio generado por `fsck` en filesystems ext, donde se depositan fragmentos recuperados tras una corrupción.                     |

## Búsquedas: find, locate y xargs

| Comando / concepto                        | Descripción                                                                                                                   |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `find <dir> <opciones>`                   | Recorre en tiempo real el árbol de directorios indicado, evaluando cada elemento contra los criterios dados.                  |
| `-name` / `-iname`                        | Busca por nombre (distinguiendo o ignorando mayúsculas/minúsculas), admite comodines (`*`).                                   |
| `-type f/d/l`                             | Filtra por tipo: archivo, directorio o enlace simbólico.                                                                      |
| `-user` / `-group`                        | Filtra por propietario o grupo propietario del archivo.                                                                       |
| `-perm 4000` / `-perm -4000`              | Permiso exacto vs. "al menos" ese permiso; base para localizar SUID (`4000`), SGID (`2000`) y sticky bit (`1000`).            |
| `-writable` / `-executable`               | Archivos/directorios sobre los que el usuario actual tiene permiso de escritura/ejecución.                                    |
| `-size +N[c\|k\|M\|G]`                    | Filtra por tamaño de archivo.                                                                                                 |
| `-mtime` / `-atime` / `-ctime ±N`         | Filtra por fecha de modificación, acceso o cambio de metadatos, en días (`-mmin`/`-amin`/`-cmin` en minutos).                 |
| `-newer archivo`                          | Elementos modificados más recientemente que un archivo de referencia.                                                         |
| `-empty`                                  | Archivos y directorios vacíos.                                                                                                |
| `-nouser` / `-nogroup`                    | Archivos huérfanos sin usuario o grupo válido asociado.                                                                       |
| `-maxdepth` / `-mindepth`                 | Limita la profundidad máxima/mínima de recursión.                                                                             |
| `-delete`                                 | Elimina cada resultado encontrado.                                                                                            |
| `-exec cmd {} \;` / `-exec cmd {} +`      | Ejecuta un comando sobre cada resultado, uno por uno o agrupados.                                                             |
| `-print0`                                 | Separa resultados con carácter nulo, para uso seguro con `xargs -0`.                                                          |
| `2>/dev/null`                             | Descarta errores de "Permiso denegado" al recorrer todo el sistema.                                                           |
| `locate`                                  | Búsqueda instantánea contra una base de datos indexada (`mlocate.db`), más rápida que `find` pero puede estar desactualizada. |
| `updatedb`                                | Actualiza manualmente la base de datos usada por `locate`.                                                                    |
| `locate -r "patrón$"`                     | Búsqueda por expresión regular, útil para anclar el nombre exacto de archivo.                                                 |
| `locate -i` / `-c` / `-e` / `-q` / `-n N` | Ignora mayúsculas / cuenta resultados / solo existentes / sin errores / limita cantidad.                                      |
| `xargs`                                   | Convierte la entrada estándar en argumentos de otro comando, agrupándolos para minimizar invocaciones.                        |
| `xargs -I {}`                             | Marcador de posición para insertar cada línea de entrada en cualquier punto del comando.                                      |
| `xargs -P N`                              | Ejecuta hasta N procesos en paralelo.                                                                                         |
| `xargs -0`                                | Interpreta entrada separada por carácter nulo (usar junto a `find -print0`).                                                  |

## SSH

| Comando / concepto                           | Descripción                                                                                                       |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `ssh usuario@host`                           | Conecta a un servidor SSH; con `-p` se indica un puerto distinto al 22 por defecto.                               |
| `ssh -v`                                     | Salida detallada (verbose), útil para depurar problemas de conexión.                                              |
| `ssh usuario@host "cmd"`                     | Ejecuta un único comando remoto sin abrir sesión interactiva.                                                     |
| `ssh-keygen -t ed25519 / rsa -b 4096`        | Genera un par de claves asimétricas (Ed25519 recomendado; RSA por compatibilidad).                                |
| `ssh-copy-id`                                | Copia la clave pública propia al `authorized_keys` de un servidor remoto.                                         |
| `~/.ssh/authorized_keys`                     | Archivo del servidor con las claves públicas autorizadas a acceder a esa cuenta.                                  |
| `~/.ssh/known_hosts`                         | Registro de claves públicas de servidores a los que el cliente ya se conectó.                                     |
| `ssh-agent` / `ssh-add`                      | Mantiene claves privadas descifradas en memoria durante la sesión, evitando reingresar la passphrase.             |
| `~/.ssh/config`                              | Define alias y parámetros por defecto (host, usuario, puerto, clave) para conexiones frecuentes.                  |
| `scp`                                        | Copia archivos entre cliente y servidor de forma directa (`-r` para directorios).                                 |
| `sftp`                                       | Sesión interactiva de transferencia de archivos sobre SSH (`get`, `put`, `ls`).                                   |
| `ssh -L puerto_local:destino:puerto_destino` | Reenvío de puerto local: accede desde la máquina local a un servicio solo visible desde el servidor remoto.       |
| `ssh -R puerto_remoto:destino:puerto_local`  | Reenvío de puerto remoto: expone un servicio local hacia el servidor remoto.                                      |
| `ssh -D puerto`                              | Reenvío dinámico: convierte la conexión SSH en un proxy SOCKS.                                                    |
| `ssh -A`                                     | Agent forwarding: reenvía el agente local al servidor remoto (riesgo si el servidor no es de confianza).          |
| `ssh -J bastion destino` / `ProxyJump`       | Atraviesa un servidor intermedio sin exponer el agente, alternativa más segura a `-A`.                            |
| `/etc/ssh/sshd_config`                       | Configuración del servidor SSH (`PermitRootLogin`, `PasswordAuthentication`, `AllowUsers`, `MaxAuthTries`, etc.). |
| `fail2ban`                                   | Herramienta que bloquea IPs con demasiados intentos fallidos de login, mitigando fuerza bruta.                    |

## Manejo avanzado de ficheros

| Comando / concepto          | Descripción                                                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `cat ./-` / `cat $(pwd)/-`  | Formas de leer un archivo cuyo nombre empieza con `-`, evitando que se interprete como flag.                                |
| `cmd -- archivo`            | Marcador `--`: indica fin de opciones, todo lo posterior se trata como argumento posicional.                                |
| `cat "nombre con espacios"` | Comillas dobles para tratar un nombre con espacios como un único argumento.                                                 |
| `cat nombre\ con\ espacios` | Escapado manual de cada espacio con `\`.                                                                                    |
| `cat s*`                    | Expansión de comodines para evitar escribir un nombre completo con espacios.                                                |
| `file archivo`              | Identifica el tipo real de un archivo según su contenido (firma/magic number), no según su extensión.                       |
| `grep -v`                   | Invierte la coincidencia: muestra las líneas que NO matchean el patrón.                                                     |
| `awk '{print $N}'`          | Imprime el campo N de cada línea; `$NF` referencia siempre al último campo.                                                 |
| `awk ... FS=":"`            | Define el separador de campos (_Field Separator_) que usará awk.                                                            |
| `cut -d ':' -f 2`           | Corta cada línea por un delimitador y extrae el campo indicado.                                                             |
| `tr 'a' 'b'`                | Traduce/sustituye caracteres de un conjunto de origen a un conjunto de destino.                                             |
| `sort \| uniq -u`           | `uniq` solo detecta duplicados consecutivos, por eso requiere `sort` previo; `-u` muestra líneas sin duplicados.            |
| `uniq -d` / `uniq -c`       | Muestra solo las líneas duplicadas / antepone el conteo de repeticiones.                                                    |
| `strings archivo`           | Extrae las cadenas de texto legibles dentro de un archivo binario.                                                          |
| `xxd archivo`               | Vuelca el contenido de un archivo en hexadecimal, útil para inspeccionar firmas de archivo.                                 |
| `base64`                    | Codifica datos binarios a texto ASCII imprimible (no es cifrado, es reversible sin clave).                                  |
| `base64 -d`                 | Decodifica una cadena en Base64 a su forma original.                                                                        |
| `base64 -w 0`               | Genera la codificación en una única línea, sin salto de línea cada 76 caracteres.                                           |
| Cifrado César / ROT13       | Desplaza cada letra del alfabeto N posiciones; ROT13 (`tr 'A-Za-z' 'N-ZA-Mn-za-m'`) es el caso con N=13, su propio inverso. |

## SSH

| Comando / concepto                          | Descripción                                                                                                                                                          |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ssh usuario@host`                          | Conecta a un servidor SSH; `-p` indica puerto distinto al 22, `-v` activa salida detallada.                                                                          |
| `ssh usuario@host "cmd"`                    | Ejecuta un único comando remoto sin abrir sesión interactiva.                                                                                                        |
| Criptografía asimétrica                     | Par de claves matemáticamente relacionadas: lo cifrado/firmado con una solo se verifica/descifra con la otra.                                                        |
| `ssh-keygen -t ed25519 / rsa -b 4096`       | Genera el par de claves (privada + `.pub`); Ed25519 recomendado sobre RSA.                                                                                           |
| `id_rsa` / `id_ed25519`                     | Clave **privada**: nunca se comparte, permisos `600`.                                                                                                                |
| `id_rsa.pub` / `id_ed25519.pub`             | Clave **pública**: se distribuye libremente, se instala en el servidor.                                                                                              |
| `~/.ssh/authorized_keys`                    | Lista de claves públicas autorizadas a entrar como esa cuenta (permisos `600`, directorio `700`).                                                                    |
| `~/.ssh/known_hosts`                        | Claves públicas de servidores a los que el cliente ya se conectó.                                                                                                    |
| `ssh-copy-id -i clave.pub usuario@host`     | Lo ejecuta el **cliente** desde su máquina; instala su clave pública en el `authorized_keys` remoto.                                                                 |
| Autenticación por firma (desafío-respuesta) | El servidor envía un desafío aleatorio; el cliente lo firma con su clave privada; el servidor verifica la firma con la pública. No es "cifrar/descifrar un mensaje". |
| Passphrase                                  | Cifra la clave privada en disco local; no viaja al servidor, solo protege el archivo ante robo.                                                                      |
| `ssh-agent` / `ssh-add`                     | Mantiene claves privadas descifradas en memoria durante la sesión, evitando reingresar la passphrase.                                                                |
| `~/.ssh/config`                             | Alias y parámetros por defecto (`Host`, `HostName`, `User`, `Port`, `IdentityFile`) para conexiones frecuentes.                                                      |
| `scp` / `sftp`                              | Copia directa de archivos (`-r` recursivo) / sesión interactiva de transferencia (`get`, `put`, `ls`).                                                               |
| `ssh -L` / `-R` / `-D`                      | Reenvío de puerto local / remoto / dinámico (proxy SOCKS) — base del pivoting por SSH.                                                                               |
| `ssh -A`                                    | Agent forwarding: reenvía el agente local al servidor remoto (riesgo si el servidor no es confiable).                                                                |
| `ssh -J bastion destino` / `ProxyJump`      | Atraviesa un servidor intermedio sin exponer el agente; alternativa más segura a `-A`.                                                                               |
| `/etc/ssh/sshd_config`                      | Configuración del servidor: `PermitRootLogin`, `PasswordAuthentication`, `AllowUsers`, `MaxAuthTries`, etc.                                                          |
| `fail2ban`                                  | Bloquea IPs con demasiados intentos fallidos de login, mitigando fuerza bruta.                                                                                       |
| `ssh usuario@host "bash"`                   | Recupera una shell funcional cuando la sesión de login normal se cierra por un `.bashrc`/`.profile` modificado.                                                      |

## Manejo avanzado de ficheros

| Comando / concepto                 | Descripción                                                                                                            |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `cat ./-` / `cat $(pwd)/-`         | Leer un archivo cuyo nombre empieza con `-`, evitando que se interprete como flag.                                     |
| `cmd -- archivo`                   | Marcador `--`: fin de opciones, todo lo posterior se trata como argumento posicional.                                  |
| `cat "nombre con espacios"` / `\ ` | Comillas dobles o escapado manual de espacios en nombres de archivo.                                                   |
| `file archivo`                     | Identifica el tipo real de un archivo por su firma/magic number, no por su extensión.                                  |
| `grep -v`                          | Invierte la coincidencia: muestra líneas que NO matchean el patrón.                                                    |
| `awk '{print $N}'` / `$NF`         | Imprime el campo N; `$NF` referencia siempre al último campo de la línea.                                              |
| `cut -d ':' -f 2`                  | Corta cada línea por un delimitador y extrae el campo indicado.                                                        |
| `tr 'a' 'b'`                       | Traduce/sustituye caracteres de un conjunto de origen a uno de destino.                                                |
| `sort \| uniq -u`                  | `uniq` solo detecta duplicados consecutivos; `-u` muestra líneas sin duplicados, `-d` las duplicadas, `-c` las cuenta. |
| `strings archivo`                  | Extrae cadenas de texto legibles de un binario.                                                                        |
| `xxd` / `hexdump -C` / `od`        | Vuelcan el contenido de un archivo en hexadecimal (offset + bytes + ASCII).                                            |
| Magic number / file signature      | Bytes iniciales característicos de cada formato (`FF D8 FF`=JPEG, `50 4B 03 04`=ZIP, `7F 45 4C 46`=ELF).               |
| `base64` / `base64 -d`             | Codifica/decodifica a Base64 (no es cifrado, reversible sin clave).                                                    |
| `base64 -w 0`                      | Codifica en una única línea, sin salto cada 76 caracteres.                                                             |
| Cifrado César / ROT13              | Desplaza cada letra N posiciones; ROT13 (`tr 'A-Za-z' 'N-ZA-Mn-za-m'`) es el caso N=13, su propio inverso.             |

## sponge, descompresión recursiva y diff

| Comando / concepto                | Descripción                                                                                                                                                      |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sponge` (moreutils)              | Absorbe toda la entrada en memoria antes de escribir; permite leer y sobrescribir el mismo archivo en un pipeline sin vaciarlo (`cat f \| awk ... \| sponge f`). |
| Condición de carrera en `>`/`tee` | `cmd f > f` o `cmd f \| tee f` vacían el archivo antes/durante la lectura, por eso truncan el contenido.                                                         |
| `7z l` / `7z x`                   | Lista (`l`) o extrae (`x`) el contenido de un archivo comprimido con 7-Zip.                                                                                      |
| `while [ $var ]; do ...; done`    | Bucle que se repite mientras la variable no esté vacía; base de la descompresión recursiva automática.                                                           |
| `trap ctrl_c INT`                 | Captura la señal `Ctrl+C` (`INT`) para finalizar un script de forma controlada.                                                                                  |
| `diff archivo1 archivo2`          | Compara dos archivos línea por línea, mostrando qué difiere entre ambos.                                                                                         |
| `diff -u`                         | Formato unificado, el más legible (el mismo que usa Git).                                                                                                        |
| `diff -r dir1/ dir2/`             | Compara recursivamente el contenido de dos directorios.                                                                                                          |

## Netcat

| Comando / concepto                                       | Descripción                                                                                                                       |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `nc -lvnp <puerto>`                                      | Modo servidor/escucha: `l` listen, `v` verbose, `n` sin resolución DNS, `p` puerto.                                               |
| `nc host puerto`                                         | Modo cliente: inicia conexión hacia un host y puerto remotos.                                                                     |
| `nc -zv host rango`                                      | Escaneo básico de puertos TCP (`-z` no envía datos, solo comprueba conexión).                                                     |
| `nc -lvnp puerto > archivo` / `nc host puerto < archivo` | Transferencia de archivos entre dos máquinas sin servidor dedicado.                                                               |
| Banner grabbing                                          | Conectarse a un puerto para leer el mensaje de bienvenida y detectar software/versión.                                            |
| Bind shell                                               | La víctima escucha y vincula un puerto a una shell (`nc -lvnp puerto -e /bin/bash`); requiere alcanzar directamente a la víctima. |
| Reverse shell                                            | El atacante escucha; la víctima inicia la conexión saliente y entrega la shell; sortea mejor los firewalls.                       |
| `nc -k`                                                  | Mantiene el servidor escuchando tras desconectarse un cliente (keep listening).                                                   |
| `nc -w N`                                                | Cierra la conexión tras N segundos de inactividad.                                                                                |
| `nc -4` / `-6`                                           | Fuerza el uso de IPv4 o IPv6.                                                                                                     |
| `nc -u`                                                  | Usa UDP en lugar de TCP.                                                                                                          |
| `nc -q N`                                                | Espera N segundos tras un EOF antes de cerrar la conexión.                                                                        |

## Puertos, procesos de red y explotación de SUID

| Comando / concepto               | Descripción                                                                                                                          |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `ss -nltp`                       | Lista sockets en escucha (`l`), TCP (`t`), sin resolver DNS (`n`), con el proceso propietario (`p`); sustituto moderno de `netstat`. |
| `netstat -s`                     | Estadísticas de red por protocolo.                                                                                                   |
| `/proc/net/tcp`                  | Tabla virtual del kernel con las conexiones TCP activas; puertos en formato `IP_hex:PUERTO_hex`.                                     |
| `bc` con `ibase`/`obase`         | Calculadora de línea de comandos; permite convertir entre bases numéricas (ej. hex → decimal).                                       |
| `lsof -i:<puerto>`               | Identifica qué proceso (PID, usuario, comando) tiene abierto un puerto determinado.                                                  |
| `lsof -i -sTCP:LISTEN`           | Lista todos los sockets del sistema en estado de escucha.                                                                            |
| GTFOBins                         | Catálogo de binarios abusables bajo SUID/sudo/capabilities para escalar privilegios.                                                 |
| `find / -perm -4000 -type f`     | Localiza binarios con SUID activado (repaso: base de la enumeración de privesc).                                                     |
| `find ... -exec /bin/bash -p \;` | Ejemplo de abuso de un binario SUID para obtener shell con privilegios heredados (`-p` conserva el UID efectivo).                    |

## Procesos: foreground y background

| Comando / concepto | Descripción                                                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `&`                | Envía un proceso a segundo plano (_background_), liberando la terminal.                                                            |
| `disown`           | Desvincula un proceso en background de la sesión de shell actual, para que sobreviva aunque se cierre la terminal.                 |
| Job number         | Identificador de trabajo asignado por el shell dentro de la sesión (se muestra entre corchetes al enviar un proceso a background). |
| PID                | _Process ID_, identificador único de un proceso a nivel de todo el sistema, asignado por el kernel.                                |

---
