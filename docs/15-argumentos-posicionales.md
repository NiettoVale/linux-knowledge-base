# Argumentos Posicionales en Bash

## Introducción

Cuando un script de bash se invoca desde la línea de comandos, es posible acompañarlo de una serie de palabras adicionales separadas por espacios, las cuales el script recibe internamente como un conjunto de variables especiales predefinidas, sin necesidad de declararlas explícitamente. Este mecanismo es lo que permite que un mismo script pueda comportarse de forma distinta según los datos que se le proporcionen en cada invocación, en lugar de tener valores fijos escritos directamente en su código, lo cual resulta imprescindible para escribir scripts reutilizables y genéricos en lugar de herramientas de un solo uso.

```bash
./script.sh hola mundo 123
```

En este ejemplo, `script.sh` es el propio script que se está ejecutando, y `hola`, `mundo` y `123` son tres argumentos independientes que bash pone a disposición del script a través de variables predefinidas, conocidas como parámetros o argumentos posicionales, precisamente porque cada uno se identifica por la posición que ocupa en la línea de comandos y no por un nombre elegido por quien escribe el script.

## $0: el nombre del script

La variable `$0` contiene el nombre (o, más precisamente, la ruta) con la que el propio script fue invocado desde la terminal. Es importante notar que su contenido depende exactamente de cómo se escribió la invocación: si el script se llamó mediante una ruta relativa, `$0` contendrá esa misma ruta relativa; si se llamó mediante una ruta absoluta, contendrá la ruta absoluta completa.

```bash
#!/bin/bash
echo "El script invocado es: $0"
```

```bash
❯ ./saludo.sh
El script invocado es: ./saludo.sh

❯ /home/fnieto/scripts/saludo.sh
El script invocado es: /home/fnieto/scripts/saludo.sh
```

Un uso habitual de `$0` es combinarlo con el comando `basename` para obtener únicamente el nombre del archivo, descartando la ruta que lo precede, algo útil al construir mensajes de ayuda o de uso (_usage_) que no dependan de cómo el usuario decidió invocar el script.

```bash
#!/bin/bash
echo "Uso: $(basename "$0") <argumento1> <argumento2>"
```

## $1, $2, $3... : los argumentos individuales

Cada argumento proporcionado en la línea de comandos, a partir del primero, queda accesible mediante una variable numerada de forma secuencial: `$1` corresponde al primer argumento, `$2` al segundo, y así sucesivamente. Esta numeración es la razón por la que este mecanismo recibe el nombre de "argumentos posicionales": el número no es un identificador arbitrario, sino que refleja literalmente la posición que ese argumento ocupa en la invocación del script.

```bash
#!/bin/bash
echo "Primer argumento: $1"
echo "Segundo argumento: $2"
echo "Tercer argumento: $3"
```

```bash
❯ ./script.sh hola mundo 123
Primer argumento: hola
Segundo argumento: mundo
Tercer argumento: 123
```

Cuando un script intenta acceder a un argumento posicional que no fue proporcionado en la invocación (por ejemplo, `$3` cuando solo se pasaron dos argumentos), bash no genera ningún error; simplemente esa variable se comporta como una variable vacía, sin contenido, lo cual conviene tener presente al escribir scripts que dependan de un número concreto de argumentos, ya que un argumento faltante no interrumpe la ejecución por sí solo y puede dar lugar a comportamientos inesperados si no se valida explícitamente.

Para acceder a argumentos posicionales de dos o más cifras (a partir del décimo argumento), es necesario encerrar el número entre llaves, ya que la sintaxis `$10` sin llaves se interpreta como la variable `$1` seguida literalmente del carácter `0`, y no como un único parámetro posicional número diez.

```bash
#!/bin/bash
# Correcto: accede al décimo argumento posicional
echo "Décimo argumento: ${10}"

# Incorrecto: esto se interpreta como "$1" concatenado con "0"
echo "Esto NO es el décimo argumento: $10"
```

## $#: la cantidad de argumentos recibidos

La variable `$#` contiene, en todo momento, el número total de argumentos posicionales que el script recibió en su invocación, sin contar el propio `$0`. Esta variable resulta fundamental para validar, al inicio de un script, que se haya proporcionado la cantidad de información esperada antes de continuar con el resto de la lógica, evitando así que el script intente operar sobre argumentos vacíos o inexistentes.

```bash
#!/bin/bash
echo "Se recibieron $# argumentos"

if [ "$#" -lt 2 ]; then
  echo "Uso: $(basename "$0") <origen> <destino>"
  exit 1
fi
```

```bash
❯ ./script.sh solo_uno
Se recibieron 1 argumentos
Uso: script.sh <origen> <destino>
```

Esta validación temprana, comprobando `$#` antes de continuar con el resto del script, es una práctica extremadamente extendida y recomendable en cualquier script que dependa de argumentos: permite fallar de forma rápida y con un mensaje claro cuando el script se invoca incorrectamente, en lugar de continuar ejecutándose con variables vacías y producir errores confusos o comportamientos incorrectos más adelante en la lógica del programa.

## `$\* y $@`: todos los argumentos juntos

Tanto `$*` como `$@` representan, en apariencia, el conjunto completo de todos los argumentos posicionales recibidos, y en la mayoría de los casos de uso sencillos ambas variables se comportan de forma indistinguible. Sin embargo, existe una diferencia de comportamiento importante entre ambas, que se manifiesta específicamente cuando se utilizan entre comillas dobles, y comprenderla evita errores sutiles pero frecuentes al escribir scripts que deban preservar argumentos que contienen espacios internos.

```bash
#!/bin/bash
echo "Usando \$*: $*"
echo "Usando \$@: $@"
```

```bash
❯ ./script.sh hola mundo 123
Usando $*: hola mundo 123
Usando $@: hola mundo 123
```

Sin comillas, ambas variables se comportan de forma equivalente: bash las expande y luego vuelve a dividir el resultado en palabras separadas según los espacios, exactamente igual que si se hubiera escrito cada argumento por separado. La diferencia aparece al encerrar cada una entre comillas dobles, un hábito recomendable en general al trabajar con variables en bash, precisamente para evitar la división de palabras no deseada.

`"$*"` (con comillas) combina todos los argumentos en una única cadena de texto, separados por el primer carácter de la variable especial `$IFS` (que por defecto es un espacio), y ese resultado se trata como un solo argumento indivisible si se pasa a su vez a otro comando. `"$@"` (con comillas), en cambio, preserva cada argumento original como una entidad completamente separada e independiente, respetando incluso los espacios que pudiera haber dentro de un argumento individual, tal como fue originalmente recibido por el script.

```bash
#!/bin/bash
echo "--- Con \$* ---"
for arg in "$*"; do
  echo "Elemento: [$arg]"
done

echo "--- Con \$@ ---"
for arg in "$@"; do
  echo "Elemento: [$arg]"
done
```

```bash
❯ ./script.sh "hola mundo" prueba
--- Con $* ---
Elemento: [hola mundo prueba]
--- Con $@ ---
Elemento: [hola mundo]
Elemento: [prueba]
```

En este ejemplo se aprecia con claridad la diferencia: el script recibió únicamente dos argumentos (`"hola mundo"` como un solo argumento, gracias a las comillas al invocarlo, y `prueba` como el segundo), pero al iterar sobre `"$*"`, el bucle trata absolutamente todo como un único elemento combinado, mientras que al iterar sobre `"$@"`, el bucle respeta correctamente la separación original entre los dos argumentos, incluyendo el espacio interno del primero. Por este motivo, `"$@"` (siempre entre comillas dobles) es la forma recomendada y ampliamente adoptada como buena práctica cuando la intención de un script es reenviar, de forma fiel, la totalidad de sus propios argumentos hacia otro comando, sin correr el riesgo de que un argumento con espacios internos se fragmente incorrectamente.

## Otras variables relacionadas

Además de las variables descritas explícitamente en estas notas, bash ofrece otras dos igualmente relevantes al trabajar con argumentos posicionales y con la ejecución general de scripts. La variable `$?` contiene el código de salida del último comando ejecutado (ya visto en apuntes anteriores sobre operadores lógicos), y resulta especialmente relevante justo después de procesar argumentos, para comprobar si alguna validación o comando anterior tuvo éxito. El comando interno `shift`, por su parte, desplaza los argumentos posicionales una posición hacia la izquierda: lo que antes era `$2` pasa a ser `$1`, lo que antes era `$3` pasa a ser `$2`, y así sucesivamente, reduciendo además en uno el valor de `$#`; esto resulta muy útil para procesar argumentos de forma iterativa, uno por uno, sin necesidad de conocer de antemano cuántos serán ni de referenciarlos todos por su número exacto.

```bash
#!/bin/bash
while [ "$#" -gt 0 ]; do
  echo "Procesando: $1"
  shift
done
```

```bash
❯ ./script.sh uno dos tres
Procesando: uno
Procesando: dos
Procesando: tres
```

En este patrón, el bucle continúa mientras queden argumentos por procesar (`$# -gt 0`), trabaja siempre sobre `$1` (que en cada vuelta del bucle es un argumento distinto, gracias al desplazamiento producido por `shift`), y termina de forma natural en cuanto `shift` reduce `$#` a cero, sin necesidad de saber de antemano cuántos argumentos se recibirían en total. Este es, precisamente, el mismo patrón estructural que ya apareció al hablar del bucle `while [ $variable ]` en la descompresión recursiva y en otros ejemplos anteriores: aprovechar una condición que se agota de forma natural, en lugar de fijar de antemano un número exacto de iteraciones.
