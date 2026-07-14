# Escape de Contexto Restringido: de `more` a una Shell Completa

## El escenario: una conexión SSH que no entrega una shell

Un escenario relativamente frecuente, tanto en máquinas de CTF diseñadas específicamente para practicar esta técnica como en sistemas reales endurecidos de forma deliberada (o, con menor frecuencia, mal configurados por error), es aquel en el que una conexión SSH se autentica correctamente, pero en lugar de entregar una sesión de shell interactiva normal, el usuario se encuentra con un banner de texto breve y, acto seguido, la conexión se corta o queda en un estado extraño, sin un prompt de comandos utilizable. Este comportamiento es distinto al ya visto en apuntes anteriores sobre archivos `.bashrc` modificados con un `exit`: aquí, el motivo suele ser que la cuenta con la que se está iniciando sesión no tiene asignada una shell convencional (como `/bin/bash` o `/bin/sh`) en `/etc/passwd`, sino que tiene configurado directamente un programa distinto como si fuera su "shell", o bien el servidor SSH está configurado con una directiva `ForceCommand` (en `/etc/ssh/sshd_config` o en el propio `authorized_keys` de esa cuenta) que obliga a ejecutar un comando concreto en lugar de abrir una sesión de shell normal, sin importar qué comando hubiera solicitado el cliente.

Cuando ese comando forzado resulta ser un paginador de texto, como `more` o `less` (invocado, por ejemplo, para mostrar un archivo de bienvenida o un mensaje de aviso legal antes de cortar la conexión), se abre una vía de escape muy conocida y ampliamente documentada dentro de la comunidad de pentesting, catalogada además en GTFOBins bajo la entrada correspondiente a `more`, `less` y `vi`/`vim`: estos programas, pensados originalmente para un uso completamente legítimo, incorporan funcionalidades internas que permiten invocar un editor de texto o un intérprete de comandos desde dentro de ellos mismos, funcionalidades que no fueron concebidas como una vulnerabilidad, sino como comodidades para el usuario, pero que en un contexto de shell restringida se convierten en la puerta de salida hacia una shell completa.

## Por qué `more` puede invocar un editor

`more` (y de forma análoga `less`, su sucesor con más funcionalidades) es un paginador: una herramienta pensada para mostrar el contenido de un archivo de texto largo pantalla por pantalla, permitiendo al usuario avanzar y retroceder con comodidad en lugar de que todo el contenido se vuelque de golpe en la terminal, como haría `cat`. Como parte de su conjunto de comandos internos (teclas que se interpretan de forma especial mientras se está paginando un archivo, sin llegar a escribirse literalmente en ningún buscador ni comando de texto), `more` incluye la posibilidad de abrir el archivo que se está visualizando directamente en un editor de texto externo, típicamente mediante la tecla `v`. Esta funcionalidad está pensada para el caso de uso legítimo de "estoy leyendo este archivo con more y quiero corregir algo que acabo de ver, sin tener que cerrar more, recordar la ruta del archivo, y volver a abrirlo manualmente en un editor". El editor concreto que `more` invoca al presionar `v` depende de la variable de entorno `$EDITOR` o `$VISUAL` si están definidas, y recurre a `vi` (o a la implementación de `vi` disponible en el sistema, habitualmente `vim`) como valor por defecto cuando ninguna de esas variables está establecida.

Esta es la clave que hace que la técnica funcione: al presionar `v` dentro de `more`, el propio `more` lanza un proceso `vim` completo, heredando el contexto de ejecución (usuario, permisos, entorno) de la sesión SSH actual. Y `vim`, a su vez, es un editor extremadamente potente que, entre sus numerosísimas funcionalidades, incluye la capacidad de ejecutar comandos del sistema operativo directamente desde dentro del propio editor, sin necesidad de cerrarlo, mediante su modo de comandos (`:`).

## Paso a paso: de la conexión SSH a una shell completa

Reconstruyendo el flujo completo descrito en el planteamiento inicial, la secuencia de pasos sería la siguiente:

```bash
# Se establece la conexión SSH de la forma habitual
ssh usuario@maquina_objetivo

# La conexión se autentica correctamente, y el servidor muestra
# un banner breve antes de comenzar a mostrar el contenido
# de algún archivo mediante "more" (por ejemplo, un mensaje
# de bienvenida o un aviso legal), quedando la terminal
# en modo de paginación, con un indicador como:
--More--
```

Llegados a este punto, en lugar de presionar `q` (que cerraría `more` y, muy probablemente, terminaría también la conexión SSH al no quedar ningún comando en ejecución dentro de la sesión forzada) o `espacio`/`enter` (que simplemente avanzarían a la siguiente pantalla del contenido), se presiona la tecla `v`.

```
--More--
v
```

Esto lanza `vim`, abriendo dentro de él el mismo archivo que `more` estaba paginando. En este punto, el usuario se encuentra dentro de una sesión completa y funcional de `vim`, con todas sus capacidades habituales disponibles, incluyendo su modo de comandos. Desde el modo normal de `vim` (el modo por defecto al abrir el editor, antes de presionar `i` para entrar en modo inserción), se escribe dos puntos (`:`) para entrar en el modo de línea de comandos de `vim`, y a continuación se establece explícitamente qué intérprete de shell debe utilizar `vim` cuando se le pida ejecutar comandos externos, mediante la opción interna `shell`.

```vim
:set shell=/bin/bash
```

Esta instrucción no ejecuta todavía ninguna shell; únicamente configura, dentro de la sesión actual de `vim`, cuál será el programa que se invocará la próxima vez que se le pida a `vim` que abra una shell o que ejecute un comando externo, sobrescribiendo el valor por defecto de esa opción (que en muchos sistemas ya apunta de por sí a `/bin/sh`, pero conviene fijarlo explícitamente a `/bin/bash` para asegurar una shell completa e interactiva con todas sus comodidades habituales, como el historial de comandos o el autocompletado). Con el shell ya configurado, se invoca el comando interno de `vim` que efectivamente abre una shell interactiva:

```vim
:shell
```

Al ejecutar `:shell`, `vim` suspende temporalmente su propia interfaz (sin cerrarse del todo) y lanza el programa indicado en la opción `shell` configurada en el paso anterior, es decir, `/bin/bash`, entregando el control de la terminal directamente a esa nueva shell. El resultado es una sesión de bash completamente interactiva y funcional, heredando los mismos privilegios que tenía la sesión SSH original (los del usuario con el que se autenticó la conexión), pero sin las restricciones que estaban impuestas sobre el comando forzado inicial, ya que `vim` (y por extensión, la shell que lanza) no está sujeto a la misma restricción que ató originalmente a `more`.

```bash
# Confirmación de que se ha obtenido una shell funcional,
# con el usuario y los privilegios de la cuenta SSH original
whoami
id
pwd
```

## Alternativa: ejecutar un único comando sin salir de vim

Además de `:shell`, que abre una sesión de shell interactiva completa, `vim` ofrece una sintaxis alternativa para ejecutar un único comando puntual del sistema operativo sin necesidad de entrar en una subshell persistente, mediante el prefijo `!` dentro del modo de comandos.

```vim
:!whoami
:!/bin/bash
```

La diferencia práctica entre ambas formas es que `:!comando` ejecuta ese comando concreto, muestra su salida, y devuelve el control inmediatamente a `vim` una vez terminado (pulsando `Enter` para volver a la interfaz normal del editor), mientras que `:shell` (o, de forma equivalente, `:!/bin/bash`, invocando explícitamente una shell como si fuera el "comando" a ejecutar) entrega una sesión interactiva persistente que se mantiene abierta hasta que el propio usuario decida cerrarla manualmente, típicamente escribiendo `exit`, momento en el cual el control regresa a la sesión de `vim` que quedó en pausa de fondo.

## Volviendo a la shell restringida original (y por qué no hace falta)

Al escribir `exit` dentro de la shell obtenida mediante `:shell`, el control regresa efectivamente a la sesión de `vim` que había quedado suspendida, y desde ahí se podría salir de `vim` de la forma habitual (`:q` para salir sin guardar cambios, dado que en este contexto no interesa modificar el archivo original que `more` estaba mostrando) para regresar al `more` original, y desde ahí presionar `q` para cerrar también el paginador. En la práctica, sin embargo, una vez obtenida la shell mediante `:shell`, la inmensa mayoría de las veces no hay ningún motivo real para regresar a ese estado anterior: la shell recién obtenida ya es plenamente funcional y persistente por sí misma, y puede utilizarse directamente para continuar cualquier tarea de post-explotación (enumeración del sistema, búsqueda de vectores de escalada de privilegios, transferencia de herramientas, etc.) sin necesidad de "deshacer" el camino recorrido a través de `more` y `vim`.

## Por qué esta técnica funciona: la raíz del problema

Esta técnica de escape ilustra un principio de seguridad mucho más general y aplicable a otras muchas situaciones, no exclusivo de `more` ni de `vim`: cualquier programa que, dentro de un entorno restringido (una shell restringida, un comando forzado por SSH, un binario SUID, una regla de `sudo` limitada a un binario concreto), permita de alguna manera invocar un editor de texto, un paginador, o cualquier otro programa suficientemente potente y de propósito general, corre el riesgo de que ese programa "secundario" invocado desde dentro se convierta en la vía de escape hacia una funcionalidad no prevista, precisamente porque ese programa secundario no hereda automáticamente las restricciones que se habían impuesto sobre el programa original que lo invocó. Este es exactamente el mismo principio subyacente a la explotación de binarios SUID vista en apuntes anteriores (el binario en sí puede estar limitado en su propósito, pero si internamente invoca un editor, un paginador o un intérprete con capacidad de ejecutar comandos, esa funcionalidad interna hereda los privilegios del binario que la invocó), lo cual explica por qué GTFOBins documenta prácticamente los mismos binarios (`vim`, `less`, `more`, `awk`, `find`, entre muchos otros) tanto para escenarios de escalada de privilegios vía SUID como para escenarios de escape de shells restringidas: en ambos casos, el mecanismo de fondo es idéntico, cambia únicamente el tipo de restricción de la que se está escapando (una restricción de privilegios en el primer caso, una restricción de funcionalidad disponible en el segundo).

## Recomendaciones de hardening

Desde la perspectiva de un administrador que necesite configurar legítimamente comandos forzados a través de SSH (por ejemplo, para ofrecer acceso limitado a un colaborador externo que solo debería poder consultar un archivo de estado, sin obtener una shell completa), este escenario deja varias lecciones claras. En primer lugar, jamás debería utilizarse un paginador de propósito general como `more` o `less` como comando forzado sin antes deshabilitar explícitamente sus capacidades de escape a un editor o a una shell; `less`, por ejemplo, admite iniciarse con la opción `--no-init` combinada con una configuración adicional para restringir estas capacidades, aunque la forma más robusta de mostrar contenido estático sin exponer ningún riesgo de escape es evitar directamente el uso de un paginador interactivo, optando en su lugar por `cat` (que no ofrece ningún comando interno interactivo del que abusar) para mostrar el contenido y cerrar la sesión inmediatamente después. En segundo lugar, si el objetivo real es restringir a un usuario a un conjunto reducido de comandos, la solución correcta es una shell restringida propiamente dicha (como `rbash`) combinada con un `$PATH` cuidadosamente limitado a únicamente los binarios estrictamente necesarios, en lugar de intentar lograr una restricción equivalente forzando la ejecución de un único programa que, como se ha visto, puede terminar ofreciendo bastante más funcionalidad de la que aparenta a simple vista. Y en tercer lugar, conviene tener presente que prácticamente cualquier editor de texto de propósito general (`vim`, `nano` en menor medida, `emacs`) incorpora, por diseño, alguna forma de invocar comandos del sistema operativo desde dentro de sí mismo, por lo que permitir su ejecución, aunque sea de forma indirecta a través de otro programa, dentro de cualquier contexto que se pretenda restringido, debe considerarse siempre equivalente a otorgar una shell completa sin restricciones.
