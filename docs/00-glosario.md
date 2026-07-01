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

## Procesos: foreground y background

| Comando / concepto | Descripción                                                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `&`                | Envía un proceso a segundo plano (_background_), liberando la terminal.                                                            |
| `disown`           | Desvincula un proceso en background de la sesión de shell actual, para que sobreviva aunque se cierre la terminal.                 |
| Job number         | Identificador de trabajo asignado por el shell dentro de la sesión (se muestra entre corchetes al enviar un proceso a background). |
| PID                | _Process ID_, identificador único de un proceso a nivel de todo el sistema, asignado por el kernel.                                |

---

_Última actualización: comandos básicos, control de flujo y redirecciones en Bash._
