# Sponge, Descompresión Recursiva y Dumps Hexadecimales

## El problema de leer y escribir sobre el mismo archivo

Un error extremadamente común al construir pipelines en bash es intentar procesar el contenido de un archivo y volcar el resultado sobre ese mismo archivo dentro de la misma línea de comandos. La intuición sugiere que, dado que las herramientas del pipeline se ejecutan en orden (`cat` primero, luego `awk`, luego la redirección final), el archivo debería leerse por completo antes de sobrescribirse. Sin embargo, esta intuición es incorrecta, y entender por qué lo es requiere comprender cómo bash gestiona realmente las redirecciones y los pipelines.

Cuando bash encuentra una redirección de salida como `> archivo`, el descriptor de archivo correspondiente se abre en modo truncado **antes** de que el comando asociado comience a ejecutarse, como parte de la propia preparación del pipeline por parte del shell. Esto significa que, en una instrucción como `cat test | awk '{print $3}' > test`, bash abre `test` en modo escritura y lo trunca (lo vacía) prácticamente de inmediato, como paso previo a lanzar los procesos `cat` y `awk`. Dado que todos los procesos de un pipeline en bash se lanzan de forma simultánea y se comunican entre sí mediante buffers en memoria (no de forma estrictamente secuencial, esperando a que termine uno para que arranque el siguiente), existe una condición de carrera real entre la apertura truncada del archivo de salida y la lectura que `cat` intenta hacer de ese mismo archivo. En la práctica, casi siempre el truncado gana la carrera, por lo que `cat` termina leyendo un archivo que ya está vacío, y el resultado final es que el archivo queda con cero bytes de contenido, o con el resultado de procesar una entrada vacía.

```bash
echo "Hola esto es una prueba" > test

# Cada una de estas variantes vacía el archivo test, por el
# motivo explicado: la redirección o tee truncan/abren el archivo
# de salida antes o durante la lectura del propio cat
cat test | awk '{print $3}' > test
cat test | awk '{print $3}' | tee test
```

El caso de `tee` merece una mención aparte, porque a primera vista parecería no tener el mismo problema, ya que `tee` no trunca el archivo hasta que empieza a recibir datos por su entrada estándar, en lugar de truncarlo de inmediato como hace una redirección `>`. Sin embargo, `tee` sí abre el archivo en modo truncado en el momento en que arranca (parte de su propia inicialización), lo cual ocurre en paralelo con el arranque de `cat`, y nuevamente se produce la misma condición de carrera: en la inmensa mayoría de los casos, `tee` trunca el archivo antes de que `cat` termine de leerlo por completo, con el mismo resultado final indeseado.

El uso de `>>` (append) evita el truncado, pero introduce un problema distinto: en lugar de vaciar el archivo, agrega el resultado del pipeline al final del contenido ya existente, sin eliminar el contenido original. Esto significa que, lejos de reemplazar el archivo por el resultado procesado, se termina con el contenido original intacto seguido del resultado nuevo, lo cual tampoco es el comportamiento deseado cuando la intención es sustituir el contenido del archivo por su versión procesada.

```bash
# Esto NO sobrescribe: agrega el resultado al final,
# conservando el contenido original de test intacto
cat test | awk '{print $3}' >> test
```

### La solución: sponge

La utilidad `sponge`, incluida en el paquete `moreutils`, resuelve este problema de raíz mediante un enfoque conceptualmente simple: en lugar de escribir su salida de forma incremental a medida que la recibe (como hacen `tee` o una redirección normal), `sponge` "absorbe" por completo toda la entrada estándar en un búfer de memoria interno hasta detectar el fin de la entrada (EOF), y únicamente después de haber leído la totalidad de los datos procede a abrir el archivo de destino, truncarlo y escribir el contenido completo de una sola vez. Este comportamiento elimina por completo la condición de carrera descrita anteriormente, ya que para el momento en que `sponge` abre y trunca el archivo, `cat` ya ha terminado de leerlo íntegramente y ha entregado todo su contenido a través del pipeline.

```bash
# Instala moreutils si sponge no está disponible en el sistema
sudo apt install moreutils

# Ahora sí: lee el contenido completo de test, lo procesa con awk,
# y sponge escribe el resultado sobre el mismo archivo de forma segura,
# solo después de haber consumido toda la entrada
cat test | awk '{print $3}' | sponge test
```

El nombre de la herramienta es, de hecho, una metáfora bastante acertada de su funcionamiento: al igual que una esponja absorbe todo el líquido disponible antes de poder escurrirse, `sponge` absorbe toda la entrada disponible antes de escribir nada en disco. Esta herramienta resulta especialmente valiosa en scripts de automatización que necesitan filtrar, ordenar o transformar el contenido de un archivo de configuración "en el lugar" (_in-place_), sin depender de crear manualmente un archivo temporal intermedio y luego renombrarlo, que era la solución tradicional a este mismo problema antes de la existencia de `sponge`.

```bash
# Patrón equivalente pero manual, sin sponge, usando un archivo temporal:
# esta era la solución clásica antes de que sponge estuviera disponible
cat test | awk '{print $3}' > test.tmp && mv test.tmp test
```

## Descompresión recursiva

### El problema: capas anidadas de compresión

En numerosos retos de CTF, y en algunos escenarios reales de exfiltración o de distribución de malware, es habitual encontrarse con un archivo comprimido que, al descomprimirse, no revela directamente el contenido final, sino un nuevo archivo que a su vez también está comprimido, y así sucesivamente a lo largo de un número de capas que no se conoce de antemano. Este patrón, a veces denominado informalmente "muñeca rusa" de archivos comprimidos, tiene como objetivo dificultar el análisis automatizado o, en un contexto didáctico, poner a prueba la capacidad de quien resuelve el reto para automatizar una tarea repetitiva en lugar de realizarla manualmente decena de veces.

El problema práctico que esto plantea es evidente: descomprimir manualmente archivo por archivo, comprobando cada vez si el resultado es a su vez otro archivo comprimido, resulta tedioso y propenso a errores cuando el número de capas es elevado (en algunos retos, puede llegar a varios cientos de niveles). La solución natural es automatizar este proceso mediante un script que repita la operación de "descomprimir y comprobar el resultado" de forma indefinida, hasta que ya no quede nada más por descomprimir.

### Análisis del script paso a paso

El [script proporcionado](../scripts/decompressor.sh) resuelve exactamente este problema apoyándose en `7z` (la herramienta de línea de comandos de 7-Zip, capaz de manejar una enorme variedad de formatos de compresión) y en un bucle `while` que se repite mientras exista un nombre de archivo pendiente de descomprimir.

```bash
#!/bin/bash
function ctrl_c(){
  echo -e "\n\n[!] Saliendo...\n"
  exit 1
}
# Ctrl+C
trap ctrl_c INT
```

La primera parte del script define una función `ctrl_c` y la asocia, mediante el comando `trap`, a la señal `INT` (_interrupt_), que es la señal que el sistema operativo envía a un proceso cuando el usuario presiona `Ctrl+C` en la terminal. Sin este mecanismo, presionar `Ctrl+C` mientras el script se ejecuta interrumpiría abruptamente el proceso de `7z` en curso, pudiendo dejar archivos a medio extraer o el terminal en un estado inconsistente; con `trap` configurado, en cambio, la interrupción se captura de forma controlada, se muestra un mensaje informativo, y el script finaliza de manera ordenada mediante `exit 1`. Este patrón de captura de señales es una buena práctica general en cualquier script que vaya a ejecutarse de forma potencialmente larga o desatendida.

```bash
first_file_name="data.gz"
decompressed_file_name="$(7z l data.gz | tail -n 3 | head -n 1 | awk 'NF{print $NF}')"
7z x $first_file_name &>/dev/null
```

A continuación, el script define el nombre del primer archivo comprimido conocido (`data.gz`) y, antes incluso de extraerlo, utiliza `7z l` (el subcomando `l`, de _list_, que lista el contenido de un archivo comprimido sin extraerlo) para averiguar de antemano cuál será el nombre del archivo que resultará de esa extracción. La salida de `7z l` incluye, entre otras líneas informativas, una tabla con los archivos contenidos en el paquete comprimido, y la combinación `tail -n 3 | head -n 1` es una técnica para aislar una línea concreta de esa tabla: `tail -n 3` se queda con las últimas tres líneas de la salida completa de `7z l` (que, dado el formato habitual de este comando, corresponden a la línea de la entrada del archivo, seguida de una línea separadora y una línea de totales), y de esas tres líneas, `head -n 1` se queda únicamente con la primera, que es la que contiene el nombre real del archivo listado. Finalmente, `awk 'NF{print $NF}'` imprime el último campo de esa línea (`$NF`), que corresponde precisamente al nombre del archivo, siempre y cuando la línea no esté vacía (la condición `NF` antes del bloque de acción verifica que la línea tenga al menos un campo, evitando así intentar imprimir algo si la línea estuviera vacía).

Con el nombre del archivo resultante ya conocido y almacenado en `decompressed_file_name`, el script procede a extraer efectivamente el primer archivo con `7z x` (el subcomando `x`, de _extract_, que sí realiza la extracción real, a diferencia de `l`), redirigiendo tanto su salida estándar como su error estándar hacia `/dev/null` para no ensuciar la terminal con los mensajes propios de la herramienta.

```bash
while [ $decompressed_file_name ]; do
  echo -e "\n[+] Nuevo archivo descomprimido: $decompressed_file_name"
  7z x $decompressed_file_name &>/dev/null
  decompressed_file_name="$(7z l $decompressed_file_name 2>/dev/null | tail -n 3 | head -n 1 | awk 'NF{print $NF}')"
done
```

El núcleo del script es este bucle `while`, cuya condición es simplemente comprobar si la variable `decompressed_file_name` tiene contenido. En bash, la construcción `[ $variable ]` (equivalente a `test $variable`) se evalúa como verdadera si la variable no está vacía, y como falsa si lo está; esta es, precisamente, la clave que permite que la recursividad se resuelva de forma automática sin necesidad de conocer de antemano cuántas capas de compresión existen: mientras el nombre de archivo obtenido en la iteración anterior no esté vacío, el bucle continúa ejecutándose.

En cada vuelta del bucle ocurren tres cosas en orden: primero se informa al usuario, mediante un mensaje, de qué archivo se acaba de descomprimir en la iteración anterior; después se extrae efectivamente ese archivo con `7z x`; y finalmente se vuelve a consultar, con la misma técnica de `7z l` combinada con `tail`, `head` y `awk` explicada anteriormente, cuál sería el nombre del siguiente archivo resultante, actualizando la variable `decompressed_file_name` para la siguiente iteración. El punto clave que hace que el bucle termine correctamente cuando ya no quedan más capas de compresión es el `2>/dev/null` añadido a `7z l` dentro del bucle: cuando el archivo que se acaba de extraer resulta ser, finalmente, el contenido real y no otro archivo comprimido, invocar `7z l` sobre él producirá un error (porque `7z` no reconocerá un formato de archivo comprimido válido), y ese error se descarta silenciosamente gracias a la redirección; como consecuencia, la sustitución de comandos `$(...)` no captura ninguna salida, la variable `decompressed_file_name` queda vacía, y la condición del `while` deja de cumplirse, finalizando el bucle de forma natural sin necesidad de una condición de parada explícita ni de conocer de antemano el número de capas.

Este diseño constituye un patrón muy elegante y reutilizable de automatización: en lugar de intentar predecir cuántas veces hay que repetir una operación, se aprovecha el propio fallo de la operación (la ausencia de una salida válida cuando ya no hay más capas que procesar) como condición natural de finalización del bucle. Es un patrón que puede adaptarse fácilmente a otros escenarios de descompresión recursiva sustituyendo `7z` por herramientas equivalentes como `tar`, `gzip`, `unzip` o `bzip2`, ajustando en cada caso la forma de extraer el nombre del archivo resultante según el formato de salida propio de cada herramienta.

## Dumps hexadecimales

### Qué es un dump hexadecimal y por qué se utiliza

Un dump hexadecimal (o _hexdump_) es una representación del contenido crudo (en bruto) de un archivo, mostrando cada byte que lo compone como un par de dígitos en base 16 (hexadecimal), habitualmente acompañado de una columna adicional con la representación en caracteres ASCII imprimibles de esos mismos bytes, cuando corresponden a un carácter representable, y con un punto u otro símbolo de relleno cuando no lo son. Esta forma de visualización resulta indispensable al trabajar con archivos binarios, ya que herramientas como `cat` asumen que el contenido es texto codificado en algún juego de caracteres reconocible, y al encontrarse con bytes que no forman una secuencia de texto válida, producen una salida ilegible o incluso pueden alterar el comportamiento de la propia terminal (por ejemplo, interpretando ciertos bytes como secuencias de escape de control).

El uso de dumps hexadecimales es particularmente relevante en varios escenarios de ciberseguridad: identificar el formato real de un archivo a partir de su firma o _magic number_ (los primeros bytes de muchos formatos de archivo siguen una convención fija y reconocible, como `FF D8 FF` al inicio de una imagen JPEG, o `50 4B 03 04` al inicio de un archivo ZIP), analizar malware o binarios sospechosos byte a byte cuando `strings` o `file` no aportan suficiente información, depurar problemas de codificación de caracteres, o localizar y modificar manualmente bytes concretos dentro de un archivo, algo habitual tanto en ingeniería inversa como en la resolución de retos de esteganografía o de manipulación de formatos de archivo.

### Herramientas para generar dumps hexadecimales

La herramienta más utilizada en sistemas Linux para este propósito es `xxd`, incluida por defecto junto con `vim`, que ofrece una salida clara y ampliamente adoptada como estándar de facto en la comunidad.

```bash
# Vuelca el contenido completo de un archivo en hexadecimal,
# mostrando 16 bytes por línea junto con su representación ASCII
xxd archivo.bin

# Limita la salida a los primeros N bytes, muy útil para
# inspeccionar rápidamente solo la cabecera de un archivo grande
# y así identificar su tipo real por su magic number
xxd -l 16 archivo.bin

# Combina xxd con head para lograr el mismo efecto que -l,
# quedándose únicamente con la primera línea de la salida completa
xxd archivo.bin | head -n 1

# Genera la salida en formato "plano" de una sola columna continua
# de dígitos hexadecimales, sin las columnas de offset ni ASCII,
# útil cuando se necesita procesar la salida con otro comando
xxd -p archivo.bin

# Operación inversa: reconstruye el archivo binario original
# a partir de su representación hexadecimal
xxd -r -p dump.hex archivo_reconstruido.bin
```

Una salida típica de `xxd` sigue esta estructura, que conviene saber interpretar: una primera columna con el desplazamiento (_offset_) en hexadecimal respecto al inicio del archivo, indicando en qué posición exacta comienza esa línea; una segunda sección central con los propios bytes representados en pares hexadecimales, agrupados de dos en dos; y una tercera columna a la derecha con la representación ASCII de esos mismos bytes, mostrando un punto (`.`) en lugar del carácter cuando el byte no corresponde a un carácter imprimible.

```
00000000: 4865 6c6c 6f2c 206d 756e 646f 210a       Hello, mundo!.
```

Además de `xxd`, existen otras utilidades equivalentes con ligeras diferencias de formato y de opciones disponibles, como `hexdump` (particularmente su variante `hexdump -C`, que produce una salida muy similar a la de `xxd`) y `od` (_octal dump_, la más antigua de las tres, capaz de mostrar el contenido tanto en octal como en hexadecimal o decimal según las opciones indicadas).

```bash
# hexdump con formato "canónico" (-C), muy similar a la salida de xxd
hexdump -C archivo.bin | head -n 5

# od mostrando el contenido en hexadecimal (-x) con direcciones también
# en hexadecimal (-A x), una de sus combinaciones más legibles
od -A x -t x1z archivo.bin | head -n 5
```

### Identificación de tipos de archivo a partir de la cabecera

Un uso extremadamente práctico de los dumps hexadecimales, y muy frecuente en retos de CTF donde la extensión de un archivo ha sido alterada deliberadamente, consiste en inspeccionar manualmente los primeros bytes del archivo y compararlos contra una lista de firmas de archivo conocidas, en lugar de confiar únicamente en la extensión del nombre.

```bash
# Comprueba los primeros bytes de un archivo cuya extensión
# es sospechosa o ha sido eliminada intencionalmente
xxd -l 8 archivo_sospechoso

# Ejemplos de firmas de archivo (magic numbers) habituales
# que conviene reconocer a simple vista:
#   89 50 4E 47              -> PNG
#   FF D8 FF                 -> JPEG
#   47 49 46 38              -> GIF
#   25 50 44 46              -> PDF
#   50 4B 03 04               -> ZIP (y formatos basados en ZIP, como DOCX/XLSX)
#   1F 8B                     -> GZIP
#   7F 45 4C 46               -> ELF (ejecutables Linux)
```

En la práctica, aunque el comando `file` ya realiza automáticamente este tipo de comprobación contra una base de datos interna mucho más completa de firmas conocidas, saber leer manualmente un dump hexadecimal resulta imprescindible cuando el archivo ha sido deliberadamente corrompido o manipulado en sus primeros bytes (una técnica común en retos de esteganografía o de recuperación de archivos), ya que en esos casos `file` puede fallar al identificar el formato correctamente, mientras que una inspección manual permite detectar y corregir a mano la cabecera dañada, comparándola contra la firma esperada del formato que se sospecha que debería tener el archivo.
