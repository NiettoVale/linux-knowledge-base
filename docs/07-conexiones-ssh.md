# SSH (Secure Shell)

## Introducción y por qué surgió

SSH, abreviatura de _Secure Shell_, es un protocolo de red diseñado para permitir la administración remota de sistemas y la transferencia de datos de forma cifrada y autenticada a través de una red potencialmente insegura. Hoy en día resulta difícil imaginar la administración de un servidor Linux sin SSH, pero su existencia responde a un problema muy concreto que sufrió la comunidad de administradores de sistemas durante las décadas de 1980 y principios de 1990: los protocolos de acceso remoto disponibles hasta entonces, como Telnet, rlogin y rsh (_remote shell_), transmitían absolutamente toda su información en texto plano por la red, incluyendo las credenciales de autenticación.

Esto significaba que cualquier atacante capaz de interceptar el tráfico de red entre el cliente y el servidor (por ejemplo, mediante técnicas de sniffing en una red local compartida, o comprometiendo algún equipo intermedio en la ruta de la conexión) podía capturar directamente el usuario y la contraseña utilizados para iniciar sesión, sin necesidad de romper ningún tipo de cifrado, ya que sencillamente no existía ninguno. El punto de inflexión que impulsó la creación de SSH ocurrió en 1995, cuando Tatu Ylönen, investigador de la Universidad Tecnológica de Helsinki, sufrió en su propia red universitaria un ataque de sniffing de contraseñas a gran escala. Como respuesta directa a este incidente, Ylönen diseñó la primera versión del protocolo SSH (posteriormente conocida como SSH-1) y liberó su implementación de forma gratuita, lo cual provocó una adopción extremadamente rápida dentro de la comunidad técnica, ya que resolvía de raíz un problema de seguridad que hasta entonces se consideraba, en cierto modo, un mal necesario del acceso remoto.

Con el tiempo se identificaron debilidades criptográficas y de diseño en la versión original del protocolo, lo cual motivó el desarrollo de una segunda versión, SSH-2, estandarizada por el IETF a través de un conjunto de RFCs a comienzos de la década de 2000. SSH-2 introdujo una arquitectura más modular y segura, y es, en la práctica, la única versión del protocolo que se utiliza en sistemas modernos; la implementación de referencia más extendida en la actualidad es OpenSSH, desarrollada originalmente por el proyecto OpenBSD y presente por defecto en la inmensa mayoría de distribuciones Linux, así como en macOS y, desde hace pocos años, también de forma nativa en Windows.

## Relevancia en ciberseguridad

Comprender SSH en profundidad es indispensable tanto para quienes se dedican a asegurar sistemas como para quienes se dedican a auditarlos desde una perspectiva ofensiva, por varios motivos que conviene desglosar. En primer lugar, SSH es, en la inmensa mayoría de infraestructuras Linux, el punto de entrada administrativo por excelencia: prácticamente cualquier servidor expuesto a internet o accesible dentro de una red corporativa cuenta con un demonio SSH escuchando en algún puerto, lo cual lo convierte de forma casi automática en uno de los primeros servicios que un pentester enumerará durante la fase de reconocimiento de un objetivo, y en uno de los servicios que un equipo defensivo debe endurecer con mayor prioridad.

En segundo lugar, aunque SSH resuelve el problema del texto plano en la red, su seguridad efectiva depende enteramente de cómo se configure y de cómo se gestionen las credenciales asociadas a él: contraseñas débiles, claves privadas mal protegidas, configuraciones por defecto permisivas, o versiones desactualizadas del software, siguen constituyendo, más de veinticinco años después de la creación del protocolo, una de las vías de acceso inicial más comunes en incidentes de seguridad reales, tanto en ataques oportunistas automatizados (botnets que escanean internet en busca de servidores SSH con credenciales débiles) como en intrusiones dirigidas.

En tercer lugar, SSH no es únicamente un mecanismo de acceso a una shell remota: sus capacidades de reenvío de puertos (_port forwarding_) y creación de túneles cifrados lo convierten en una herramienta extremadamente versátil tanto para tareas legítimas de administración (acceder a servicios internos de una red sin exponerlos directamente a internet) como para técnicas ofensivas de post-explotación, como el pivoting durante un ejercicio de pentesting, donde un atacante que ha comprometido un host utiliza su conexión SSH hacia él como puente para alcanzar otros sistemas de la red interna que de otro modo serían inaccesibles desde el exterior.

## Arquitectura y funcionamiento del protocolo

Una conexión SSH se establece siguiendo, a grandes rasgos, tres fases diferenciadas, cada una de las cuales aporta una garantía de seguridad distinta al conjunto del protocolo. La primera fase es el establecimiento de la capa de transporte, durante la cual el cliente y el servidor negocian los algoritmos criptográficos que utilizarán a lo largo de la sesión (algoritmo de intercambio de claves, cifrado simétrico, algoritmo de verificación de integridad) y, mediante un intercambio de claves de tipo Diffie-Hellman (o alguna de sus variantes modernas basadas en curvas elípticas), generan de forma colaborativa una clave de sesión simétrica compartida, sin que dicha clave viaje nunca directamente por la red. Es precisamente en esta fase donde se produce la verificación de la identidad del servidor por parte del cliente, comparando la clave pública del host contra el archivo `known_hosts` del cliente, el mecanismo que da lugar a la conocida advertencia de "the authenticity of host X can't be established" la primera vez que un cliente se conecta a un servidor desconocido.

La segunda fase es la autenticación del usuario, en la cual el cliente demuestra ante el servidor que tiene derecho a iniciar sesión con la cuenta solicitada, ya sea mediante contraseña, mediante un par de claves criptográficas, o mediante otros métodos que se detallan más adelante en este documento. Es importante remarcar que esta fase de autenticación de usuario ocurre siempre después de que el canal cifrado ya está establecido gracias a la primera fase, por lo que, a diferencia de lo que ocurría con Telnet, ni la contraseña ni ninguna otra credencial viaja jamás en texto plano por la red, incluso si el método de autenticación elegido es una contraseña tradicional.

La tercera fase es la del propio canal de la conexión (_connection layer_), sobre la cual se multiplexan las distintas funcionalidades que SSH ofrece una vez autenticado el usuario: una sesión de shell interactiva, la ejecución de un comando remoto puntual, la transferencia de archivos mediante SFTP o SCP, o el establecimiento de túneles de reenvío de puertos, todo ello circulando sobre la misma conexión cifrada subyacente.

```bash
# Conexión básica a un servidor SSH, especificando el usuario
# y el host de destino
ssh usuario@192.168.1.10

# Especifica un puerto distinto al 22 por defecto
ssh -p 2222 usuario@192.168.1.10

# Ejecuta un único comando remoto sin abrir una sesión interactiva,
# devolviendo la salida directamente al terminal local
ssh usuario@192.168.1.10 "uname -a && uptime"

# Activa la salida detallada (verbose), muy útil para depurar
# problemas de conexión o de negociación de algoritmos
ssh -v usuario@192.168.1.10
```

## Autenticación: contraseña frente a claves públicas

SSH admite varios métodos de autenticación, siendo los dos más relevantes en la práctica la autenticación mediante contraseña y la autenticación mediante un par de claves asimétricas (pública y privada). Aunque la autenticación por contraseña sigue siendo funcionalmente válida y está habilitada por defecto en muchas configuraciones, la autenticación mediante claves se considera la práctica recomendada tanto por motivos de seguridad como de comodidad operativa, y su comprensión resulta fundamental tanto para configurar accesos administrativos correctamente como para reconocer, desde una perspectiva ofensiva, los riesgos asociados a una gestión descuidada de estas claves.

El funcionamiento de la autenticación por clave pública se apoya en criptografía asimétrica: el usuario genera un par de claves matemáticamente relacionadas entre sí, compuesto por una clave privada, que debe permanecer estrictamente secreta y nunca debe salir de la máquina del usuario ni compartirse con nadie, y una clave pública, que puede distribuirse libremente y que se instala en el servidor al que se desea acceder, concretamente en el archivo `~/.ssh/authorized_keys` de la cuenta de usuario correspondiente. Durante el proceso de autenticación, el servidor genera un desafío criptográfico basado en la clave pública registrada, y únicamente quien posea la clave privada correspondiente es capaz de responder correctamente a dicho desafío, demostrando así su identidad sin necesidad de transmitir la clave privada por la red en ningún momento.

```bash
# Genera un nuevo par de claves utilizando el algoritmo Ed25519,
# recomendado actualmente frente a RSA por ofrecer mayor seguridad
# con claves considerablemente más cortas y una generación más rápida
ssh-keygen -t ed25519 -C "fnieto@ntech.studio"

# Alternativa con RSA, útil cuando se necesita compatibilidad
# con sistemas más antiguos que no soportan Ed25519;
# se recomienda un mínimo de 4096 bits de longitud
ssh-keygen -t rsa -b 4096 -C "fnieto@ntech.studio"

# Copia la clave pública generada hacia un servidor remoto,
# añadiéndola automáticamente a su archivo authorized_keys
ssh-copy-id usuario@192.168.1.10

# Forma manual equivalente a ssh-copy-id, útil cuando esta
# herramienta no está disponible en el sistema
cat ~/.ssh/id_ed25519.pub | ssh usuario@192.168.1.10 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Conexión especificando explícitamente qué clave privada utilizar,
# en lugar de depender de la selección automática
ssh -i ~/.ssh/id_ed25519_produccion usuario@192.168.1.10
```

Al generar un par de claves, `ssh-keygen` ofrece la posibilidad de proteger la clave privada con una frase de contraseña (_passphrase_). Esta frase de contraseña no sustituye a la clave privada como mecanismo de autenticación frente al servidor, sino que cifra la clave privada en el disco local del cliente, de modo que, aunque un atacante lograse copiar el archivo de la clave privada, no podría utilizarlo sin conocer también dicha frase de contraseña. Omitir esta protección por comodidad es una práctica desaconsejada, particularmente en equipos portátiles o en entornos donde el archivo de la clave pudiera quedar expuesto por un descuido, un malware infostealer, o una copia de seguridad mal protegida.

Para evitar tener que introducir la frase de contraseña de la clave privada en cada conexión, existe el agente SSH (`ssh-agent`), un proceso en segundo plano que mantiene las claves privadas descifradas en memoria durante la sesión del usuario, de modo que solo sea necesario introducir la contraseña una vez al inicio.

```bash
# Inicia el agente SSH en segundo plano (en muchos entornos de
# escritorio ya se inicia automáticamente al iniciar sesión)
eval "$(ssh-agent -s)"

# Añade una clave privada al agente, solicitando su passphrase
# una única vez durante el resto de la sesión
ssh-add ~/.ssh/id_ed25519

# Lista las claves actualmente cargadas en el agente
ssh-add -l

# Elimina todas las claves cargadas del agente,
# útil antes de cerrar sesión en un equipo compartido
ssh-add -D
```

## El archivo de configuración del cliente

El archivo `~/.ssh/config` permite definir alias y parámetros de conexión predeterminados para distintos hosts, evitando tener que recordar y escribir manualmente opciones extensas de línea de comandos cada vez que se desea conectar a un servidor determinado, y resultando especialmente valioso cuando se administran múltiples servidores con distintas claves, usuarios o puertos.

```bash
# Fragmento de ejemplo de ~/.ssh/config
Host produccion
    HostName 203.0.113.50
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_produccion

Host jumpbox
    HostName 198.51.100.20
    User fnieto
    IdentityFile ~/.ssh/id_ed25519

# Con esta configuración, en lugar de escribir el comando completo,
# basta con invocar el alias definido:
ssh produccion
```

## Transferencia de archivos: SCP y SFTP

Sobre el mismo canal cifrado que utiliza SSH para las sesiones de shell, es posible transferir archivos entre cliente y servidor mediante dos utilidades habituales: `scp` (_Secure Copy_), pensada para copias rápidas y directas con una sintaxis muy similar a la del comando `cp` tradicional, y `sftp` (_SSH File Transfer Protocol_), que ofrece una sesión interactiva de tipo FTP con capacidades más completas de navegación y gestión de archivos remotos.

```bash
# Copia un archivo local hacia un servidor remoto
scp archivo.txt usuario@192.168.1.10:/home/usuario/destino/

# Copia un archivo remoto hacia la máquina local
scp usuario@192.168.1.10:/etc/passwd ./passwd_copiado.txt

# Copia un directorio completo de forma recursiva
scp -r ./proyecto usuario@192.168.1.10:/home/usuario/

# Inicia una sesión interactiva SFTP contra un servidor remoto
sftp usuario@192.168.1.10
sftp> get archivo_remoto.txt      # Descarga un archivo
sftp> put archivo_local.txt       # Sube un archivo
sftp> ls                          # Lista el contenido remoto
sftp> exit
```

## Reenvío de puertos y tunneling

Una de las capacidades más potentes y menos conocidas por usuarios ocasionales de SSH es su capacidad de crear túneles cifrados para redirigir tráfico de red arbitrario, no necesariamente relacionado con la propia sesión de shell. Esta funcionalidad tiene tres modalidades principales, cada una con un propósito distinto.

El reenvío de puerto local (_local port forwarding_) permite acceder, desde la máquina local, a un servicio que solo es accesible desde el servidor remoto (por ejemplo, una base de datos que escucha únicamente en `localhost` dentro de ese servidor), redirigiendo un puerto de la máquina local a través del túnel SSH hacia el destino final.

```bash
# Redirige el puerto 8080 de la máquina local hacia el puerto 5432
# (PostgreSQL) tal y como se ve desde el servidor remoto, permitiendo
# conectarse a "localhost:8080" localmente para llegar a esa base de datos
ssh -L 8080:localhost:5432 usuario@192.168.1.10

# También es posible especificar un host de destino distinto al propio
# servidor SSH, útil para alcanzar un tercer equipo solo visible
# desde la red interna donde se encuentra el servidor SSH
ssh -L 8080:db-interno.local:5432 usuario@192.168.1.10
```

El reenvío de puerto remoto (_remote port forwarding_) realiza la operación inversa: expone un servicio de la máquina local hacia el servidor remoto, de modo que quien se conecte a un puerto determinado del servidor remoto termine realmente accediendo al servicio que corre en la máquina local del usuario. Esta modalidad es frecuentemente utilizada tanto en escenarios legítimos (exponer temporalmente un servicio de desarrollo local para que un tercero pueda probarlo) como en escenarios ofensivos durante ejercicios de pentesting, por ejemplo para exponer un servicio de captura de shells reversas hacia un host comprometido que se encuentra detrás de un NAT o un firewall restrictivo.

```bash
# Expone el puerto 3000 del servidor remoto, redirigiéndolo
# hacia el puerto 3000 de la máquina local
ssh -R 3000:localhost:3000 usuario@192.168.1.10
```

Finalmente, el reenvío dinámico (_dynamic port forwarding_) convierte a la propia conexión SSH en un proxy SOCKS, permitiendo redirigir a través del túnel cifrado el tráfico de cualquier aplicación configurada para utilizar ese proxy (navegadores, herramientas de escaneo, etc.), sin necesidad de especificar de antemano un destino fijo como ocurre con los reenvíos local y remoto.

```bash
# Levanta un proxy SOCKS en el puerto local 1080, a través
# del cual puede encaminarse el tráfico de otras herramientas
ssh -D 1080 usuario@192.168.1.10

# Ejemplo de uso combinado con proxychains para dirigir
# el tráfico de un escaneo de nmap a través del túnel SSH,
# alcanzando así hosts que solo son visibles desde la red
# interna donde reside el servidor SSH comprometido/administrado
proxychains nmap -sT -Pn 10.10.10.0/24
```

> **Nota de ciberseguridad:** el reenvío de puertos convierte a SSH en una herramienta de pivoting extremadamente eficaz durante un ejercicio de pentesting o Red Team: al comprometer un host con acceso SSH que además tiene visibilidad hacia una red interna inaccesible desde el exterior, un atacante puede utilizar el reenvío dinámico para encaminar herramientas de escaneo y explotación completas a través de ese único punto de apoyo. Desde la perspectiva defensiva, esto significa que restringir estrictamente qué usuarios pueden establecer túneles (mediante la directiva `AllowTcpForwarding` en la configuración del servidor) es una medida de hardening relevante en servidores que actúan como frontera entre redes con distinto nivel de confianza.

## Agent forwarding y sus riesgos

SSH permite además reenviar el propio agente de autenticación local hacia un servidor remoto, de modo que, una vez conectado a dicho servidor, sea posible utilizar las claves cargadas en el agente de la máquina local para autenticarse hacia un tercer servidor, sin necesidad de copiar la clave privada al servidor intermedio. Esta funcionalidad, conocida como _agent forwarding_, resulta cómoda en escenarios de administración con servidores intermedios (bastion hosts o jump servers), pero conlleva una implicación de seguridad importante que conviene comprender bien antes de habilitarla.

```bash
# Habilita el reenvío del agente SSH hacia el servidor remoto
ssh -A usuario@jumpbox.local
```

> **Nota de ciberseguridad:** cuando se habilita el agent forwarding hacia un servidor, cualquier proceso con privilegios suficientes en ese servidor (incluyendo, de forma crítica, el usuario `root` de dicho servidor, o un atacante que hubiese logrado comprometerlo) puede, mientras la sesión del usuario permanece activa, utilizar el socket del agente reenviado para autenticarse hacia cualquier otro servidor donde la clave privada del usuario tenga acceso, sin necesidad de robar ni de conocer la clave privada en sí. En la práctica, esto significa que habilitar `-A` hacia un servidor en el que no se confía plenamente equivale, durante la duración de la sesión, a delegar la capacidad de autenticarse con la identidad del usuario en cualquier otro sistema accesible con esa misma clave. Por este motivo, la recomendación general es evitar el agent forwarding salvo que sea estrictamente necesario, y en su lugar preferir mecanismos como `ProxyJump` para atravesar servidores intermedios sin exponer el agente.

```bash
# ProxyJump permite atravesar un servidor intermedio (bastion host)
# para llegar a un servidor final, sin necesidad de reenviar
# el agente de autenticación hacia el servidor intermedio
ssh -J usuario@bastion.local usuario@servidor-interno.local

# Configuración equivalente, más cómoda, dentro de ~/.ssh/config
Host servidor-interno
    HostName 10.0.0.5
    User usuario
    ProxyJump bastion.local
```

## Hardening del servidor SSH

Desde la perspectiva de un administrador de sistemas o de un auditor que emite recomendaciones tras un pentest, existen numerosas directivas configurables en el archivo de configuración del demonio SSH (`/etc/ssh/sshd_config`) que reducen significativamente la superficie de ataque expuesta por este servicio, muchas de las cuales deberían considerarse prácticamente obligatorias en cualquier servidor expuesto a redes no completamente confiables.

```bash
# Fragmento de ejemplo de /etc/ssh/sshd_config endurecido

# Deshabilita por completo el acceso directo del usuario root vía SSH,
# obligando a iniciar sesión con una cuenta normal y escalar mediante sudo
PermitRootLogin no

# Deshabilita la autenticación mediante contraseña, exigiendo
# el uso de claves públicas, lo cual elimina por completo el riesgo
# de ataques de fuerza bruta o diccionario contra contraseñas
PasswordAuthentication no

# Exige explícitamente que la autenticación por clave pública
# esté habilitada (suele venir activada por defecto)
PubkeyAuthentication yes

# Cambia el puerto por defecto (22) por otro no estándar,
# lo cual no aporta seguridad real frente a un atacante dirigido,
# pero reduce drásticamente el ruido de escaneos automatizados
# y ataques oportunistas de bots que solo prueban el puerto 22
Port 2222

# Restringe el acceso SSH únicamente a los usuarios o grupos indicados
AllowUsers fnieto admin
AllowGroups ssh-access

# Limita el número de intentos de autenticación permitidos
# por conexión antes de cerrarla
MaxAuthTries 3

# Desconecta automáticamente sesiones inactivas tras un periodo
# de tiempo determinado, reduciendo la ventana de exposición
# de sesiones olvidadas abiertas
ClientAliveInterval 300
ClientAliveCountMax 2

# Restringe el reenvío de puertos únicamente a los casos
# estrictamente necesarios, en lugar de permitirlo globalmente
AllowTcpForwarding no

# Deshabilita el reenvío del agente SSH por defecto en el servidor
AllowAgentForwarding no

# Deshabilita el uso de autenticación basada en host, un mecanismo
# heredado y considerablemente menos seguro que las claves públicas
HostbasedAuthentication no
```

Además de la configuración del propio `sshd_config`, se recomienda complementar el hardening del servicio con herramientas de protección a nivel de red, como `fail2ban`, que monitoriza los registros de autenticación y bloquea automáticamente, mediante reglas de firewall, las direcciones IP que acumulan un número excesivo de intentos fallidos de inicio de sesión en un periodo corto de tiempo, mitigando así ataques de fuerza bruta incluso cuando, por algún motivo operativo, la autenticación por contraseña no puede deshabilitarse por completo.

## SSH desde la perspectiva ofensiva

Durante un ejercicio de pentesting, la enumeración de un servicio SSH expuesto sigue un patrón bastante consistente. En primer lugar, se identifica la versión concreta del software en ejecución (habitualmente OpenSSH junto con un número de versión), lo cual permite contrastarla contra bases de datos de vulnerabilidades conocidas para esa versión específica, ya que a lo largo de los años se han descubierto puntualmente vulnerabilidades explotables directamente en la implementación del propio demonio SSH.

```bash
# Obtiene el banner de versión del servicio SSH mediante netcat
nc -nv 192.168.1.10 22

# Escaneo más completo con nmap, incluyendo scripts de detección
# de algoritmos soportados y posibles vulnerabilidades conocidas
nmap -sV -p 22 --script ssh2-enum-algos,ssh-auth-methods 192.168.1.10
```

Cuando la autenticación por contraseña está habilitada, y especialmente cuando se han identificado nombres de usuario válidos previamente (por ejemplo, mediante OSINT o mediante la enumeración de otros servicios del mismo objetivo), los ataques de fuerza bruta o de diccionario contra el servicio SSH siguen siendo, sorprendentemente, una vía de acceso inicial habitual en entornos reales mal configurados, apoyados en herramientas como Hydra o Medusa.

```bash
# Ataque de diccionario contra un servicio SSH utilizando Hydra,
# probando un usuario conocido contra una lista de contraseñas comunes
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://192.168.1.10
```

Por otro lado, cuando durante la fase de post-explotación se logra acceso a un sistema comprometido, resulta habitual buscar claves privadas SSH mal protegidas que pudieran permitir el movimiento lateral hacia otros sistemas de la infraestructura, particularmente cuando dichas claves no están protegidas mediante una frase de contraseña.

```bash
# Búsqueda de posibles claves privadas SSH en un sistema comprometido
find / -name "id_rsa" -o -name "id_ed25519" -o -name "*.pem" 2>/dev/null

# Revisión de qué claves públicas están autorizadas a acceder
# a la cuenta actual, lo cual puede revelar identidades
# o máquinas relacionadas con el propietario legítimo de la cuenta
cat ~/.ssh/authorized_keys

# Revisión del historial de hosts conocidos, que puede revelar
# otros servidores de la infraestructura a los que el usuario
# comprometido se ha conectado previamente
cat ~/.ssh/known_hosts
```

Este último punto ilustra por qué, más allá de la robustez criptográfica del propio protocolo, la seguridad real de un despliegue basado en SSH depende en gran medida de la disciplina operativa que rodea a la gestión de sus claves: dónde se almacenan, con qué protección, durante cuánto tiempo permanecen válidas, y qué alcance tienen dentro de la infraestructura, aspectos que ninguna mejora al propio protocolo puede garantizar por sí sola.
