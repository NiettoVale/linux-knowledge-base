# Comandos Básicos de Linux para Ciberseguridad

## Introducción

Antes de abordar técnicas de explotación, post-explotación o escalada de privilegios, es fundamental dominar los comandos básicos que permiten comprender el estado de un sistema Linux: quién es el usuario actual, a qué grupos pertenece, cómo se resuelven las rutas de ejecución de binarios, y dónde se almacena la información de usuarios y grupos del sistema. Estos comandos, que a primera vista parecen triviales o puramente administrativos, constituyen en realidad la base de cualquier fase de reconocimiento interno (post-explotación) durante un ejercicio de hacking ético o una prueba de penetración. Cuando un pentester obtiene acceso a un sistema, ya sea mediante la explotación de una vulnerabilidad, el abuso de credenciales débiles o la ejecución de código remoto, el primer paso lógico no es intentar escalar privilegios a ciegas, sino comprender exhaustivamente el contexto en el que se encuentra: qué usuario es, qué permisos tiene asignados, qué grupos lo habilitan a realizar determinadas acciones, y qué configuraciones del entorno podrían representar una vía de escalada. Este proceso, conocido habitualmente como _enumeración local_, depende en gran medida del dominio de los comandos que se explican a continuación, y suele ser la diferencia entre quedar atrapado con un acceso de bajo privilegio y lograr comprometer completamente el sistema.

## Identidad del usuario en el sistema

El comando `whoami` devuelve únicamente el nombre del usuario con el que se está ejecutando la sesión actual, sin brindar información adicional sobre sus permisos o pertenencias a grupos. Por su parte, `id` resulta considerablemente más informativo, ya que muestra el UID (identificador numérico único que el kernel utiliza internamente para representar al usuario), el GID del grupo primario (aquel al que pertenece por defecto todo archivo o proceso creado por dicho usuario) y, adicionalmente, la lista completa de grupos secundarios de los que forma parte. Esta distinción entre grupo primario y grupos secundarios es relevante porque el sistema de permisos de Linux evalúa ambos al determinar si un usuario puede acceder a un recurso determinado.

```bash
# Muestra el nombre del usuario actual
❯ whoami
fnieto

# Muestra el UID, GID principal y todos los grupos secundarios del usuario
❯ id
uid=1000(fnieto) gid=1002(fnieto) grupos=1002(fnieto),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),101(netdev),103(scanner),112(bluetooth),117(lpadmin),1000(docker),1001(podman)
```

Conocer los grupos a los que pertenece un usuario resulta especialmente relevante en auditorías de seguridad, ya que ciertos grupos otorgan permisos que, aunque no equivalen directamente a ser `root`, pueden ser abusados mediante técnicas conocidas para alcanzar privilegios equivalentes. Por ejemplo, pertenecer al grupo `docker` habitualmente permite montar el sistema de archivos raíz dentro de un contenedor con privilegios elevados y así obtener acceso como `root` en el host; pertenecer al grupo `disk` puede permitir leer directamente los dispositivos de bloque del sistema; y, como se detalla a continuación, pertenecer al grupo `sudo` habilita, en la mayoría de los casos, una vía directa y explícita hacia privilegios administrativos completos. Por este motivo, revisar la salida de `id` suele ser uno de los primeros pasos que realiza un atacante o un auditor al obtener una shell en un sistema comprometido.

## El grupo sudo y la escalada de privilegios

El usuario `root` es el superusuario del sistema operativo: a diferencia del resto de las cuentas, no está sujeto a las restricciones habituales del modelo de permisos de Linux, y por lo tanto puede leer, escribir o ejecutar cualquier archivo, así como modificar la configuración del kernel, gestionar dispositivos, y administrar el resto de los usuarios sin limitación alguna. Pertenecer al grupo `sudo` no convierte automáticamente a un usuario en `root`, pero sí significa que dicho usuario está autorizado, según la configuración definida en `/etc/sudoers`, a ejecutar comandos con privilegios de `root` anteponiendo la palabra clave `sudo`, siempre que se autentique correctamente (habitualmente reingresando su propia contraseña, aunque esto puede variar según la política configurada).

Desde la perspectiva de un pentester, formar parte del grupo `sudo` —o encontrar durante la fase de enumeración una vía para incorporar al usuario comprometido a dicho grupo, por ejemplo explotando una vulnerabilidad de escalada local— representa la culminación de una escalada de privilegios exitosa, ya que otorga control prácticamente absoluto sobre el sistema comprometido. Con este nivel de acceso resulta posible instalar puertas traseras persistentes, exfiltrar información sensible almacenada en cualquier ubicación del sistema, modificar binarios legítimos para insertar código malicioso, e incluso borrar rastros de la intrusión manipulando registros de auditoría, todas ellas acciones que en condiciones normales estarían restringidas a un usuario sin privilegios.

```bash
# Muestra el contenido de /etc/shadow, archivo que almacena los hashes
# de las contraseñas del sistema y al que normalmente solo root
# tiene permiso de lectura
sudo cat /etc/shadow

# Abre una sesión interactiva como root, reemplazando efectivamente
# el usuario actual por el superusuario del sistema
sudo su

# Cierra la sesión de root y retorna a la sesión del usuario original
exit
```

Resulta importante destacar que, tras autenticarse correctamente al ejecutar `sudo` por primera vez, el sistema almacena de forma temporal un denominado _privilege token_ (gestionado internamente mediante un archivo de marca de tiempo asociado a la sesión). Este mecanismo evita que el usuario deba reingresar su contraseña en cada invocación posterior de `sudo` durante un intervalo de tiempo determinado, típicamente unos pocos minutos, cuya duración exacta puede configurarse mediante la directiva `timestamp_timeout` en `/etc/sudoers`. Esta característica también tiene implicancias ofensivas: si un atacante logra ejecutar código en una sesión donde este token todavía es válido, puede invocar `sudo` sin necesidad de conocer la contraseña del usuario legítimo.

## El fichero /etc/group

El archivo `/etc/group` funciona como la base de datos local en la que el sistema almacena la definición de todos los grupos existentes, ya sean grupos del sistema (asociados a servicios o componentes internos) o grupos creados manualmente por un administrador. Cada entrada de este archivo describe el nombre del grupo, su identificador numérico (GID) y, opcionalmente, la lista de usuarios que forman parte de él como miembros secundarios, es decir, usuarios cuyo grupo primario es distinto pero que igualmente heredan los permisos asociados a ese grupo.

```bash
cat /etc/group

1 │ root:x:0:
2 │ daemon:x:1:
3 │ bin:x:2:
4 │ sys:x:3:
5 │ adm:x:4:
6 │ tty:x:5:
7 │ disk:x:6:
8 │ lp:x:7:
9 │ mail:x:8:
```

Cada línea del archivo sigue el formato `nombre_grupo:contraseña:GID:lista_de_usuarios`, separados por dos puntos. El segundo campo, correspondiente a la contraseña del grupo, prácticamente nunca se utiliza en sistemas modernos: se representa mediante una `x` que indica que, de existir, el mecanismo real de autenticación se delega a otro componente del sistema. El último campo, cuando no está vacío, lista separados por comas los nombres de los usuarios que pertenecen a ese grupo como miembros secundarios, información que resulta directamente consultable también mediante el comando `id` para un usuario específico.

## Variables de entorno y la variable PATH

Las variables de entorno son valores nombrados que el shell y los distintos programas que se ejecutan dentro de una sesión pueden consultar en tiempo de ejecución para determinar comportamientos o configuraciones del sistema, sin necesidad de que dichos valores estén codificados directamente en cada programa. Existen numerosas variables de entorno predefinidas en cualquier sistema Linux, pero una de las más relevantes, tanto desde el punto de vista operativo como de seguridad, es `$PATH`. Esta variable contiene una lista de directorios, separados por dos puntos, en los que el shell realiza una búsqueda secuencial cada vez que se invoca un comando sin especificar explícitamente su ruta completa. La búsqueda se efectúa en el orden exacto en que los directorios aparecen listados, de izquierda a derecha, y se detiene apenas se encuentra la primera coincidencia, ejecutando ese binario e ignorando cualquier otro con el mismo nombre que pudiera existir en directorios posteriores de la lista.

```bash
# Muestra el contenido de la variable PATH
echo $PATH
/home/fnieto/.local/bin:/home/fnieto/.nvm/versions/node/v24.18.0/bin:/home/fnieto/.local/bin/scripts:/opt/kitty/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/sbin/
```

Para comprender en profundidad el funcionamiento de `$PATH`, resulta ilustrativo analizar el comportamiento del comando `whoami`. Al invocarlo simplemente escribiendo `whoami`, sin ninguna ruta adicional, el shell no tiene de antemano ningún conocimiento sobre la ubicación exacta de ese binario dentro del sistema de archivos. Sin embargo, el ejecutable existe físicamente en la ruta `/usr/bin/whoami`, y dado que el directorio `/usr/bin` forma parte de los directorios listados en `$PATH`, el shell logra localizarlo automáticamente durante su búsqueda secuencial y lo ejecuta, sin que el usuario necesite conocer ni escribir su ubicación absoluta.

Esta variable, más allá de su utilidad práctica evidente, tiene implicancias de seguridad considerables que suelen aprovecharse activamente en escenarios de escalada de privilegios. Si, por algún error de configuración, un directorio con permisos de escritura para un usuario sin privilegios se encuentra ubicado al inicio del `$PATH` de un usuario con mayores privilegios (por ejemplo, dentro de un script que se ejecuta periódicamente como `root`), un atacante podría colocar en ese directorio un binario malicioso con el mismo nombre que un comando legítimo utilizado por dicho script. Cuando el script se ejecute, el shell encontrará primero el binario malicioso durante su búsqueda en `$PATH` y lo ejecutará en lugar del comando original, otorgando así al atacante la posibilidad de ejecutar código arbitrario con los privilegios del usuario que ejecuta el script. Esta técnica se conoce comúnmente como _PATH hijacking_ y constituye uno de los vectores clásicos de escalada de privilegios en entornos Linux mal configurados.

Además de `$PATH`, existen otras variables de entorno de uso muy frecuente durante la administración y exploración de un sistema, como `$HOME`, que almacena la ruta absoluta del directorio personal asociado al usuario actualmente autenticado, y que suele emplearse internamente por múltiples programas para localizar archivos de configuración personales.

```bash
# Muestra el directorio personal (home) del usuario actual
echo $HOME
```

## El fichero /etc/passwd

El archivo `/etc/passwd` constituye el registro central de todas las cuentas de usuario configuradas en el sistema, ya sean cuentas destinadas a personas reales que inician sesión de forma interactiva, o cuentas de servicio empleadas internamente por distintos procesos y demonios del sistema operativo. Por cada usuario registrado, este archivo almacena información como su identificador numérico (UID), el identificador de su grupo primario (GID), un campo de comentario habitualmente utilizado para describir el propósito de la cuenta, la ruta a su directorio personal, y la shell que se le asigna por defecto al momento de iniciar una sesión.

```bash
cat /etc/passwd
1  │ root:x:0:0:root:/root:/bin/zsh
2  │ daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
3  │ bin:x:2:2:bin:/bin:/usr/sbin/nologin
4  │ sys:x:3:3:sys:/dev:/usr/sbin/nologin
5  │ sync:x:4:65534:sync:/bin:/bin/sync
6  │ games:x:5:60:games:/usr/games:/usr/sbin/nologin
7  │ man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
8  │ lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
9  │ mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
10 │ news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
11 │ uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
```

Cada línea del archivo sigue el formato `usuario:contraseña:UID:GID:comentario:directorio_home:shell`, con sus campos separados por dos puntos. El campo correspondiente a la contraseña, al igual que ocurre en `/etc/group`, se representa habitualmente mediante una `x`, lo cual indica que el hash real de la contraseña no se almacena en este archivo (que es legible por cualquier usuario del sistema por razones históricas de compatibilidad), sino en `/etc/shadow`, un archivo separado cuyo acceso de lectura está restringido exclusivamente a `root` o a usuarios con privilegios equivalentes. Esta separación entre `/etc/passwd` y `/etc/shadow`, introducida hace décadas mediante el mecanismo conocido como _shadow passwords_, existe precisamente para evitar que cualquier usuario del sistema pueda acceder a los hashes de contraseñas y someterlos a ataques de fuerza bruta o de diccionario fuera de línea. Por otra parte, la shell asignada a cada cuenta constituye un dato particularmente relevante durante una auditoría de seguridad, ya que revela de forma directa qué cuentas del sistema están efectivamente habilitadas para iniciar una sesión interactiva y cuáles, por el contrario, son cuentas de servicio configuradas explícitamente con una shell como `/usr/sbin/nologin` o `/bin/false`, precisamente para impedir que puedan utilizarse para iniciar sesión.

### Rutas absolutas frente a rutas relativas

Las rutas absolutas son aquellas que describen la ubicación de un archivo o directorio partiendo siempre desde la raíz del sistema de archivos, representada por el carácter `/`, y detallando de forma completa cada uno de los directorios intermedios que deben recorrerse hasta llegar al recurso deseado. Una ruta absoluta es, por definición, siempre válida sin importar cuál sea el directorio en el que se encuentre posicionado el usuario en el momento de utilizarla, ya que no depende de ningún contexto adicional. Las rutas relativas, en cambio, se definen tomando como punto de partida el directorio de trabajo actual, motivo por el cual una misma ruta relativa puede apuntar a recursos completamente distintos según desde dónde se ejecute. Para expresar rutas relativas se emplean además dos notaciones especiales heredadas de Unix: el punto simple (`.`), que hace referencia al directorio en el que el usuario se encuentra actualmente posicionado, y el punto doble (`..`), que hace referencia al directorio inmediatamente superior en la jerarquía, es decir, al directorio padre del directorio actual.

```bash
# Ruta absoluta: parte desde la raíz del sistema de archivos,
# independientemente de dónde esté posicionado el usuario
/usr/bin/cat /etc/group

# Ruta relativa equivalente, resuelta automáticamente mediante $PATH
cat /etc/group

# Ruta absoluta hacia un directorio específico
cd /home/fnieto/Desktop

# Ruta relativa, válida únicamente si el directorio de trabajo
# actual es /home/fnieto
cd ./Desktop
```

## Comandos complementarios de uso frecuente

Más allá de los comandos ya mencionados, existe un conjunto reducido pero fundamental de utilidades que se emplean de forma constante durante la exploración inicial de cualquier sistema Linux. El comando `cat` (abreviatura de _concatenate_) permite leer y volcar por la salida estándar el contenido completo de uno o varios archivos de texto, resultando indispensable para inspeccionar archivos de configuración o registros del sistema. El comando `echo` imprime por consola el texto o el valor de una variable que se le indique como argumento, y suele emplearse tanto para depurar scripts como para consultar rápidamente variables de entorno. El operador `|`, conocido como _pipe_ o tubería, permite encadenar comandos tomando la salida estándar generada por el comando ubicado a su izquierda y entregándola directamente como entrada estándar al comando ubicado a su derecha, lo cual habilita la construcción de flujos de procesamiento de datos combinando herramientas simples. Finalmente, `grep` (acrónimo derivado de _global regular expression print_) permite filtrar, entre un conjunto de líneas de texto, únicamente aquellas que coincidan con un patrón determinado, ya sea una cadena literal o una expresión regular.

```bash
# Lee el contenido de /etc/group y filtra únicamente las líneas
# que contengan la palabra "floppy", mostrando también el número
# de línea correspondiente gracias a la opción -n
❯ cat /etc/group | grep -nE "floppy"
19:floppy:x:25:fnieto
```

El comando `which` permite consultar la ruta completa del binario que efectivamente se ejecutaría al invocar un comando determinado, o bien indicar si dicho comando se encuentra definido como un alias en el shell actual, resultando de gran utilidad para confirmar la existencia de un comando en el sistema y, en escenarios de post-explotación, para verificar rápidamente qué herramientas están disponibles en un entorno comprometido. Sin embargo, `which` no siempre está disponible, particularmente en distribuciones minimalistas o en entornos de contenedores reducidos, por lo cual una alternativa considerablemente más portable, dado que forma parte del estándar POSIX y suele estar integrada directamente en el propio shell, es el comando `command -v`.

```bash
# Consulta la ruta o el alias asociado al comando "cat"
❯ which cat
cat: aliased to bat

# Alternativa equivalente, más portable entre distintos entornos
# y disponible incluso cuando "which" no lo está
❯ command -v cat
alias cat=bat
```

El comando `ls`, cuyo nombre deriva de _List directory_, permite listar el contenido de un directorio determinado, o del directorio actual si no se especifica ninguno. Su comportamiento por defecto resulta bastante limitado, por lo que suele combinarse con distintas opciones según la información que se necesite obtener: la opción `-l` presenta la salida en un formato detallado que incluye permisos, propietario, grupo, tamaño en bytes y fecha de última modificación de cada elemento; la opción `-a` amplía el listado incluyendo también los archivos y directorios ocultos, es decir, aquellos cuyo nombre comienza con un punto y que normalmente el sistema omite mostrar; y la opción `-h`, utilizada en conjunto con `-l`, convierte los tamaños de archivo a un formato legible para humanos, expresándolos en kilobytes, megabytes o gigabytes según corresponda, en lugar de mostrarlos siempre en bytes.

```bash
# Lista el contenido del directorio actual, sin detalles adicionales
❯ ls
01-comandos-basicos.md

# Lista en formato detallado, incluyendo archivos ocultos
❯ ls -la
total 8
drwxrwxr-x 1 fnieto fnieto   60 jul  1 04:28 .
drwxrwxr-x 1 fnieto fnieto   98 jun 30 18:04 ..
-rw-rw-r-- 1 fnieto fnieto 4112 jul  1 04:48 01-comandos-basicos.md
-rw-rw-r-- 1 fnieto fnieto    0 jun 30 17:58 .gitkeep

# Igual que el comando anterior, pero con tamaños en formato legible
❯ ls -lah
total 8,0K
drwxrwxr-x 1 fnieto fnieto   60 jul  1 04:28 .
drwxrwxr-x 1 fnieto fnieto   98 jun 30 18:04 ..
-rw-rw-r-- 1 fnieto fnieto 4,1K jul  1 04:48 01-comandos-basicos.md
-rw-rw-r-- 1 fnieto fnieto    0 jun 30 17:58 .gitkeep
```

Finalmente, el comando `pwd`, cuyo nombre deriva de _Print Working Directory_, devuelve la ruta absoluta correspondiente al directorio en el que se encuentra posicionado actualmente el usuario dentro de la sesión de shell. Aunque se trata de un comando extremadamente sencillo, resulta de utilidad constante para mantener la orientación durante la navegación por el sistema de archivos, especialmente en sesiones remotas o en scripts donde el directorio de trabajo puede no ser evidente a simple vista.

```bash
# Muestra la ruta absoluta del directorio de trabajo actual
❯ pwd
/home/fnieto/Desktop/github/06-linux-knowledge-base/docs
```
