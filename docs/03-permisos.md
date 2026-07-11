# Permisos en Linux

## Introducción

El sistema de permisos es uno de los pilares fundamentales de la seguridad en Linux, ya que determina de forma granular quién puede leer, modificar o ejecutar cada archivo y cada directorio del sistema. Para un pentester o auditor de seguridad, comprender a fondo este mecanismo resulta indispensable: una mala configuración de permisos, un binario con privilegios elevados mal asignado, o un directorio con permisos excesivamente permisivos pueden convertirse en la puerta de entrada perfecta para una escalada de privilegios. Antes de profundizar en la asignación y notación de permisos, conviene repasar brevemente algunos comandos básicos para la creación y eliminación de archivos, ya que serán utilizados constantemente a lo largo de los ejemplos.

Para crear un archivo vacío se emplea el comando `touch`, mientras que para crear un archivo con contenido resulta más práctico utilizar `echo` junto con un operador de redirección. Para eliminar archivos se utiliza `rm`, y para eliminar directorios de forma recursiva (incluyendo todo su contenido) se agrega la opción `-r`.

```bash
# Redirige "Hola mundo" hacia fichero.txt, sobrescribiendo su contenido
echo "Hola mundo" > fichero.txt

# Agrega "Hola mundo" al final del archivo, sin sobrescribir lo existente
echo "Hola mundo" >> fichero.txt

# Elimina el archivo fichero.txt
rm fichero.txt

# Elimina un directorio y todo su contenido de forma recursiva
rm -r directorio
```

## Lectura e interpretación de permisos

En Linux, cada archivo y cada directorio tiene asociados tres tipos de permisos básicos: lectura (`read`, representada con la letra `r`), escritura (`write`, representada con la letra `w`) y ejecución (`execute`, representada con la letra `x`). Estos tres permisos se aplican de manera independiente a tres categorías de usuarios distintas: el propietario del archivo, el grupo propietario del archivo, y el resto de los usuarios del sistema, comúnmente denominados "otros". Esta estructura tripartita es la que se observa al listar un archivo con `ls -l`, donde los permisos aparecen representados mediante una cadena de diez caracteres, en la que el primero indica el tipo de elemento (`-` para archivo regular, `d` para directorio) y los nueve restantes se agrupan en tres bloques de tres caracteres cada uno, correspondientes respectivamente al propietario, al grupo y a otros.

```bash
❯ ls -la
.rw-rw-r-- fnieto fnieto  11 B Wed Jul  1 16:02:15 2026  fichero.txt
```

En este ejemplo, el archivo `fichero.txt` presenta la siguiente distribución de permisos: el primer bloque, correspondiente al propietario, es `rw-`; el segundo bloque, correspondiente al grupo, es también `rw-`; y el tercer bloque, correspondiente a otros, es `r--`. Traducido a un lenguaje más concreto, esto significa que el propietario del archivo (en este caso, `fnieto`) puede leerlo y escribirlo pero no ejecutarlo; los usuarios que pertenecen al grupo propietario del archivo tienen exactamente los mismos permisos que el propietario, es decir, pueden leerlo y escribirlo; y cualquier otro usuario del sistema, ajeno tanto al propietario como al grupo, únicamente puede leer el contenido del archivo, sin poder modificarlo ni ejecutarlo.

## Asignación de permisos

Para comprender en profundidad cómo se asignan y modifican los permisos, resulta útil recorrer un ejemplo práctico paso a paso. Supongamos que, como usuario `root`, se crea un directorio llamado `prueba`, el cual queda con los siguientes permisos por defecto:

```bash
❯ ls -l
drwxr-xr-x root root 0 B Mon Jul  6 05:31:36 2026 prueba
```

En este caso, tanto el propietario como el grupo propietario del directorio son `root`. Si el usuario `fnieto` intenta interactuar con este directorio, se encuentra en la categoría de "otros", y los permisos indican que dicha categoría únicamente puede leer y ejecutar (es decir, listar contenido y acceder al directorio), pero no puede escribir en él, lo cual implica que no puede crear archivos ni subdirectorios dentro de `prueba`.

```bash
❯ touch file.txt
touch: no se puede efectuar `touch' sobre 'file.txt': Permiso denegado

❯ mkdir tests
mkdir: cannot create directory ‘tests’: Permiso denegado
```

Para modificar estos permisos se utiliza el comando `chmod` (change mode), el cual permite alterar los permisos de lectura, escritura y ejecución de forma selectiva sobre cualquiera de las tres categorías (propietario, grupo u otros). En el siguiente ejemplo se le otorga permiso de escritura a la categoría "otros" sobre el directorio `prueba`:

```bash
❯ chmod o+w prueba
drwxr-xrwx root root 0 B Mon Jul  6 05:31:36 2026 prueba
```

Ahora bien, si en lugar de otorgarle permiso de escritura a "otros" se quisiera que fuera específicamente el grupo `fnieto` el que tuviera esa capacidad, primero sería necesario cambiar el grupo propietario del directorio, reemplazando `root` por el grupo deseado. Para esto se utiliza el comando `chgrp` (change group), y posteriormente se ajustan los permisos del grupo con `chmod`:

```bash
❯ chgrp fnieto prueba
drwxr-xr-x root fnieto 0 B Mon Jul  6 05:31:36 2026 prueba

❯ chmod g+w prueba   # Asigna permiso de escritura al grupo
drwxrwxr-x root fnieto 0 B Mon Jul  6 05:31:36 2026 prueba

# Al pasar a ser el usuario fnieto, ahora sí puede crear archivos y directorios
❯ touch file.txt
❯ mkdir tests
drwxrwxr-x fnieto fnieto 0 B Mon Jul  6 05:40:30 2026 tests
.rw-rw-r-- fnieto fnieto 0 B Mon Jul  6 05:40:27 2026 file.txt
```

El comando `chmod` permite además modificar varios permisos simultáneamente en una sola línea, siguiendo una sintaxis simbólica bien definida. Esta sintaxis se compone de tres elementos: en primer lugar, la categoría sobre la que se quiere actuar, representada mediante `u` para el usuario propietario, `g` para el grupo, y `o` para otros (pudiendo combinarse o utilizar `a` para referirse a las tres categorías a la vez); en segundo lugar, el operador que indica la acción a realizar, siendo `+` para agregar un permiso y `-` para quitarlo; y en tercer lugar, la letra correspondiente al permiso que se desea modificar (`r`, `w` o `x`).

Por ejemplo, si se quisiera dejar al directorio `prueba` con los permisos `rw---x---`, es decir, lectura y escritura para el propietario, ningún permiso para el grupo, y únicamente ejecución para otros, podría lograrse de la siguiente manera:

```bash
drwxrwxr-x root fnieto 0 B Mon Jul  6 05:31:36 2026 prueba
❯ chmod u-x,g-wr,o-wrx prueba
drw---x--- root fnieto 26 B Mon Jul  6 05:40:30 2026 prueba
```

### Creación y administración de usuarios y grupos

La gestión de permisos está estrechamente vinculada a la gestión de usuarios y grupos, ya que en definitiva son estos los sujetos sobre los que recaen los permisos definidos en cada archivo. Para crear un nuevo usuario se utiliza el comando `useradd`, y es una buena práctica especificar explícitamente, en el mismo comando, tanto el directorio personal del usuario (mediante la opción `-d`) como la shell que se le asignará por defecto (mediante la opción `-s`), en lugar de dejar que el sistema aplique valores por defecto que podrían no ser los deseados.

```bash
❯ useradd asta -s /usr/bin/zsh -d /home/asta
❯ cat /etc/passwd | grep "asta"
asta:x:1002:1007::/home/asta:/usr/bin/zsh
❯ cat /etc/group | grep "asta"
asta:x:1007:
```

Nótese que, al crear el usuario `asta`, el sistema automáticamente genera además un grupo propio con el mismo nombre, lo cual constituye el comportamiento por defecto en la mayoría de las distribuciones modernas (un esquema conocido como _user private group_). Para asignarle una contraseña al usuario recién creado se utiliza el comando `passwd`, seguido del nombre de usuario:

```bash
❯ passwd asta
Nueva contraseña:
Vuelva a escribir la nueva contraseña:
passwd: contraseña actualizada correctamente
```

Un detalle importante a tener en cuenta es que, si el usuario `asta` fue creado por `root`, el directorio personal de `asta` pertenece inicialmente a `root` tanto en cuanto a propietario como a grupo, ya que fue el propio `root` quien lo creó durante el proceso de `useradd`. Esto puede corregirse fácilmente con `chgrp`, o de forma más completa (cambiando propietario y grupo en una sola operación) con el comando `chown` (change owner):

```bash
drwxr-xr-x root   root     0 B  Mon Jul  6 05:51:59 2026 asta
❯ chgrp asta asta
drwxr-xr-x root   asta     0 B  Mon Jul  6 05:51:59 2026 asta

# Forma más directa: cambia propietario y grupo en una sola instrucción
❯ chown asta:root asta
drwxr-xr-x asta   root     0 B  Mon Jul  6 05:51:59 2026 asta
```

Además de `useradd`, existen otros comandos fundamentales para la administración de cuentas: `groupadd` permite crear un nuevo grupo en el sistema, mientras que `usermod` permite modificar atributos de un usuario ya existente, como por ejemplo agregarlo a un grupo adicional mediante la combinación de opciones `-a -G` (donde `-a` significa "append", es decir, agregar sin eliminar las pertenencias a otros grupos, y `-G` especifica el grupo secundario a añadir).

```bash
❯ groupadd lideres
❯ cat /etc/group | grep "lideres"
lideres:x:1008:

❯ usermod -a -G lideres asta
❯ cat /etc/group | grep "lideres"
lideres:x:1008:asta
```

## Notación de permisos: simbólica y octal

Existen dos notaciones equivalentes para representar los permisos de un archivo o directorio: la notación simbólica, que es la que se ha utilizado hasta ahora (`rwx`, `r--`, etc.), y la notación octal, que expresa los mismos permisos mediante números del 0 al 7. El nombre "octal" proviene precisamente de que se trata de un sistema numérico en base 8, en el cual cada dígito puede tomar uno de ocho valores posibles. Aunque a primera vista esta notación puede parecer más abstracta y difícil de interpretar que la simbólica, en la práctica resulta mucho más rápida de utilizar una vez que se comprende la lógica subyacente, y es la forma que emplean la mayoría de los administradores de sistemas y pentesters al momento de asignar permisos mediante `chmod`.

Para convertir de notación simbólica a octal, el procedimiento consiste en separar los permisos en sus tres bloques de tres caracteres y, dentro de cada bloque, reemplazar cada letra presente por un `1` y cada guion (ausencia de permiso) por un `0`. El resultado es, en definitiva, un número expresado en sistema binario, que luego debe convertirse a su equivalente en base 8. Por ejemplo, tomemos el directorio `testing`, creado con los permisos por defecto `rwxr-xr-x`:

```bash
❯ mkdir testing
drwxr-xr-x root   root    0 B Mon Jul  6 06:00:26 2026 testing
```

Separando los permisos en sus tres bloques (`rwx`, `r-x`, `r-x`) y sustituyendo cada letra por un `1` y cada guion por un `0`, se obtiene la secuencia binaria `111 101 101`. Para convertir cada grupo de tres dígitos binarios a su equivalente octal, basta con memorizar la siguiente tabla de correspondencias, que cubre las ocho combinaciones posibles de tres bits:

```
0 --> 000
1 --> 001
2 --> 010
3 --> 011
4 --> 100
5 --> 101
6 --> 110
7 --> 111
```

Aplicando esta tabla a la secuencia obtenida (`111 101 101`), el resultado en notación octal es `755`, que es precisamente el valor numérico que suele emplearse habitualmente para asignar permisos de ejecución completos al propietario y de lectura/ejecución al grupo y a otros.

Como segundo ejemplo, supongamos que se desea asignar al mismo directorio los permisos `r-xr---w-`. Transformando cada bloque a binario se obtiene `101 100 010`, y consultando la tabla de correspondencias, esto equivale al número octal `542`. Con este valor, `chmod` puede aplicar el cambio directamente:

```bash
❯ ls -la
drwxr-xr-x root   root    0 B Mon Jul  6 06:00:26 2026 testing
❯ chmod 542 testing
❯ ls -la
dr-xr---w- root   root    0 B Mon Jul  6 06:00:26 2026 testing
```

Existe además un atajo mental particularmente útil para calcular la notación octal sin necesidad de memorizar la tabla completa, basado en el patrón `4-2-1`. Este patrón se deriva directamente de cómo se convierte un número binario a decimal: cada posición de un número binario representa una potencia de 2, comenzando desde la posición menos significativa con `2⁰ = 1`, seguida de `2¹ = 2` y `2² = 4`. Al tratarse siempre de grupos de exactamente tres bits (dado que la notación octal solo admite dígitos del 0 al 7), las únicas potencias relevantes son `4`, `2` y `1`, correspondientes respectivamente a los permisos de lectura, escritura y ejecución. De este modo, para obtener el valor octal de un bloque de permisos, basta con sumar 4 si hay permiso de lectura, 2 si hay permiso de escritura, y 1 si hay permiso de ejecución, e ignorar por completo aquellas posiciones donde el permiso esté ausente.

Por ejemplo, para el número binario `110`, solo se suman las potencias correspondientes a las posiciones con un `1`: `2² + 2¹ = 4 + 2 = 6`. Aplicando esta misma lógica a la cadena de permisos `r--rwx-wx`, se obtiene: `r--` equivale a `4` (solo lectura), `rwx` equivale a `4+2+1 = 7` (los tres permisos), y `-wx` equivale a `2+1 = 3` (escritura y ejecución, sin lectura), dando como resultado el valor octal `473`.

## Permisos especiales

Además de los permisos básicos de lectura, escritura y ejecución aplicados a propietario, grupo y otros, Linux contempla tres permisos especiales adicionales que amplían el comportamiento estándar del sistema de archivos: el bit SUID (_Set User ID_), el bit SGID (_Set Group ID_) y el sticky bit (bit de permanencia). Estos tres permisos especiales permiten que la representación octal de un archivo o directorio se extienda de los tres dígitos habituales (000 a 777) a cuatro dígitos (0000 a 7777), donde el dígito adicional, ubicado a la izquierda de los tres ya conocidos, corresponde precisamente a la combinación de estos permisos especiales: el sticky bit se representa con el valor `1`, el SGID con el valor `2`, y el SUID con el valor `4`, pudiendo combinarse sumando sus valores cuando se desea activar más de uno simultáneamente.

El permiso SUID, cuando se activa sobre un archivo ejecutable, provoca que dicho archivo se ejecute siempre con los privilegios del usuario propietario del archivo, independientemente de qué usuario del sistema sea quien efectivamente lo invoque. Esto resulta especialmente relevante cuando el propietario del archivo es `root`: en tal caso, cualquier usuario sin privilegios que ejecute ese binario obtendrá, durante el tiempo que dure la ejecución, privilegios equivalentes a los de `root`. Un ejemplo real y muy conocido de esta mecánica es el propio binario `passwd`, el cual necesita permisos de `root` para poder modificar el archivo `/etc/shadow`, pero que cualquier usuario del sistema debe poder ejecutar para cambiar su propia contraseña; el permiso SUID es precisamente lo que hace posible esta aparente contradicción. Para asignar este permiso se utiliza `chmod u+s archivo`, o su equivalente octal anteponiendo un `4` a los permisos normales, como en `chmod 4755 archivo`. Al listar un archivo con este permiso activado, la letra `x` correspondiente al propietario se reemplaza por una `s` minúscula (si el archivo además tiene permiso de ejecución) o por una `S` mayúscula (si el archivo no tiene permiso de ejecución, en cuyo caso el bit SUID queda sin efecto práctico, ya que un archivo que no puede ejecutarse tampoco puede aprovechar esta elevación de privilegios). Desde la perspectiva de un pentester, localizar binarios con el permiso SUID activado y pertenecientes a `root` es una de las primeras tareas de enumeración en cualquier sistema comprometido, ya que ciertos binarios mal configurados con este permiso constituyen una vía directa y bien documentada de escalada de privilegios.

El permiso SGID funciona de manera análoga al SUID, pero en lugar de heredar los privilegios del usuario propietario, hereda los privilegios del grupo propietario del archivo. Aplicado sobre un archivo ejecutable, cualquier usuario que lo ejecute obtendrá los privilegios asociados al grupo propietario mientras dure la ejecución. Sin embargo, la aplicación más habitual del SGID no es sobre archivos individuales sino sobre directorios: cuando este permiso se activa en un directorio, todo archivo o subdirectorio creado dentro de él heredará automáticamente el grupo propietario del directorio padre, en lugar del grupo primario del usuario que efectivamente lo creó. Esta característica resulta sumamente útil en directorios de trabajo compartido entre varios usuarios que pertenecen a un mismo grupo, ya que garantiza que todos los archivos generados dentro de ese directorio queden accesibles para todo el grupo, sin depender de que cada usuario recuerde cambiar manualmente el grupo propietario de cada archivo nuevo. Para asignarlo se utiliza `chmod g+s archivo_o_directorio`, o su equivalente octal anteponiendo un `2`, como en `chmod 2755 directorio`. Al igual que ocurre con el SUID, en la salida de `ls -l` la letra `x` correspondiente al grupo se reemplaza por una `s` (o una `S` si no existía permiso de ejecución previo).

El sticky bit, por su parte, tiene un propósito bien distinto: aplicado sobre un directorio, restringe la posibilidad de eliminar o renombrar los archivos contenidos en él exclusivamente al propietario de cada archivo y a `root`, incluso si otros usuarios cuentan con permiso de escritura sobre el directorio en cuestión. En ausencia de este permiso, cualquier usuario con permiso de escritura sobre un directorio podría eliminar o renombrar archivos ajenos dentro de él, lo cual resultaría problemático en directorios de uso compartido por múltiples usuarios del sistema. El ejemplo más representativo de este permiso es el directorio `/tmp`, utilizado por prácticamente todos los procesos del sistema para almacenar archivos temporales: gracias al sticky bit, cada usuario o proceso puede crear y modificar sus propios archivos temporales en `/tmp`, pero no puede eliminar ni renombrar los archivos temporales creados por otros usuarios. Para asignar este permiso se utiliza `chmod +t directorio`, o su equivalente octal anteponiendo un `1`, como en `chmod 1755 directorio`. En la salida de `ls -l`, el sticky bit se refleja reemplazando la `x` correspondiente a "otros" por una `t` minúscula (si existía permiso de ejecución) o una `T` mayúscula (si no existía).

Dado que los tres permisos especiales pueden combinarse sumando sus valores octales, resulta posible, por ejemplo, activar simultáneamente SUID y SGID sobre un archivo con permisos `755` mediante `chmod 6755 archivo` (sumando `4` de SUID más `2` de SGID), o activar los tres permisos especiales a la vez sobre un directorio con permisos `777` mediante `chmod 7777 directorio`. Aunque estos permisos especiales resultan legítimamente útiles en escenarios administrativos concretos, es fundamental manejarlos con extremo cuidado: una configuración descuidada, particularmente en el caso del SUID sobre binarios propiedad de `root`, es una de las causas más frecuentes de escaladas de privilegios accidentales o explotables en sistemas Linux mal auditados.

## Control de atributos de ficheros: chattr y lsattr

Más allá de los permisos convencionales gestionados mediante `chmod`, `chown` y `chgrp`, el sistema de archivos de Linux (particularmente en filesystems de la familia extended, como ext2, ext3 y ext4) admite un conjunto adicional de atributos de bajo nivel, almacenados directamente en el inodo del archivo, que operan de forma completamente independiente al modelo de permisos tradicional. Estos atributos se gestionan mediante dos comandos complementarios: `lsattr`, que permite listar los atributos actualmente asignados a uno o varios archivos, y `chattr` (_change attribute_), que permite modificarlos.

La diferencia fundamental entre estos atributos y los permisos convencionales radica en que los atributos actúan a un nivel más profundo que el propio modelo de usuarios y grupos: mientras que los permisos habituales dependen de quién sea el usuario que intenta realizar una acción, ciertos atributos gestionados por `chattr` restringen operaciones específicas de forma incondicional, independientemente de qué usuario las intente, incluyendo en algunos casos incluso al propio `root`. El atributo más utilizado en la práctica es el atributo inmutable, representado con la letra `i`. Cuando un archivo tiene este atributo activado, no puede ser modificado, renombrado, eliminado, ni se pueden crear enlaces (ni duros ni simbólicos) hacia él, y esta restricción aplica incluso a `root`, salvo que este primero retire explícitamente el atributo inmutable con `chattr -i`. Esta característica convierte al atributo inmutable en una herramienta de defensa particularmente interesante para proteger archivos críticos del sistema, como `/etc/passwd` o `/etc/shadow`, frente a modificaciones accidentales o maliciosas, incluso en escenarios donde un atacante ya hubiese logrado obtener privilegios de `root` de forma temporal, ya que dicho atacante tendría que conocer y ejecutar explícitamente el comando para retirar el atributo antes de poder alterar el archivo protegido.

```bash
# Muestra los atributos actuales de un archivo
lsattr archivo.txt

# Activa el atributo inmutable sobre el archivo (requiere privilegios de root)
sudo chattr +i archivo.txt

# A partir de este punto, cualquier intento de modificación falla,
# incluso realizado por root, hasta que se retire el atributo
echo "nuevo contenido" > archivo.txt
# bash: archivo.txt: Operation not permitted

# Retira el atributo inmutable, devolviendo el archivo a su estado normal
sudo chattr -i archivo.txt
```

Otro atributo de uso frecuente es el atributo de solo-anexado, representado con la letra `a`. A diferencia del atributo inmutable, que bloquea cualquier tipo de modificación, este atributo permite que se agregue contenido nuevo al final del archivo, pero impide modificar o eliminar el contenido ya existente, así como eliminar o renombrar el archivo en sí. Esta característica resulta especialmente valiosa para proteger la integridad de archivos de registro (logs), ya que garantiza que la información histórica ya escrita no pueda ser alterada retroactivamente por un atacante que intentase borrar evidencia de sus acciones, permitiendo únicamente que el proceso de logging continúe agregando nuevas entradas.

```bash
# Activa el atributo de solo-anexado sobre un archivo de registro
sudo chattr +a registro.log

# Es posible seguir agregando contenido al final del archivo
echo "nueva entrada de log" >> registro.log

# Pero cualquier intento de sobrescribir o truncar el archivo falla
echo "intento de sobrescritura" > registro.log
# bash: registro.log: Operation not permitted
```

Existen además otros atributos menos utilizados en el día a día pero igualmente documentados, como el atributo de compresión automática (`c`), el atributo que deshabilita la actualización del registro de último acceso o _atime_ (`A`), o el atributo de eliminación segura (`s`), que garantiza que los bloques de datos de un archivo eliminado se sobrescriban con ceros antes de liberarse, dificultando su posible recuperación forense. Cabe destacar que no todos los sistemas de archivos soportan la totalidad de estos atributos: mientras que ext2, ext3 y ext4 ofrecen soporte prácticamente completo, sistemas de archivos como XFS o Btrfs solo admiten un subconjunto reducido de ellos, por lo que conviene siempre verificar la compatibilidad del sistema de archivos en uso antes de depender de un atributo específico como mecanismo de protección.

Desde la perspectiva de la ciberseguridad, tanto la asignación como la detección de estos atributos resultan relevantes en direcciones opuestas: como medida defensiva, aplicar el atributo inmutable sobre archivos de configuración críticos o binarios sensibles puede dificultar considerablemente que un atacante, incluso habiendo obtenido privilegios elevados, logre persistir modificaciones maliciosas de forma sencilla; como medida ofensiva o de auditoría, revisar la presencia de atributos inusuales mediante `lsattr` en ubicaciones como directorios temporales puede ayudar a detectar mecanismos de persistencia o manipulaciones fuera de lo común dejadas por un atacante previo.

Más allá de `i` y `a`, existen otros flags que, aunque se usan con menor frecuencia, resultan igualmente interesantes de conocer. El atributo `d`, cuando se activa sobre un archivo, indica a la utilidad `dump` (herramienta clásica de copias de seguridad a nivel de sistema de archivos en distribuciones basadas en ext) que dicho archivo debe excluirse del respaldo, lo cual puede ser útil para archivos temporales o regenerables que no tiene sentido incluir en un backup, pero que también podría ser abusado por un atacante para ocultar deliberadamente un archivo malicioso de los procesos de copia de seguridad automatizados. El atributo `u`, por su parte, tiene un comportamiento peculiar: cuando un archivo con este atributo activado se elimina, el sistema conserva su contenido de manera que, en teoría, pueda recuperarse posteriormente en lugar de liberar inmediatamente los bloques de datos que ocupaba; en la práctica, el soporte real de esta funcionalidad de "undelete" depende en gran medida de utilidades específicas y no está garantizado en todas las implementaciones, pero resulta un concepto interesante desde el punto de vista forense. El atributo `j`, disponible en sistemas ext3 y ext4 con journaling habilitado, obliga a que todos los cambios realizados sobre el archivo se registren primero en el journal del sistema de archivos antes de escribirse en el archivo en sí, lo cual mejora la resistencia del archivo ante una corrupción causada por un corte de energía o un cierre abrupto del sistema, a costa de un rendimiento ligeramente menor. El atributo `S`, de forma similar, fuerza que cualquier modificación se escriba de manera síncrona en disco de inmediato, en lugar de quedar temporalmente en el caché de escritura del sistema, lo cual también prioriza la integridad frente al rendimiento y resulta útil para archivos donde no se puede permitir la pérdida de las últimas escrituras ante un fallo repentino.

Es importante distinguir estos atributos, que pueden establecerse y modificarse mediante `chattr`, de otro grupo de atributos que `lsattr` puede mostrar pero que son de solo lectura, es decir, que el propio kernel o el sistema de archivos los gestiona automáticamente sin que el usuario pueda alterarlos manualmente. Entre estos se encuentran el atributo `e`, que indica que el archivo utiliza el formato de extents para su asignación de bloques (un método de direccionamiento más eficiente que el esquema clásico de bloques indirectos, y que aparece por defecto en prácticamente todos los archivos de un sistema ext4), el atributo `E`, que indica que el archivo se encuentra cifrado a nivel de sistema de archivos, y el atributo `I`, que indica que el directorio correspondiente está indexado mediante un árbol hash (htree) para acelerar las búsquedas dentro de directorios con una gran cantidad de archivos. Ver estos atributos en la salida de `lsattr` es normal y no implica ninguna configuración manual: forman parte del funcionamiento interno del sistema de archivos y sirven principalmente como información de diagnóstico.
