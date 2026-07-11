# Linux Capabilities

## Introducción y motivación

Tradicionalmente, el modelo de seguridad de Unix y Linux distinguía únicamente entre dos categorías de procesos: los procesos privilegiados, ejecutados con UID 0 (el usuario `root`), que podían saltarse virtualmente cualquier comprobación de permisos del kernel, y los procesos no privilegiados, sujetos estrictamente a las comprobaciones de permisos habituales basadas en UID, GID y los bits de lectura, escritura y ejecución. Este modelo binario, aunque simple de razonar, presenta un problema evidente desde el punto de vista de la seguridad: numerosos programas legítimos necesitan realizar una única operación privilegiada muy concreta (por ejemplo, `ping` necesita abrir un socket de tipo `raw` para construir paquetes ICMP manualmente, algo que el kernel reserva por defecto a `root`), pero no tienen ninguna necesidad real del resto de superpoderes que implica ser root, como poder leer cualquier archivo del sistema, cargar módulos del kernel, o modificar la configuración de red global. Bajo el modelo clásico, la única forma de resolver esta necesidad era otorgarle al binario en cuestión el permiso especial SUID con propietario `root` (como efectivamente ocurre históricamente con `ping`), lo cual concede al proceso, mientras dura su ejecución, absolutamente todos los privilegios de `root`, muy por encima de lo que realmente necesita para cumplir su función.

Las capacidades de Linux (_Linux capabilities_), introducidas en el kernel a partir de la versión 2.2, nacen precisamente para resolver este problema de sobre-privilegio. La idea central consiste en descomponer el conjunto monolítico de privilegios que tradicionalmente poseía el usuario `root` en unidades más pequeñas e independientes, cada una de las cuales habilita un grupo concreto de operaciones privilegiadas del kernel. De este modo, en lugar de tener que elegir entre "todos los privilegios de root" o "ningún privilegio especial", es posible asignarle a un proceso o a un binario exactamente el subconjunto de privilegios que necesita para cumplir su función, y nada más. Siguiendo con el ejemplo de `ping`, en sistemas modernos este binario ya no requiere el bit SUID completo, sino que le basta con la capacidad `cap_net_raw`, que únicamente le permite crear sockets raw y sockets de paquete, sin otorgarle ningún otro privilegio adicional sobre el resto del sistema.

Este principio de descomponer privilegios en unidades mínimas y otorgar únicamente las estrictamente necesarias es una aplicación directa del principio de mínimo privilegio (_principle of least privilege_), uno de los pilares fundamentales del diseño de sistemas seguros. Desde la perspectiva de un pentester o un auditor de seguridad, comprender las capabilities resulta doblemente relevante: por un lado, representan una superficie de ataque legítima y bien documentada para la escalada de privilegios cuando están mal configuradas; por otro lado, su correcta implementación constituye una de las mejores prácticas recomendables al momento de dar recomendaciones de hardening tras una auditoría, en sustitución del uso indiscriminado de SUID o de reglas de `sudo` demasiado permisivas.

## Los conjuntos de capacidades (capability sets)

Para comprender realmente cómo funcionan las capabilities y, sobre todo, para poder interpretar correctamente la salida de herramientas como `getcap` o `capsh`, resulta imprescindible conocer que una capacidad no es simplemente un permiso que "está activado o no" para un proceso: en realidad, cada proceso en Linux mantiene varios conjuntos (_sets_) de capacidades distintos, cada uno con una semántica propia. Comprender esta distinción es fundamental, ya que muchas confusiones habituales en la explotación de capabilities provienen precisamente de no diferenciar correctamente entre estos conjuntos.

El conjunto **Permitted** (permitido) representa el límite superior de capacidades que un proceso puede llegar a utilizar. Una capacidad presente en este conjunto puede ser activada por el propio proceso en su conjunto Effective, pero una capacidad que no está en Permitted jamás podrá ser adquirida por el proceso, sin importar qué intente hacer. El conjunto **Effective** (efectivo) representa las capacidades que el kernel está utilizando activamente en este momento para decidir si autoriza o deniega una operación privilegiada; es, en la práctica, el conjunto que realmente importa a la hora de que una llamada al sistema tenga éxito o falle. Muchos binarios mantienen ciertas capacidades en Permitted pero las activan y desactivan dinámicamente en Effective según las necesiten en cada momento, siguiendo también el principio de mínimo privilegio a nivel interno del propio programa.

El conjunto **Inheritable** (heredable) determina qué capacidades puede transmitir un proceso a los programas que ejecute mediante llamadas de la familia `exec()`. Es importante remarcar que, por defecto, la mayoría de las capacidades no se heredan automáticamente al ejecutar un nuevo programa, precisamente para evitar que privilegios elevados se propaguen de forma descontrolada por todo el árbol de procesos; solo aquellas capacidades explícitamente marcadas como heredables, y que además el binario ejecutado tenga permiso de recibir, llegarán al nuevo proceso. El conjunto **Bounding** (delimitador) actúa como un techo global: ninguna capacidad puede añadirse jamás al conjunto Permitted, Effective o Inheritable de un proceso si no está presente en su Bounding set, lo cual lo convierte en un mecanismo de contención especialmente relevante en entornos como contenedores, donde limitar el Bounding set de un proceso reduce drásticamente lo que ese proceso podría llegar a hacer incluso si lograse ejecutar código arbitrario dentro de él.

Finalmente, el conjunto **Ambient** (ambiental), introducido en versiones más recientes del kernel, resuelve una limitación práctica del modelo clásico: permite que ciertas capacidades sobrevivan a través de un `exec()` hacia un programa que no tiene capacidades asociadas mediante `setcap`, siempre que dichas capacidades estén simultáneamente presentes en los conjuntos Permitted e Inheritable del proceso original. Este mecanismo resulta particularmente útil para servicios gestionados por `systemd`, que puede asignar capacidades ambientales a un servicio mediante la directiva `AmbientCapabilities` en su unidad, sin necesidad de modificar el binario del servicio en disco con `setcap`.

```bash
# Consulta las capacidades asignadas a un proceso en ejecución
# a través de su identificador de proceso (PID)
cat /proc/<PID>/status | grep Cap

# Salida de ejemplo, mostrando los distintos conjuntos en formato hexadecimal
CapInh: 0000000000000000
CapPrm: 0000000000003000
CapEff: 0000000000000000
CapBnd: 0000003fffffffff
CapAmb: 0000000000000000

# capsh permite decodificar esos valores hexadecimales a nombres legibles
capsh --decode=0000000000003000
```

## Herramientas de gestión: getcap, setcap y capsh

La gestión de capabilities sobre binarios en disco (a diferencia de las capacidades de un proceso en ejecución, que se consultan vía `/proc`) se realiza principalmente mediante dos utilidades incluidas en el paquete `libcap2-bin` (o su equivalente según la distribución): `getcap`, para consultar qué capacidades tiene asignado un archivo, y `setcap`, para asignárselas o retirárselas. Adicionalmente, la utilidad `capsh` resulta muy útil para inspeccionar y depurar las capacidades del propio shell actual o para lanzar procesos con un conjunto de capacidades restringido de forma controlada, algo especialmente valioso durante pruebas de hardening.

```bash
# Instala las herramientas de gestión de capabilities si no estuvieran presentes
sudo apt install libcap2-bin

# Consulta las capacidades de un binario específico
getcap /usr/bin/ping
# /usr/bin/ping cap_net_raw=ep

# Recorre recursivamente todo el sistema de archivos buscando
# binarios con alguna capability asignada, descartando errores
# de permisos denegados
getcap -r / 2>/dev/null

# Muestra las capacidades del shell/proceso actual de forma legible
capsh --print
```

La sintaxis de `setcap` merece explicarse con detalle, ya que su formato combina el nombre de la capacidad con una serie de letras que indican en qué conjunto se está aplicando. La forma general es `nombre_capacidad+flags`, donde las flags más habituales son `e` (Effective), `p` (Permitted) e `i` (Inheritable). Así, `cap_net_raw+ep` significa que se está otorgando la capacidad `cap_net_raw` tanto al conjunto Permitted como al Effective del binario, que es la combinación típica para que la capacidad esté disponible de inmediato al ejecutar el binario, sin que el propio programa tenga que activarla explícitamente por su cuenta.

```bash
# Otorga la capacidad cap_setuid a un binario, activándola tanto
# en Permitted como en Effective (ep), lo cual la deja lista para
# usarse inmediatamente al ejecutar el binario
sudo setcap cap_setuid+ep /home/soporte/python3

# Otorga varias capacidades simultáneamente, separadas por comas
sudo setcap cap_net_admin,cap_net_raw+eip /usr/bin/dumpcap

# Retira todas las capacidades asignadas a un binario
sudo setcap -r /usr/bin/ping

# Retira específicamente una capacidad, dejando el resto intactas
sudo setcap cap_net_raw-ep /usr/bin/ping
```

Es importante señalar que las capabilities asignadas mediante `setcap` se almacenan como un atributo extendido del sistema de archivos (concretamente, en el atributo `security.capability`), lo cual tiene una consecuencia práctica relevante: si el binario se copia a otra ubicación mediante herramientas que no preservan explícitamente los atributos extendidos, o si se transfiere a través de determinados protocolos de red o herramientas de compresión que no soportan xattrs, la capacidad asignada puede perderse silenciosamente en el proceso. Esto también implica que, a diferencia del bit SUID, las capabilities de un archivo no son visibles en la salida habitual de `ls -l`, por lo que su enumeración depende exclusivamente de herramientas específicas como `getcap`.

## Escenario práctico: preparación de un binario vulnerable

Para ilustrar de forma completa cómo una configuración de capabilities puede derivar en una escalada de privilegios, resulta útil recorrer un escenario habitual en entornos de CTF y HackTheBox, en el que un administrador del sistema, con la intención de evitar otorgar acceso completo a `sudo` o asignar el bit SUID a un binario, decide en su lugar utilizar capabilities para permitir que un usuario de soporte técnico pueda realizar una tarea administrativa concreta. El error, en este caso, radica en elegir una capacidad demasiado amplia para el propósito, o en asignarla sobre un binario capaz de ejecutar código arbitrario, como un intérprete de un lenguaje de scripting.

Supongamos que existe un usuario `soporte` sin privilegios administrativos, y que el administrador copia el binario de Python hacia su directorio personal para, supuestamente, permitirle ejecutar ciertos scripts de mantenimiento con privilegios elevados:

```bash
# El administrador copia el intérprete de Python al home del usuario soporte
cp /usr/bin/python3 /home/soporte/python3

# Y le asigna la capacidad cap_setuid, pensando que solo le permitirá
# realizar cambios de identidad puntuales dentro de un script controlado
setcap cap_setuid+ep /home/soporte/python3

# Se puede verificar que la capacidad quedó correctamente asignada
getcap /home/soporte/python3
# /home/soporte/python3 cap_setuid=ep
```

El problema de fondo es que `cap_setuid` no otorga un privilegio acotado a una tarea específica: otorga la capacidad de invocar la llamada al sistema `setuid()` y cambiar el UID efectivo del proceso a voluntad, incluyendo el UID 0 de `root`. Dado que el binario sobre el que se asignó esta capacidad es un intérprete completo de Python, capaz de ejecutar cualquier código arbitrario que se le indique, el usuario `soporte` en la práctica dispone de una vía directa y trivial hacia una shell con privilegios de `root`.

## Explotación: de la capability a la shell de root

Continuando con el escenario anterior, un atacante que hubiese obtenido acceso a la máquina con el usuario `soporte` (por ejemplo, mediante la explotación de un servicio expuesto o el robo de credenciales) llegaría, durante su fase de enumeración local, a localizar este binario y a identificar la capacidad que tiene asignada, típicamente mediante un recorrido recursivo del sistema de archivos:

```bash
# Enumeración de binarios con capabilities asignadas en todo el sistema
getcap -r / 2>/dev/null

# Resultado relevante para este escenario
/home/soporte/python3 = cap_setuid+ep
```

Tras confirmar que el binario pertenece a `root` mediante `ls -l /home/soporte/python3`, y comprobar que cualquier usuario tiene permiso de ejecución sobre él, el siguiente paso consiste en aprovechar la capacidad `cap_setuid` para invocar `setuid(0)` desde dentro de Python y, a continuación, generar una shell interactiva que hereda ese UID recién adquirido:

```bash
# Ejecuta el binario de Python con capacidad cap_setuid asignada,
# cambia el UID efectivo del proceso a 0 (root) y lanza una shell
./python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'

# La shell resultante reporta UID root, aunque el GID heredado
# sigue siendo el del usuario original (soporte), a menos que
# también se invoque setgid(0) de forma explícita
id
# uid=0(root) gid=1000(soporte) groups=1000(soporte)
```

Este patrón de explotación —abusar de un intérprete con `cap_setuid` para invocar directamente la llamada al sistema desde el propio lenguaje— se repite de forma prácticamente idéntica en otros intérpretes de scripting, cambiando únicamente la sintaxis correspondiente al lenguaje en cuestión:

```bash
# Perl con la capacidad cap_setuid asignada
perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/bash";'

# Ruby con la capacidad cap_setuid asignada
ruby -e 'Process::Sys.setuid(0); exec "/bin/bash"'

# Ejemplo equivalente utilizando Python para obtener también el GID de root
python3 -c 'import os; os.setuid(0); os.setgid(0); os.system("/bin/bash")'
```

## Otras capacidades peligrosas y sus vectores de explotación

Aunque `cap_setuid` es probablemente la capacidad más citada en materiales introductorios de escalada de privilegios, no es en absoluto la única que puede llevar a comprometer por completo un sistema. A continuación se detallan las capacidades más relevantes desde una perspectiva ofensiva, junto con ejemplos concretos de cómo abusarlas cuando aparecen asignadas a binarios que permiten ejecutar comandos o manipular archivos arbitrarios.

La capacidad `cap_dac_override` permite a un proceso saltarse por completo las comprobaciones de permisos discrecionales del sistema de archivos (lectura, escritura y ejecución basadas en los bits `rwx` tradicionales), lo cual significa en la práctica que puede leer, escribir o ejecutar cualquier archivo del sistema, sin importar los permisos que dicho archivo tenga asignados. Un binario con esta capacidad y capaz de escribir contenido arbitrario a un archivo (como un editor de texto) puede utilizarse para modificar directamente `/etc/passwd` o `/etc/shadow`:

```bash
# Con vim y cap_dac_override asignado, es posible escribir en /etc/shadow
# aunque el usuario actual no tenga permisos normales para hacerlo
vim /etc/shadow
# Dentro de vim: editar la línea de root para quitarle la contraseña,
# o reemplazar el hash por uno conocido generado previamente con openssl
```

La capacidad `cap_dac_read_search` es la contraparte orientada a lectura de la anterior: permite saltarse las comprobaciones de permisos de lectura y de búsqueda en directorios sobre cualquier archivo del sistema. Binarios de compresión o archivado, como `tar` o `zip`, resultan particularmente interesantes cuando tienen esta capacidad asignada, ya que permiten extraer el contenido de archivos normalmente inaccesibles:

```bash
# tar con cap_dac_read_search asignado puede empaquetar archivos
# a los que el usuario actual no tendría acceso de lectura normalmente
tar -cvf /tmp/shadow.tar /etc/shadow
tar -xvf /tmp/shadow.tar -C /tmp
cat /tmp/etc/shadow
```

Las capacidades `cap_chown` y `cap_fowner` permiten, respectivamente, cambiar el propietario de cualquier archivo del sistema y modificar sus permisos, sin las restricciones habituales que normalmente exigirían ser el propietario original o `root`. Un binario con `cap_chown` puede utilizarse para tomar posesión de `/etc/shadow`, cambiando su propietario al usuario actual, lo cual habilita su posterior modificación con herramientas normales:

```bash
# Con Python y cap_chown asignado, se cambia el propietario de
# /etc/shadow al UID y GID del usuario actual (por ejemplo 1000)
python3 -c 'import os; os.chown("/etc/shadow", 1000, 1000)'

# A partir de este punto, el archivo puede editarse directamente
# con las herramientas habituales, ya que el usuario pasa a ser su dueño
```

La capacidad `cap_setgid` es análoga a `cap_setuid` pero orientada al identificador de grupo: permite invocar `setgid()` y cambiar el GID efectivo del proceso, lo cual, combinada con pertenecer a grupos con permisos interesantes, o simplemente combinada con `cap_setuid` en el mismo binario, contribuye a una escalada de privilegios completa.

La capacidad `cap_sys_ptrace` habilita el uso de la llamada al sistema `ptrace()` sobre prácticamente cualquier proceso del sistema, independientemente de su propietario, lo cual permite inspeccionar y modificar la memoria de procesos ajenos, incluyendo procesos que se ejecutan como `root`. Esta capacidad resulta especialmente peligrosa porque habilita técnicas de inyección de código en procesos privilegiados en ejecución, permitiendo por ejemplo forzar a un proceso root a ejecutar una llamada al sistema arbitraria mediante herramientas especializadas como `gdb`.

La capacidad `cap_sys_admin` es, en la práctica, la más peligrosa y menos granular de todas las capacidades definidas por el kernel, hasta el punto de que suele describirse informalmente como "la nueva root" dentro de la comunidad de seguridad. Bajo esta única capacidad se agrupan un número muy elevado de operaciones administrativas dispares, entre ellas montar y desmontar sistemas de archivos arbitrarios, lo cual puede aprovecharse para montar el disco raíz del sistema dentro de un directorio accesible y, desde allí, modificar cualquier archivo sin restricción alguna, sorteando por completo el modelo de permisos habitual.

La capacidad `cap_sys_module` permite cargar y descargar módulos del kernel mediante `insmod` y `rmmod`. Dado que un módulo del kernel se ejecuta con el máximo nivel de privilegio posible dentro del sistema operativo (anillo 0), disponer de esta capacidad equivale, en la práctica, a poder ejecutar código arbitrario con privilegios totales sobre el kernel, lo cual convierte a esta capacidad en una de las más críticas de detectar durante una auditoría, ya que su explotación no se limita a comprometer el espacio de usuario sino el propio núcleo del sistema operativo.

La capacidad `cap_net_bind_service` permite a un proceso vincularse a puertos de red por debajo del 1024, tradicionalmente reservados a `root` por convención histórica de Unix. Aunque en sí misma no suele constituir una vía directa de escalada de privilegios, resulta relevante conocerla porque es una de las capacidades más comúnmente asignadas de forma legítima a servidores web y de aplicaciones que necesitan escuchar en el puerto 80 o 443 sin ejecutarse como `root`, representando así un ejemplo positivo del uso correcto de esta tecnología.

Finalmente, la capacidad `cap_setfcap` merece una mención especial, ya que permite a un proceso asignar capabilities a otros archivos del sistema mediante `setcap`, lo cual la convierte en una capacidad que, en la práctica, puede utilizarse para autoconcederse cualquier otra capacidad adicional sobre binarios propios o incluso del sistema, escalando de forma indirecta hacia cualquiera de los vectores descritos anteriormente.

## Enumeración sistemática y uso de GTFOBins

Durante una auditoría o un ejercicio de post-explotación, la enumeración de capabilities debería formar parte del mismo checklist que la búsqueda de binarios SUID, reglas de `sudo` y tareas programadas. El comando central para esta tarea es `getcap -r /`, complementado con `capsh --print` para inspeccionar el propio contexto de capacidades del proceso actual, algo especialmente relevante dentro de contenedores, donde el proceso inicial puede arrancar ya con un conjunto de capacidades no trivial heredado de la configuración del motor de contenedores.

```bash
# Enumeración estándar de capabilities en todo el sistema de archivos
getcap -r / 2>/dev/null

# Enumeración focalizada en rutas de binarios habituales,
# más rápida que recorrer todo el sistema de archivos
getcap -r /usr/bin /usr/sbin /bin /sbin 2>/dev/null

# Inspección de las capacidades del proceso/shell actual,
# útil especialmente dentro de contenedores Docker
capsh --print
```

Una vez identificado un binario con una capacidad interesante, el recurso de referencia obligado es GTFOBins (gtfobins.github.io), un catálogo curado de binarios Unix legítimos que documenta, para cada uno, las distintas formas en que puede ser abusado según el contexto en el que se encuentre (SUID, sudo, capabilities, entre otros). Es importante tener en cuenta un matiz práctico al consultar GTFOBins para capabilities: la sección específica de "Capabilities" de cada binario suele estar orientada casi exclusivamente a la capacidad `cap_setuid`, por lo que, si el binario identificado tiene asignada una capacidad distinta (como `cap_dac_read_search` o `cap_chown`), conviene en su lugar consultar las secciones generales de ese binario (por ejemplo, "File read" o "File write"), y razonar manualmente si la función descrita es compatible con la capacidad concreta que se ha encontrado, en lugar de descartar el binario únicamente por no aparecer explícitamente listado bajo capabilities.

## Recomendaciones de hardening y buenas prácticas defensivas

Desde la perspectiva de un administrador de sistemas o de un equipo de seguridad ofensiva encargado de emitir recomendaciones tras una auditoría, existen varias pautas concretas que reducen significativamente el riesgo asociado al uso de capabilities sin renunciar a sus beneficios legítimos frente al uso de SUID o `sudo` sin restricciones.

En primer lugar, resulta fundamental evitar asignar capacidades peligrosas, y en particular `cap_setuid`, `cap_setgid`, `cap_dac_override` o `cap_dac_read_search`, sobre binarios que sean intérpretes de propósito general (Python, Perl, Ruby, Node.js, PHP en modo CLI, etc.) o sobre herramientas capaces de ejecutar comandos arbitrarios a través de opciones o subcomandos internos (como muchos editores de texto, paginadores o herramientas de compresión). Estos binarios son, por diseño, capaces de ejecutar prácticamente cualquier instrucción que se les indique, lo cual anula por completo el objetivo original de granularidad que las capabilities pretenden ofrecer. Cuando se necesite otorgar una capacidad para una tarea administrativa concreta, la práctica recomendada consiste en escribir un binario propio, pequeño, auditado y de propósito único, que realice exactamente la operación privilegiada necesaria y nada más, y asignar la capacidad únicamente a ese binario específico, en lugar de a una herramienta genérica.

En segundo lugar, conviene aplicar el mismo principio de mínimo privilegio dentro de las propias capabilities: en lugar de asignar el conjunto completo `=ep` (que habilita la capacidad tanto en Permitted como en Effective de forma inmediata), cuando el binario lo soporte internamente resulta preferible asignar la capacidad únicamente al conjunto Permitted, dejando que sea el propio programa quien la active en Effective justo en el momento en que la necesita y la desactive inmediatamente después, reduciendo así la ventana temporal durante la cual el privilegio está realmente disponible para ser explotado en caso de que el binario tenga alguna otra vulnerabilidad.

En tercer lugar, en entornos que hacen uso de `systemd` para gestionar servicios, resulta preferible utilizar las directivas `AmbientCapabilities` y `CapabilityBoundingSet` dentro de la unidad del servicio, en lugar de aplicar `setcap` directamente sobre el binario en disco. Esta aproximación tiene la ventaja de que la asignación de privilegios queda documentada de forma centralizada y auditable en la configuración del propio servicio, y que el binario en disco permanece sin capacidades asignadas, por lo que si un atacante lograse copiarlo o ejecutarlo fuera del contexto controlado por `systemd`, no heredaría automáticamente ningún privilegio adicional.

```ini
# Fragmento de ejemplo de una unidad systemd (.service) que otorga
# la capacidad cap_net_bind_service de forma controlada y auditable,
# sin necesidad de aplicar setcap sobre el binario en disco
[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
```

En cuarto lugar, en entornos de contenedores (Docker, Podman, Kubernetes), la recomendación estándar de la industria es partir siempre de un Bounding set vacío y añadir explícitamente, una por una, únicamente las capacidades estrictamente necesarias para el funcionamiento de la aplicación, en lugar de confiar en el conjunto por defecto que el motor de contenedores asigna (el cual, aunque considerablemente más reducido que el de un proceso root nativo, sigue incluyendo capacidades como `cap_chown`, `cap_dac_override` o `cap_setuid` que rara vez son necesarias para la mayoría de las aplicaciones).

```bash
# Ejecuta un contenedor eliminando primero todas las capacidades
# por defecto y añadiendo únicamente la estrictamente necesaria
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE mi-imagen
```

Finalmente, tanto la asignación de capabilities como la aparición de binarios inesperados con capacidades asignadas deberían formar parte de las rutinas periódicas de auditoría de un sistema, de forma análoga a como ya se audita habitualmente la existencia de binarios con el bit SUID activado. Dado que las capabilities no son visibles mediante un `ls -l` convencional, su detección depende exclusivamente de ejecutar `getcap -r /` de forma programada y comparar el resultado contra una línea base conocida y aprobada, de manera que cualquier binario nuevo con una capacidad asignada (por ejemplo, tras la instalación de un paquete comprometido, o tras la manipulación directa de un atacante que ya obtuvo acceso) pueda ser detectado e investigado con prontitud, antes de que se convierta en un mecanismo de persistencia o en una vía de escalada de privilegios para un segundo actor.
