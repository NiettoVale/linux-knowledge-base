# Diagnóstico, Shells Restringidas y Explotación de SUID/SGID

## diff: comparación de ficheros

El comando `diff` compara el contenido de dos archivos línea por línea y reporta exactamente en qué líneas difieren, mostrando tanto el contenido original como el contenido modificado. Su utilidad resulta evidente en escenarios donde dos versiones de un mismo archivo parecen, a simple vista, idénticas (por ejemplo, dos configuraciones de varios cientos de líneas, o dos versiones de un script antes y después de una modificación sospechosa), pero en realidad contienen cambios puntuales que serían prácticamente imposibles de detectar revisando el contenido manualmente línea por línea.

```bash
# Compara dos archivos y muestra únicamente las líneas
# que difieren entre ambos
diff archivo_original.txt archivo_modificado.txt

# Salida de ejemplo: el formato "a" indica "añadido",
# "c" indica "cambiado" (change), y "d" indica "eliminado" (delete)
# 3c3
# < Esta es la línea original
# ---
# > Esta es la línea modificada
```

La sintaxis de salida por defecto de `diff` sigue un formato compacto donde el número antes de la letra (`a`, `c` o `d`) indica la línea del primer archivo, la letra indica el tipo de cambio, y el número después de la letra indica la línea correspondiente en el segundo archivo; el contenido del primer archivo se marca con `<` y el del segundo con `>`, separados por una línea de guiones cuando se trata de un cambio. Existen además variantes de formato considerablemente más legibles para revisiones extensas, particularmente el formato unificado, ampliamente utilizado también por herramientas de control de versiones como Git.

```bash
# Formato unificado (-u), el más legible y el más habitual
# en el contexto de revisión de código y control de versiones
diff -u archivo_original.txt archivo_modificado.txt

# Ignora diferencias de mayúsculas/minúsculas al comparar
diff -i archivo1.txt archivo2.txt

# Ignora diferencias de espacios en blanco, útil cuando
# el contenido es idéntico pero la indentación cambió
diff -w archivo1.txt archivo2.txt

# Compara recursivamente el contenido completo de dos
# directorios, reportando qué archivos difieren entre ambos
diff -r directorio1/ directorio2/
```

Desde una perspectiva de ciberseguridad, `diff` resulta particularmente valioso en dos escenarios concretos. El primero es la detección de manipulaciones no autorizadas en archivos de configuración críticos: comparar el archivo actual de un sistema en producción contra una copia de referencia conocida y confiable (por ejemplo, `/etc/passwd`, `/etc/sudoers` o el propio `.bashrc` de una cuenta administrativa) permite detectar rápidamente si alguien introdujo un cambio malicioso o inesperado, algo que a simple vista, en un archivo de varias decenas o cientos de líneas, sería fácil pasar por alto. El segundo escenario, íntimamente relacionado con la siguiente sección de estas notas, es precisamente el de identificar qué se modificó en un archivo de inicio de shell (como `.bashrc`, `.bash_profile` o `.profile`) cuando una conexión SSH comienza a comportarse de forma anómala, comparándolo contra una versión de referencia del mismo archivo tomada de otra cuenta o de un sistema no comprometido.

## Recuperación de una shell cuando SSH "rebota"

Un escenario que aparece con cierta frecuencia, tanto en entornos de CTF como en sistemas reales mal configurados o deliberadamente endurecidos como medida de seguridad, es aquel en el que una conexión SSH se establece correctamente (la autenticación tiene éxito) pero la sesión se cierra inmediatamente después, sin llegar a entregar una shell interactiva utilizable. Este comportamiento suele deberse a que alguno de los archivos de inicio de la shell del usuario (típicamente `~/.bashrc`, `~/.bash_profile`, `~/.profile`, o incluso la propia shell configurada en `/etc/passwd` para ese usuario) ha sido modificado deliberadamente para ejecutar una instrucción que termina la sesión inmediatamente, como una llamada explícita a `exit`, o para apuntar a un intérprete que no es una shell interactiva funcional.

La razón técnica de este comportamiento reside en el propio funcionamiento de bash: cuando se inicia una sesión interactiva de login (como la que SSH crea por defecto), bash ejecuta automáticamente, antes de entregarle el control al usuario, uno o varios de estos archivos de inicio, en un orden concreto según el tipo exacto de shell que se esté abriendo. Si alguno de esos archivos contiene una instrucción que finaliza el proceso (como `exit 0` insertado deliberadamente al principio del archivo), la sesión SSH se cerrará antes de que el usuario tenga siquiera la oportunidad de escribir un solo comando, incluso habiéndose autenticado correctamente.

Una primera comprobación consiste en verificar si SSH sigue permitiendo la ejecución de un comando puntual, en lugar de una sesión interactiva completa, ya que la ejecución de un comando remoto específico (`ssh usuario@host "comando"`) no siempre dispara el mismo conjunto de archivos de inicio que una sesión de login interactiva completa.

```bash
# Ejecuta un único comando remoto sin abrir una sesión interactiva;
# en muchos casos, esto SÍ funciona correctamente incluso cuando
# la sesión interactiva normal se cierra inmediatamente
ssh usuario@maquina "whoami"
# El comando se ejecuta y devuelve su resultado, pero la conexión
# se cierra de todas formas justo después, ya que no se solicitó
# una sesión interactiva persistente
```

La solución práctica a este problema consiste en pedirle a SSH que ejecute directamente un nuevo intérprete de shell como "comando remoto", en lugar de dejar que se abra la sesión de login por defecto que dispara los archivos de inicio problemáticos. Al invocar `bash` de esta manera, se obtiene una nueva shell interactiva que no pasa por el mismo proceso de inicialización de una sesión de login completa (o que, dependiendo de la configuración exacta, sí ejecuta `.bashrc` pero sin que ello provoque el cierre inmediato, ya que el contexto de ejecución es distinto al de una sesión de login propiamente dicha).

```bash
# En lugar de conectar de forma normal (que dispara el archivo
# de inicio problemático y cierra la sesión), se le indica a SSH
# que ejecute directamente bash como si fuera un comando remoto
ssh usuario@maquina "bash"

# Esto entrega una sesión interactiva de bash, evitando el disparo
# automático de los archivos de inicio de sesión de login que
# estaban causando el cierre prematuro de la conexión
```

Una vez recuperado el acceso a una shell funcional de esta manera, el paso lógico siguiente es precisamente utilizar `diff` (visto en la sección anterior) para comparar el `.bashrc` o el archivo de inicio sospechoso contra una copia de referencia, e identificar con precisión qué línea fue la responsable del comportamiento anómalo, permitiendo tanto entender el problema como, si se cuenta con los permisos necesarios, corregirlo.

```bash
# Una vez dentro, se inspecciona el contenido del archivo
# de inicio sospechoso para localizar la línea problemática
cat ~/.bashrc

# Si se dispone de una copia de referencia de un .bashrc
# "limpio" (por ejemplo, de otra cuenta del mismo sistema
# o de un backup previo), diff permite localizar exactamente
# qué se añadió o modificó
diff ~/.bashrc /etc/skel/.bashrc
```

Este mismo patrón resulta relevante también en el terreno ofensivo: durante un ejercicio de post-explotación con fines de persistencia, un atacante podría insertar deliberadamente comandos maliciosos en los archivos de inicio de un usuario legítimo (de forma que se ejecuten automáticamente cada vez que ese usuario inicia sesión), y saber cómo obtener una shell "limpia" que evite disparar ese archivo modificado es precisamente la técnica que permite a un analista o a un administrador investigar el sistema sin activar, sin querer, la propia carga maliciosa que se está investigando.

## Explotación de binarios con SUID: relevancia en pentesting

Ya se ha cubierto en apuntes anteriores el funcionamiento técnico del permiso especial SUID (_Set owner User ID_) y de su equivalente orientado a grupos, SGID (_Set Group ID_), pero conviene profundizar aquí específicamente en por qué su hallazgo durante un ejercicio de pentesting se considera, casi literalmente, "oro puro" para quien está intentando escalar privilegios en un sistema comprometido.

El principio es directo: cuando un binario ejecutable tiene el bit SUID activado y su propietario es `root`, cualquier usuario del sistema que tenga permiso de ejecución sobre ese binario lo ejecutará con los privilegios efectivos de `root`, sin importar con qué usuario se haya iniciado sesión originalmente. Esto significa que, si dicho binario permite de alguna manera leer archivos arbitrarios, escribir archivos arbitrarios, o lo que resulta más crítico, ejecutar comandos arbitrarios (aunque sea de forma indirecta, a través de alguna funcionalidad interna del propio programa que no estaba pensada como una puerta trasera pero que puede abusarse con ese fin), un atacante con acceso a una cuenta de bajo privilegio puede aprovechar ese binario como palanca para obtener, en la práctica, una shell con privilegios administrativos completos.

```bash
# Localiza todos los binarios con el bit SUID activado
# en todo el sistema, ignorando los errores de permiso denegado
find / -perm -4000 -type f 2>/dev/null

# Salida de ejemplo: junto a los SUID esperables del propio
# sistema operativo (passwd, sudo, su, mount), puede aparecer
# ocasionalmente algún binario inusual o de terceros
/usr/bin/passwd
/usr/bin/sudo
/usr/bin/su
/usr/bin/mount
/usr/local/bin/backup_tool
```

El proceso habitual de enumeración consiste en obtener este listado y contrastar cada resultado contra GTFOBins (`gtfobins.github.io`), un catálogo curado de binarios Unix legítimos que documenta, para cada uno, si existe alguna forma conocida de abusar de su funcionalidad interna para ejecutar comandos arbitrarios cuando se encuentra bajo SUID, bajo una regla de `sudo`, o con capabilities asignadas. Muchos binarios completamente legítimos y de uso cotidiano (editores de texto, paginadores, intérpretes, herramientas de backup, utilidades de red) incorporan, por diseño, la capacidad de ejecutar comandos del sistema operativo como parte de alguna de sus funcionalidades normales (por ejemplo, un editor de texto que permite abrir una shell temporal sin cerrar el editor, una función pensada originalmente para comodidad del usuario), y es precisamente esa funcionalidad legítima la que se termina utilizando como vector de escalada de privilegios cuando el binario en cuestión tiene el bit SUID activado con propietario `root`.

```bash
# Ejemplo ilustrativo: si "find" tuviera el bit SUID activado
# con propietario root (una configuración insegura,
# pero documentada como posible en entornos reales mal
# configurados), su propia opción -exec puede abusarse
# para obtener una shell con privilegios de root
find /home -exec /bin/bash -p \; -quit

# La opción -p le indica a bash que no descarte los privilegios
# efectivos heredados del binario SUID, algo que bash hace
# por defecto como medida de seguridad al detectar que su UID
# real y su UID efectivo no coinciden
```

El nivel de peligro de un binario SUID mal configurado depende directamente de qué operaciones permite realizar. Un binario SUID que permite lectura arbitraria de archivos, aunque no llegue a otorgar una shell completa, ya representa un riesgo serio, ya que puede utilizarse para leer `/etc/shadow` y obtener los hashes de contraseñas del sistema para intentar romperlos posteriormente sin conexión. Un binario que permite escritura arbitraria resulta aún más crítico, ya que puede utilizarse para modificar `/etc/passwd` (por ejemplo, añadiendo una nueva entrada de usuario con UID `0`, equivalente a crear una cuenta adicional de `root`) o para sobrescribir `/etc/sudoers` otorgando privilegios completos de `sudo` a la cuenta actual. Y, como se ha visto, cualquier binario que permita, directa o indirectamente, la ejecución de comandos arbitrarios, constituye la vía más directa y menos elaborada hacia una escalada de privilegios completa.

## SGID como vector complementario

Aunque SUID acapara la mayor parte de la atención en materiales introductorios de escalada de privilegios, SGID no debe pasarse por alto durante una enumeración exhaustiva. Su alcance es, en principio, algo más acotado que el de SUID, ya que otorga los privilegios del grupo propietario del archivo en lugar de los del usuario propietario, pero esto sigue siendo relevante cuando el grupo en cuestión tiene acceso a recursos interesantes: por ejemplo, un binario SGID perteneciente al grupo `shadow` podría permitir la lectura de `/etc/shadow` incluso sin llegar a otorgar privilegios de `root` propiamente dichos, ya que ese grupo específico suele tener permiso de lectura sobre dicho archivo por diseño del propio sistema operativo.

```bash
# Localiza binarios con el bit SGID activado en todo el sistema
find / -perm -2000 -type f 2>/dev/null

# Es igualmente valioso combinar la búsqueda de SUID y SGID
# en una sola pasada, ya que ambos son igualmente relevantes
# durante la fase de enumeración de privesc
find / \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null
```

## Netcat: opciones avanzadas para conexiones temporales

Retomando y ampliando lo ya visto sobre Netcat, conviene profundizar en algunas opciones adicionales que resultan de gran utilidad tanto en tareas administrativas legítimas como durante un ejercicio de pentesting, particularmente al establecer conexiones puntuales y temporales que no deberían quedar abiertas indefinidamente ni comportarse de forma inesperada ante una desconexión del otro extremo.

```bash
# Recordatorio de la sintaxis básica de escucha temporal
nc -lvnp <puerto>
# l --> modo escucha (listen)
# v --> modo detallado (verbose)
# n --> sin resolución DNS
# p --> especifica el puerto local
```

Por defecto, cuando el cliente conectado a un servidor Netcat en modo escucha cierra su conexión, el propio proceso servidor de Netcat también finaliza, dejando de escuchar en ese puerto. Esto puede ser problemático quiere mantenerse una escucha persistente capaz de aceptar múltiples conexiones sucesivas sin tener que relanzar manualmente el comando cada vez. La opción `-k` (_keep listening_) resuelve precisamente esto, forzando a Netcat a seguir escuchando en el mismo puerto incluso después de que un cliente se desconecte.

```bash
# Mantiene el servidor escuchando de forma persistente,
# aceptando nuevas conexiones aunque la anterior se cierre
nc -k -lvnp 4444
```

Otra opción relevante es `-w`, que establece un tiempo límite (en segundos) de inactividad antes de que Netcat cierre automáticamente la conexión, evitando así que una conexión quede abierta indefinidamente por descuido, algo especialmente recomendable en scripts automatizados donde una conexión colgada podría bloquear la ejecución del resto del proceso.

```bash
# Cierra automáticamente la conexión tras 10 segundos
# de inactividad, evitando que quede abierta indefinidamente
nc -w 10 192.168.1.10 4444
```

Para trabajar explícitamente con IPv4 o IPv6, en lugar de dejar que Netcat elija automáticamente según la resolución disponible, las opciones `-4` y `-6` fuerzan el uso de una familia de direcciones concreta, lo cual resulta útil para depurar problemas de conectividad quy resultan específicos de una de las dos versiones del protocolo IP.

```bash
# Fuerza el uso de IPv4 tanto en el servidor como en el cliente
nc -4 -lvnp 4444
nc -4 192.168.1.10 4444

# Fuerza el uso de IPv6
nc -6 -lvnp 4444
```

Por último, para trabajar sobre UDP en lugar de TCP (el protocolo que Netcat utiliza por defecto), se añade la opción `-u`, y para ajustar cuánto tiempo espera Netcat antes de cerrar la conexión tras recibir un EOF (fin de archivo) por su entrada estándar, en lugar de cerrarla inmediatamente, se utiliza la opción `-q` seguida del número de segundos de espera deseado.

```bash
# Establece una conexión sobre UDP en lugar de TCP
nc -u -lvnp 4444
nc -u 192.168.1.10 4444

# Espera 5 segundos tras recibir un EOF antes de cerrar
# la conexión, en lugar de cerrarla de inmediato
nc -q 5 192.168.1.10 4444
```

Conocer estas opciones adicionales conviene tenerlas presentes especialmente al automatizar conexiones puntuales dentro de scripts de administración o de explotación: una conexión Netcat mal configurada, sin límite de tiempo ni comportamiento definido ante un EOF, puede quedar colgada de forma silenciosa y bloquear la ejecución del resto de un script, un problema sutil pero frecuente cuando se depende de esta herramienta como parte de un flujo de trabajo automatizado más amplio.
