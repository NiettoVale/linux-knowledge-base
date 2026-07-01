# Control de Flujo y Redirecciones en Bash

## Operadores lógicos en la terminal

De manera análoga a como ocurre en los lenguajes de programación, la terminal permite controlar el flujo de ejecución de los comandos mediante operadores lógicos equivalentes a los conocidos `and`, `or` y `not`, aunque en el contexto del shell se representan mediante símbolos particulares en lugar de palabras reservadas. El operador `&&` cumple la función de un `and` lógico: al encadenar dos comandos mediante `&&`, el segundo comando únicamente se ejecutará si el primero finalizó exitosamente. El operador `||` cumple la función de un `or` lógico: el segundo comando se ejecutará únicamente si el primero falló. El símbolo `!` se utiliza como operador de negación en distintos contextos del shell, invirtiendo el resultado lógico de una expresión o condición. Adicionalmente, el punto y coma (`;`) permite concatenar múltiples comandos dentro de una misma línea, ejecutándolos de forma secuencial e incondicional, es decir, sin que el resultado de un comando afecte la ejecución del siguiente.

Esta capacidad de encadenar comandos mediante operadores lógicos resulta especialmente útil para construir los denominados _one-liners_, expresiones compactas que combinan varios comandos en una sola línea con el fin de automatizar tareas o construir cadenas de explotación sin necesidad de escribir un script completo. Comprender cómo se determina el éxito o el fracaso de un comando resulta indispensable para entender el comportamiento de estos operadores: cada comando ejecutado en el shell devuelve, al finalizar, un código de estado numérico conocido como _exit code_ o _exit status_, el cual queda almacenado en la variable especial `$?` y puede consultarse inmediatamente después de la ejecución. Por convención, un código de estado igual a `0` indica que el comando finalizó correctamente, mientras que cualquier valor distinto de `0` (generalmente entre `1` y `255`) indica algún tipo de fallo, cuyo significado específico depende de cada programa.

```bash
# Ejecuta whoami y, sin importar el resultado, ejecuta ls a continuación
whoami ; ls

# Ejecuta whoami; solo si finaliza con éxito (exit code 0) ejecuta ls
whoami && ls

# Muestra el código de salida del último comando ejecutado
echo $?

# Ejecuta whoami; si falla (exit code distinto de 0), ejecuta ls como alternativa
whoami || ls
```

Esta lógica condicional resulta particularmente relevante en el contexto de la explotación de vulnerabilidades, ya que numerosas técnicas de inyección de comandos (_command injection_) se apoyan precisamente en operadores como `&&`, `||` o `;` para lograr que el sistema vulnerable ejecute un comando adicional no previsto por la aplicación, aprovechando que el shell interpretará la cadena completa como una secuencia de comandos encadenados.

## Redirecciones de entrada y salida

Todo proceso que se ejecuta en un sistema Unix o Linux cuenta, por defecto, con tres flujos de datos estándar identificados internamente mediante números conocidos como descriptores de archivo (_file descriptors_): el descriptor `0` corresponde a la entrada estándar (_stdin_), por donde el proceso recibe datos de entrada; el descriptor `1` corresponde a la salida estándar (_stdout_), por donde el proceso emite su salida normal; y el descriptor `2` corresponde al error estándar (_stderr_), por donde el proceso emite mensajes de error, separados deliberadamente de la salida normal para que puedan tratarse de forma independiente. Las redirecciones son un mecanismo propio del shell que permite alterar el destino u origen de estos flujos, enviándolos hacia archivos, hacia otros procesos, o descartándolos por completo, en lugar de dejar que sigan su comportamiento por defecto (mostrarse en la terminal o leerse desde el teclado).

El operador `>` redirige la salida estándar de un comando hacia un archivo, sobrescribiendo su contenido si ya existía, mientras que `>>` realiza la misma operación pero añadiendo el contenido al final del archivo en lugar de sobrescribirlo. Dado que `1` es el descriptor por defecto para la salida estándar, escribir `cmd > file` es completamente equivalente a escribir `cmd 1> file`, aunque en la práctica casi nunca se especifica el número explícitamente para la salida estándar por tratarse del comportamiento por defecto. Para redirigir específicamente el error estándar se antepone el número `2` al operador, de la siguiente manera:

```bash
❯ whoam
zsh: command not found: whoam

# Redirige el error estándar (fd 2) a /dev/null, descartándolo
# y evitando que se muestre en la terminal
❯ whoam 2> /dev/null
```

El dispositivo especial `/dev/null` merece una mención particular, ya que se trata de un archivo virtual provisto por el propio kernel que descarta silenciosamente cualquier dato que se escriba en él, sin generar ningún error ni ocupar espacio de almacenamiento. Redirigir un flujo hacia `/dev/null` es, en la práctica, la forma estándar de descartar información que no resulta de interés, ya sea la salida estándar (`> /dev/null`), el error estándar (`2> /dev/null`), o ambos flujos simultáneamente combinando ambas redirecciones o utilizando el operador abreviado `&>`, que redirige tanto stdout como stderr hacia el mismo destino en una sola expresión.

Existe también una forma alternativa de redirigir ambos flujos hacia un mismo archivo, expresada como `cmd > file 2>&1`. Esta construcción primero redirige la salida estándar hacia el archivo indicado, y luego, mediante `2>&1`, indica que el descriptor `2` (stderr) debe apuntar hacia el mismo destino al que actualmente apunta el descriptor `1` (stdout), que en ese punto ya es el archivo. Resulta fundamental comprender que el orden de las redirecciones altera el resultado: la expresión `cmd 2>&1 > file` no produce el mismo efecto, ya que en ese caso `2>&1` se ejecuta primero, cuando el descriptor `1` todavía apunta a la terminal, por lo que stderr terminaría redirigido hacia la pantalla y no hacia el archivo. Por este motivo, cuando se desea combinar ambos flujos en un único archivo, suele preferirse la forma abreviada y menos propensa a errores `&> file`.

```bash
# Muestra un mensaje de error por stderr al no tener permisos suficientes
❯ wireshark
 ** (wireshark:47336) 05:31:31.731354 [Capture WARNING] ./ui/capture.c:1019 -- capture_interface_stat_start(): Couldn't run dumpcap in child process: Permiso denegado

# Redirige tanto stdout como stderr hacia /dev/null,
# descartando por completo cualquier salida del programa
❯ wireshark &>/dev/null
```

Redirigir la salida de un comando resulta especialmente útil cuando se automatizan tareas mediante scripts que invocan herramientas externas, y no se desea que la salida de dichas herramientas "ensucie" la salida propia del script, o cuando simplemente se quiere ejecutar un programa en silencio, sin que sus mensajes informativos o de error interrumpan visualmente el trabajo en la terminal.

Además de redirigir la salida, es posible redirigir la entrada estándar de un comando para que, en lugar de esperar datos escritos por teclado, los lea directamente desde un archivo mediante el operador `<`. Existen también dos variantes especiales de redirección de entrada: el _here-document_, introducido mediante `<<` seguido de una palabra delimitadora, que permite entregarle a un comando un bloque de varias líneas de texto como si hubiesen sido tecleadas manualmente en la entrada estándar; y el _here-string_, introducido mediante `<<<`, que permite entregar una única cadena de texto como entrada estándar de forma mucho más compacta, sin necesidad de abrir un bloque multilínea.

```bash
# Redirige el contenido del archivo hacia la entrada estándar del comando
cmd < archivo

# Here-document: entrega varias líneas como entrada estándar
cmd << EOL
linea1
linea2
EOL

# Here-string: entrega una única línea como entrada estándar,
# de forma mucho más concisa que un here-document
cmd <<< "una sola linea de texto"
```

## Descriptores de archivo personalizados y redirecciones avanzadas

Más allá de los tres descriptores estándar (`0`, `1` y `2`), bash permite abrir descriptores de archivo adicionales de forma manual mediante el comando `exec`, lo cual habilita escenarios más avanzados de manejo de flujos de datos. Mediante `exec 3< archivo` se abre el descriptor `3` en modo lectura sobre un archivo determinado, mientras que `exec 3> archivo` lo abre en modo escritura, y `exec 3<> archivo` lo abre simultáneamente en modo lectura y escritura. Un descriptor abierto de esta manera permanece disponible durante el resto de la sesión de shell (o hasta que se cierre explícitamente), y puede utilizarse posteriormente en cualquier comando mediante la sintaxis `>&3` o `<&3`, para escribir o leer respectivamente a través de él. Un descriptor se cierra explícitamente mediante `exec 3>&-`, y es posible además duplicar un descriptor existente hacia otro número, por ejemplo con `exec 4>&3`, lo cual hace que el descriptor `4` apunte al mismo destino que el `3`.

```bash
# Abre el descriptor 3 en modo lectura y escritura sobre un archivo
exec 3<> archivo

# Escribe en el archivo a través del descriptor 3
echo "contenido" >&3

# Lee el contenido del archivo a través del descriptor 3
cat <&3

# Cierra el descriptor 3
exec 3>&-
```

Uno de los usos más interesantes de esta capacidad de abrir descriptores personalizados, especialmente relevante en el ámbito ofensivo, es la posibilidad de abrir directamente una conexión de red mediante las rutas especiales `/dev/tcp/host/puerto` y `/dev/udp/host/puerto`. Se trata de una característica propia de bash, no del kernel de Linux, que permite establecer una conexión TCP o UDP hacia un host y puerto determinados sin depender de herramientas externas como `nc` o `curl`, lo cual resulta particularmente útil en entornos restringidos durante un ejercicio de post-explotación, por ejemplo para verificar la conectividad hacia un servicio remoto o incluso para construir una reverse shell rudimentaria utilizando únicamente funcionalidades nativas del shell.

```bash
# Abre una conexión TCP hacia host:puerto a través del descriptor 3,
# sin depender de herramientas externas como nc
exec 3<> /dev/tcp/host/puerto
```

Por otra parte, bash permite agrupar varios comandos y redirigir en conjunto la salida de todos ellos hacia un mismo destino. Esto puede lograrse de dos formas: encerrando los comandos entre paréntesis, lo cual los ejecuta dentro de una subshell independiente, o encerrándolos entre llaves con espacios y punto y coma, lo cual los ejecuta directamente en la shell actual sin crear un proceso adicional, resultando en un enfoque más eficiente cuando no se necesita el aislamiento que ofrece una subshell.

```bash
# Ejecuta ambos comandos en una subshell y redirige la salida conjunta
(cmd1; cmd2) > archivo

# Ejecuta ambos comandos en la shell actual (más eficiente)
# y redirige la salida conjunta hacia el archivo
{ cmd1; cmd2; } > archivo
```

Otra construcción avanzada disponible en bash es la sustitución de procesos (_process substitution_), representada mediante `<(comando)` o `>(comando)`. Esta funcionalidad permite tratar la salida (o la entrada) de un comando como si fuese un archivo temporal, sin necesidad de crear realmente un archivo en disco: internamente, bash crea una tubería con nombre (FIFO) anónima y la expone como si fuera una ruta de archivo, la cual puede pasarse como argumento a otro comando que espere recibir un nombre de archivo en lugar de datos por la entrada estándar. Un ejemplo clásico de esta técnica es comparar la salida de dos comandos distintos utilizando `diff`, herramienta que espera recibir dos rutas de archivo como argumentos y no datos por stdin.

```bash
# Compara la salida ordenada de dos búsquedas distintas
# sin necesidad de crear archivos temporales intermedios
diff <(find /ruta1 | sort) <(find /ruta2 | sort)
```

Finalmente, resulta importante mencionar el comando `tee`, el cual permite tomar la salida estándar de un comando y, simultáneamente, escribirla en un archivo y mostrarla por pantalla, a diferencia de una redirección simple con `>` que únicamente la enviaría al archivo sin mostrarla en la terminal. Esto resulta especialmente útil cuando se desea conservar un registro de la salida de un comando sin perder la posibilidad de observarla en tiempo real durante su ejecución.

```bash
# Muestra la salida de cmd en pantalla y, al mismo tiempo,
# la guarda en un archivo
cmd | tee archivo
```

## Background y Foreground

Todo comando ejecutado en una terminal corre, por defecto, en primer plano (_foreground_), lo cual significa que el shell queda bloqueado, a la espera de que dicho comando finalice, antes de poder aceptar y ejecutar cualquier otro comando. Esto resulta problemático cuando se ejecuta un programa de larga duración, o con interfaz gráfica, del cual no se necesita observar constantemente la salida, ya que mientras el proceso se mantenga en primer plano la terminal quedará inutilizada para cualquier otra tarea. Para resolver esta limitación, es posible enviar un proceso a segundo plano (_background_) anteponiendo el símbolo `&` al final del comando, lo cual permite que el shell continúe disponible para ejecutar nuevos comandos mientras el proceso enviado a segundo plano sigue corriendo de forma independiente.

```bash
# Ejecuta wireshark descartando toda su salida y lo envía
# a segundo plano, liberando la terminal para seguir trabajando
❯ wireshark &>/dev/null &
[1] 48913
```

El número entre corchetes que se muestra al enviar un proceso a segundo plano corresponde al identificador de trabajo (_job number_) asignado por el shell dentro de la sesión actual, mientras que el número que le sigue corresponde al PID (_Process ID_), el identificador único que el kernel asigna a ese proceso dentro de todo el sistema. Resulta fundamental tener en cuenta que, por defecto, los procesos enviados a segundo plano de esta manera continúan asociados a la sesión del shell que los originó, comportándose como procesos hijos de dicha sesión. Esto implica que, si el proceso padre (la propia sesión de shell, o la terminal que la contiene) finaliza o se cierra, el sistema operativo normalmente enviará una señal de cierre a todos sus procesos hijos, incluyendo aquellos que se hayan enviado a segundo plano, provocando que también finalicen de forma abrupta aunque el usuario no lo haya solicitado explícitamente.

Para evitar esta dependencia entre el proceso hijo y la sesión de shell que lo originó, bash ofrece el comando incorporado `disown`, el cual elimina un trabajo enviado a segundo plano de la tabla de trabajos que el shell gestiona internamente, desvinculándolo efectivamente de la sesión actual. Un proceso al que se le aplica `disown` continuará ejecutándose de forma completamente independiente incluso si la terminal o la sesión de shell que lo originó se cierra, comportándose de manera similar a como lo haría un proceso lanzado mediante herramientas dedicadas a este propósito, como `nohup`.

```bash
# Envía wireshark a segundo plano y, mediante disown,
# lo desvincula de la sesión actual, permitiendo que siga
# ejecutándose aunque se cierre la terminal
❯ wireshark &>/dev/null & disown
[1] 49884
```

Este comportamiento resulta especialmente relevante en el contexto de la post-explotación de un sistema, ya que permite lanzar herramientas, listeners o procesos de larga duración dentro de una sesión comprometida sin correr el riesgo de perder dicho proceso si la conexión original (por ejemplo, una shell remota) llegara a interrumpirse o cerrarse.
