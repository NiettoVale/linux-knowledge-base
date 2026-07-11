# Manejo Avanzado de Ficheros en Linux: Lectura, Filtrado y Decodificación

## Introducción

Más allá de los comandos básicos de lectura y navegación, existe todo un conjunto de técnicas que resultan indispensables tanto en la administración cotidiana de un sistema Linux como, muy particularmente, en ejercicios de CTF, HackTheBox o auditorías de post-explotación: leer ficheros cuyo nombre confunde al propio intérprete de comandos, filtrar y transformar texto de forma quirúrgica combinando varias herramientas mediante pipes, e interpretar contenido que no está pensado para leerse directamente, ya sea porque es binario o porque está codificado o cifrado. Este documento reúne estas técnicas, explicando el porqué de cada una y no solo el cómo, ya que comprender la causa de un comportamiento inesperado del shell es lo que realmente permite resolver variantes del mismo problema en el futuro sin depender de memorizar soluciones puntuales.

## Lectura de ficheros con nombres especiales

### Ficheros cuyo nombre comienza con un guion

Cuando un archivo tiene un nombre que comienza con el carácter `-`, como por ejemplo un archivo literalmente llamado `-`, intentar leerlo de la forma habitual con `cat -` no funciona como cabría esperar. El motivo es que prácticamente todas las utilidades de línea de comandos en Unix siguen la convención de que cualquier argumento que comience con un guion se interpreta como una flag u opción del propio comando, y no como un nombre de archivo. Al ejecutar `cat -`, el programa no entiende que se le está pidiendo leer un archivo llamado `-`, sino que interpreta ese guion como la instrucción de leer desde la entrada estándar (comportamiento estándar de `cat` cuando no recibe un nombre de archivo válido), por lo que el comando queda "colgado", esperando indefinidamente a que el usuario escriba algo por teclado, en lugar de fallar con un error evidente.

La solución a este problema consiste, en esencia, en lograr que el nombre del archivo no comience literalmente con un guion desde el punto de vista del parser de argumentos, aunque el archivo en disco sí se llame así. Esto puede lograrse anteponiendo cualquier prefijo de ruta al nombre, de modo que el argumento que recibe `cat` ya no comience con `-`, sino con `.` o con `/`.

```bash
# Antepone "./" al nombre del archivo: el argumento que recibe
# cat ya no empieza con "-", por lo que deja de interpretarse
# como una flag y se trata correctamente como una ruta de archivo
cat ./-

# Uso de la ruta absoluta completa, misma lógica: el argumento
# ya no comienza con el carácter "-"
cat /home/fnieto/directorio/-

# Sustitución de comandos: $(pwd) se expande primero a la ruta
# absoluta del directorio actual, de modo que el argumento final
# que recibe cat es algo como "/home/fnieto/directorio/-",
# que tampoco comienza con un guion
cat $(pwd)/-
```

Existe además una convención POSIX ampliamente adoptada por muchas utilidades (aunque no todas) que consiste en usar `--` como marcador explícito de "fin de las opciones": todo lo que aparezca después de `--` se trata como argumento posicional (por ejemplo, un nombre de archivo), sin importar que comience con un guion.

```bash
# El doble guion le indica a cat que deje de interpretar
# flags a partir de ese punto; útil en comandos que lo soportan
cat -- -
```

Este mismo problema y su misma solución aparecen de forma recurrente al buscar el nombre real de un archivo "raro" dentro de un conjunto de resultados, por ejemplo tras un `find` o un `grep -r`. Una técnica habitual en este tipo de escenarios (frecuente en retos como los de OverTheWire Bandit) consiste en filtrar recursivamente el contenido de un directorio en busca de alguna palabra o patrón conocido, quedarse con la línea de resultado relevante, y extraer únicamente el nombre del archivo de esa línea, descartando el resto de la información que antecede a los dos puntos que `grep -r` antepone por defecto a cada coincidencia.

```bash
# grep -r busca recursivamente cualquier línea con al menos
# un carácter alfanumérico ("\w"); tail -n 1 se queda con la
# última línea de resultado; awk separa por el carácter ":"
# (FS=":") e imprime el segundo campo, que corresponde
# al nombre del archivo encontrado por grep
grep -r "\w" 2>/dev/null | tail -n 1 | awk '{print $2}' FS=":"

# Alternativa funcionalmente equivalente usando cut,
# que corta la línea por el delimitador ":" y se queda
# con el segundo campo
grep -r "\w" 2>/dev/null | tail -n 1 | cut -d ':' -f 2

# Otra alternativa: tr reemplaza cada ":" por un espacio,
# y luego awk imprime el segundo campo separado por espacios
grep -r "\w" 2>/dev/null | tail -n 1 | tr ':' ' ' | awk '{print $2}'
```

### Ficheros con espacios en el nombre

Los espacios tienen un significado especial para el shell: por defecto, se utilizan para separar los distintos argumentos de un comando. Esto significa que un archivo llamado `spaces in this filename` no puede pasarse tal cual a `cat`, ya que el shell lo interpretaría como cuatro argumentos independientes (`spaces`, `in`, `this` y `filename`) en lugar de como un único nombre de archivo. Existen varias formas de resolver esta ambigüedad, todas ellas basadas en indicarle al shell, de una manera u otra, que ese espacio forma parte del nombre y no debe usarse como separador.

```bash
# Encerrar el nombre completo entre comillas dobles es la forma
# más clara y recomendada: el shell trata todo el contenido
# entre comillas como un único argumento
cat "spaces in this filename"

# Alternativa: escapar cada espacio individualmente con
# una barra invertida, indicándole al shell que ese carácter
# en particular no debe interpretarse como separador
cat spaces\ in\ this\ filename

# En la práctica, resulta muy cómodo aprovechar el autocompletado
# del shell (tab) para que sea la propia terminal la que inserte
# automáticamente las barras de escape necesarias, sin tener
# que teclearlas manualmente ni arriesgarse a un error de tipeo

# Uso de comodines: si se conoce parte del nombre, un asterisco
# permite evitar por completo el problema de los espacios,
# ya que el shell expande el patrón antes de pasarlo a cat
cat s*

# Muestra el contenido de TODOS los archivos de un directorio,
# concatenados uno tras otro, sin importar sus nombres
cat /home/fnieto/directorio/*

# Ruta relativa o absoluta hacia un nombre conocido sin espacios
cat ./archivo
```

## Ficheros ocultos

En Linux, un archivo o directorio se considera oculto simplemente porque su nombre comienza con un punto (`.`), una convención heredada directamente de Unix y que no implica ningún mecanismo real de protección o cifrado: cualquier usuario con permisos de lectura puede acceder a su contenido con total normalidad, la única diferencia es que `ls` no los muestra en un listado normal a menos que se le indique explícitamente que lo haga.

```bash
# Muestra también los archivos y directorios ocultos, en formato detallado
ls -la

# Antes de asumir el tipo de contenido de un archivo oculto,
# "file" permite identificar de qué tipo de archivo se trata
# (texto plano, binario, script, imagen, etc.) analizando
# su contenido real y no solo su nombre o extensión
file .hidden

# Lee el contenido de un archivo oculto de texto normalmente
cat .hidden
```

Una técnica interesante para recorrer sistemáticamente el contenido de múltiples archivos (ocultos o no) dentro de un directorio, descartando aquellos que resultan poco relevantes por ser configuraciones estándar del shell, consiste en combinar `find` con `grep -v` (que invierte la coincidencia, mostrando lo que NO matchea el patrón) y `xargs` para aplicar `cat` a cada resultado.

```bash
# Busca todos los archivos regulares del directorio actual,
# descarta (con -v de "invertir") aquellos cuyo nombre contenga
# "bashrc", "profile" o "logout" (archivos de configuración
# estándar del shell, poco interesantes en este contexto),
# y muestra el contenido de todo lo demás con cat
find . -type f | grep -vE "bashrc|profile|logout" | xargs cat

# Busca archivos cuyo nombre contenga el patrón "-file"
# (el guion se escapa con "\-" porque, dentro de una expresión
# regular de grep, un guion al inicio de un rango de caracteres
# también podría interpretarse con un significado especial)
# y determina el tipo de cada uno con file, a través de xargs
find . -type f | grep "\-file" | xargs file
```

## Búsquedas avanzadas con find: tamaño, legibilidad y propietario

Retomando y combinando las opciones de `find` ya vistas en apuntes anteriores, resulta muy habitual en retos de CTF y en tareas de enumeración tener que localizar un archivo describiendo varias características simultáneas: su tamaño exacto en bytes, si es legible por el usuario actual, si carece de permiso de ejecución, o a qué usuario y grupo pertenece.

```bash
# Busca un fichero legible por el usuario actual (-readable),
# de exactamente 1033 bytes de tamaño (el sufijo "c" indica bytes,
# a diferencia de "k" o "M"), y que además NO sea ejecutable
# (el símbolo "!" niega la condición que le sigue)
find / -type f -readable -size 1033c ! -executable 2>/dev/null

# Busca un fichero que pertenezca simultáneamente al usuario
# "bandit7" y al grupo "bandit6", con un tamaño exacto de 33 bytes,
# y muestra directamente su contenido encadenando xargs cat
find / -type f -user bandit7 -group bandit6 -size 33c 2>/dev/null | xargs cat
```

Este tipo de combinaciones ilustra bien la filosofía de `find`: en lugar de recordar un comando específico para cada escenario, se trata de ir sumando condiciones (todas ellas unidas por un "y" lógico implícito) hasta que el conjunto de resultados se reduzca a lo estrictamente buscado, algo especialmente útil cuando se sabe de antemano una característica concreta del archivo objetivo (por ejemplo, su tamaño exacto, dato frecuente en el enunciado de un reto) pero no su nombre ni su ubicación exacta.

## Filtrado y transformación de texto

Una vez localizado el contenido relevante, suele ser necesario filtrarlo o transformarlo para quedarse únicamente con el dato que interesa, descartando el resto. Para esto, Linux ofrece un conjunto de herramientas de propósito específico que, combinadas mediante pipes, permiten construir filtros extremadamente precisos sin necesidad de escribir un script completo.

```bash
# Filtra las líneas de data.txt que contienen la palabra "millionth"
# (con -i para ignorar mayúsculas/minúsculas), y de esas líneas
# awk imprime únicamente el último campo (NF, "Number of Fields",
# hace referencia dinámicamente a la posición del último campo
# de cada línea, sin importar cuántos campos tenga en total)
cat data.txt | grep -i "millionth" | awk 'NF{print $NF}'
```

Conviene detenerse un momento en `awk`, ya que es una de las herramientas más potentes y a la vez más subestimadas del ecosistema Unix: se trata de un lenguaje de procesamiento de texto orientado a registros y campos, donde por defecto cada línea de la entrada se considera un registro, y cada palabra separada por espacios (o por el separador que se indique con `FS`, _Field Separator_) se considera un campo, accesible mediante `$1`, `$2`, y así sucesivamente, mientras que `$NF` siempre apunta al último campo de la línea actual, sea cual sea su posición numérica exacta, lo cual resulta muy conveniente cuando el número de campos varía de una línea a otra.

Para detectar líneas duplicadas o, por el contrario, líneas que aparecen una única vez dentro de un archivo (un patrón de búsqueda frecuente en retos donde el dato interesante es precisamente "la aguja en el pajar", el único valor que no se repite entre miles de líneas idénticas), la combinación de `sort` seguido de `uniq` resulta indispensable.

```bash
# uniq solo detecta líneas duplicadas si son CONSECUTIVAS,
# por lo que ordenar previamente con sort es un paso obligatorio
# para que todas las repeticiones de un mismo valor queden juntas.
# La opción -u de uniq muestra únicamente las líneas que NO tienen
# ningún duplicado en todo el archivo, es decir, las que aparecen
# una única vez
cat data.txt | sort | uniq -u

# Variantes útiles de uniq:
# -d muestra únicamente las líneas que SÍ están duplicadas
# -c antepone a cada línea el número de veces que aparece
sort data.txt | uniq -d
sort data.txt | uniq -c
```

## Interpretación de ficheros binarios

Cuando el contenido de un archivo no es texto plano, `cat` produce una salida ilegible, mezclando caracteres de control y símbolos sin sentido en la terminal. Para estos casos, `strings` resulta la herramienta de referencia: recorre el archivo completo, sea cual sea su formato, y extrae únicamente las secuencias de bytes que se corresponden con texto legible (por defecto, secuencias de al menos cuatro caracteres imprimibles consecutivos), descartando todo lo demás. Esto la convierte en una herramienta de reconocimiento muy valiosa al enfrentarse a un binario desconocido, ya que a menudo revela rutas de archivos, mensajes de error, URLs, o incluso credenciales embebidas por descuido en el propio ejecutable.

```bash
# Extrae las cadenas de texto legibles de un archivo binario,
# filtra aquellas que contienen "===" (un patrón habitual usado
# como delimitador o marca en algunos retos de CTF), se queda
# con la última coincidencia, y de esa línea imprime el último campo
strings data.txt | grep "===" | tail -n 1 | awk 'NF{print $NF}'
```

Más allá de `strings`, resulta útil conocer que la identificación real del tipo de un archivo no depende de su extensión (que es solo una convención y puede alterarse libremente sin cambiar el contenido real), sino de su contenido binario, concretamente de los primeros bytes del archivo, conocidos como _magic numbers_ o firmas de archivo (_file signatures_). El comando `file`, mencionado anteriormente, se apoya precisamente en una base de datos de estas firmas conocidas para determinar el tipo real de un archivo independientemente de su nombre o extensión, lo cual lo convierte en un primer paso obligado antes de intentar procesar cualquier archivo desconocido, especialmente en retos donde el nombre o la extensión del archivo pueden haber sido alterados deliberadamente para despistar.

```bash
# Determina el tipo real del archivo analizando su contenido,
# sin importar su extensión aparente
file archivo_sospechoso

# xxd permite inspeccionar directamente los primeros bytes
# en hexadecimal, útil para comparar manualmente contra
# una lista de firmas de archivo conocidas cuando "file" no
# logra identificar el formato con certeza
xxd archivo_sospechoso | head -n 1
```

## Ficheros codificados en Base64

Base64 es un esquema de codificación (no de cifrado) que transforma datos binarios arbitrarios en una cadena compuesta únicamente por caracteres imprimibles del alfabeto ASCII (letras, números, `+`, `/` y `=` como relleno), lo cual resulta muy útil para transportar datos binarios a través de medios pensados originalmente para texto, como el cuerpo de un correo electrónico o una URL. Es fundamental tener presente que Base64 no aporta ningún tipo de seguridad ni confidencialidad: cualquiera que reconozca una cadena en Base64 puede decodificarla instantáneamente sin necesidad de ninguna clave, por lo que encontrarse con datos en Base64 durante una auditoría no debe interpretarse como un dato "protegido", sino simplemente como un dato "transformado" que conviene decodificar cuanto antes para inspeccionar su contenido real.

```bash
# Codifica el texto "Prueba" a Base64
echo "Prueba" | base64

# Codifica el contenido completo de un archivo a Base64;
# por defecto, la salida se divide en líneas de 76 caracteres
cat /etc/hosts | base64

# La opción -w 0 desactiva el ajuste de línea, generando
# la codificación completa en una única línea continua,
# más cómoda para copiar y pegar o para usar como argumento
# de otro comando
cat /etc/hosts | base64 -w 0

# Decodifica una cadena en Base64 de vuelta a su forma original,
# mediante la opción -d ("decode")
cat data.txt | base64 -d
```

En el contexto de CTF y pentesting, es habitual encontrar varias capas anidadas de Base64 (una cadena que, al decodificarse, revela otra cadena también en Base64), por lo que conviene tener presente que el proceso de decodificación puede requerir aplicarse más de una vez de forma sucesiva hasta llegar al contenido final legible.

```bash
# Decodificación de Base64 anidado (dos capas), encadenando
# el proceso de decodificación dos veces seguidas
cat data.txt | base64 -d | base64 -d
```

## Cifrado César con tr

A diferencia de Base64, el cifrado César sí constituye un cifrado propiamente dicho, aunque extremadamente débil desde el punto de vista criptográfico: consiste en desplazar cada letra del alfabeto un número fijo de posiciones (la "clave" del cifrado), de modo que, por ejemplo, con un desplazamiento de 3 posiciones, la letra `A` se convierte en `D`, la `B` en `E`, y así sucesivamente, volviendo al principio del alfabeto una vez superada la `Z`. Su debilidad radica en que, al existir únicamente 25 desplazamientos posibles distintos de cero, resulta trivial romperlo por fuerza bruta probando todas las combinaciones, o incluso identificarlo a simple vista por patrones característicos del idioma. Aun así, sigue apareciendo con frecuencia en retos introductorios de criptografía dentro de CTFs, precisamente por su simplicidad didáctica.

El comando `tr` (_translate_), cuya función habitual es sustituir o eliminar caracteres de una cadena de forma directa, resulta ideal para implementar un cifrado César en una única línea, ya que permite definir de forma explícita la correspondencia exacta entre cada carácter de un conjunto de origen y el carácter correspondiente en un conjunto de destino.

```bash
# Aplica un desplazamiento de 13 posiciones (variante conocida
# específicamente como ROT13, un caso particular muy popular
# del cifrado César por ser su propio inverso: aplicarlo dos
# veces devuelve el texto original). El primer rango describe
# el alfabeto de entrada en su orden natural, dividido en dos
# mitades (G-Z seguido de A-F, para mayúsculas, y lo mismo
# en minúsculas), y el segundo rango describe hacia qué letra
# se traduce cada una de las anteriores, respetando el mismo orden
cat data.txt | tr '[G-ZA-Fg-za-f]' '[T-ZA-St-za-s]'

# Forma más directa y legible de aplicar ROT13 con tr,
# equivalente al ejemplo anterior
cat data.txt | tr 'A-Za-z' 'N-ZA-Mn-za-m'

# Para descifrar un desplazamiento distinto de 13, basta con
# invertir el orden de los dos conjuntos de caracteres en tr;
# por ejemplo, para deshacer un desplazamiento de 3 posiciones
# (donde A se convirtió en D), se traduce en sentido inverso:
cat data_cifrado.txt | tr 'D-ZA-Cd-za-c' 'A-Za-z'
```
