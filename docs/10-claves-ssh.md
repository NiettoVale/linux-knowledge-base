# Claves SSH: Autenticación sin Contraseñas

## Introducción: el problema que resuelven las claves SSH

Cuando se establece una conexión SSH, el servidor necesita verificar que quien intenta iniciar sesión efectivamente tiene derecho a hacerlo con la cuenta solicitada. El método más intuitivo y también el más extendido históricamente es pedir una contraseña, pero este enfoque arrastra varios problemas de seguridad y de comodidad operativa: las contraseñas pueden adivinarse mediante ataques de fuerza bruta o de diccionario, pueden reutilizarse entre distintos servicios (de modo que si se filtra en un sitio, queda comprometida en todos los demás donde se usó la misma), y su gestión se vuelve tediosa cuando un mismo administrador necesita acceder con regularidad a decenas o cientos de servidores distintos.

Las claves SSH resuelven este problema sustituyendo el conocimiento de un secreto compartido (la contraseña, que tanto el cliente como el servidor deben "conocer" de alguna forma) por una prueba criptográfica de posesión: el cliente demuestra matemáticamente que posee una clave privada concreta, sin necesidad de revelar jamás esa clave privada al servidor ni a nadie que pudiera estar interceptando la conexión. Este mecanismo no solo es más seguro frente a ataques de adivinación de contraseñas, sino que además permite automatizar conexiones (por ejemplo, en scripts o en integraciones continuas) sin tener que almacenar contraseñas en texto plano en ningún lugar del sistema.

## Criptografía asimétrica: la base conceptual

Para entender por qué esto funciona, es necesario comprender el fundamento matemático sobre el que se apoya: la criptografía asimétrica (también llamada criptografía de clave pública). A diferencia de la criptografía simétrica, donde una misma clave sirve tanto para cifrar como para descifrar un mensaje (y por tanto ambas partes deben compartir ese mismo secreto de antemano, con el riesgo que ello implica si dicho secreto se filtra durante su intercambio), la criptografía asimétrica genera un **par** de claves matemáticamente relacionadas entre sí mediante operaciones matemáticas complejas (en el caso de RSA, basadas en la dificultad de factorizar números muy grandes que son producto de dos números primos; en el caso de algoritmos más modernos como Ed25519, basadas en la aritmética de curvas elípticas), pero con una propiedad fundamental: lo que se cifra con una de las dos claves del par únicamente puede descifrarse con la otra clave del mismo par, y resulta computacionalmente inviable (con la tecnología actual) deducir una clave a partir de la otra.

De este par de claves, una se designa como **clave privada** y debe permanecer siempre en posesión exclusiva de su dueño, sin compartirse jamás bajo ninguna circunstancia; la otra se designa como **clave pública**, y puede distribuirse libremente sin que ello comprometa la seguridad del sistema, precisamente porque conocer la clave pública no permite, en la práctica, deducir cuál es la clave privada correspondiente.

## Generación del par de claves con ssh-keygen

El comando `ssh-keygen` es la utilidad estándar, incluida con cualquier instalación de OpenSSH, encargada de generar este par de claves de forma local en la máquina del usuario. Al ejecutarlo sin ninguna opción adicional, genera por defecto un par de claves RSA y las guarda, salvo que se indique lo contrario, dentro del directorio oculto `~/.ssh/` del usuario que ejecuta el comando.

```bash
# Genera un par de claves RSA con el tamaño por defecto
ssh-keygen

# Genera un par de claves RSA especificando explícitamente
# el algoritmo y una longitud de 4096 bits (recomendable
# frente al valor por defecto de 2048 bits, hoy considerado
# el mínimo aceptable)
ssh-keygen -t rsa -b 4096

# Alternativa moderna y recomendada actualmente frente a RSA:
# Ed25519 ofrece un nivel de seguridad equivalente o superior
# con claves mucho más cortas, generación más rápida y
# resistencia mejorada frente a ciertos ataques de canal lateral
ssh-keygen -t ed25519 -C "fnieto@ntech.studio"
```

Durante la ejecución interactiva de `ssh-keygen`, la herramienta solicita tres datos: la ubicación donde guardar el par de claves (por defecto, `~/.ssh/id_rsa` para el algoritmo RSA, o `~/.ssh/id_ed25519` para Ed25519), y una frase de contraseña opcional (_passphrase_) para proteger la clave privada, que se solicita dos veces para confirmar que se ha escrito correctamente.

```bash
❯ ssh-keygen -t ed25519
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/fnieto/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/fnieto/.ssh/id_ed25519
Your public key has been saved in /home/fnieto/.ssh/id_ed25519.pub
```

Como resultado de este proceso se generan exactamente dos archivos, y resulta fundamental tener clarísimo cuál es cuál y cómo se comporta cada uno:

- **`id_rsa`** (o `id_ed25519`, según el algoritmo elegido): esta es la **clave privada**. Es el secreto que nunca debe compartirse, copiarse a un servidor remoto, subirse a un repositorio de código, ni transmitirse por ningún canal que no esté bajo control absoluto del propio usuario. Por defecto, `ssh-keygen` la crea con permisos `600` (lectura y escritura únicamente para el propietario), y de hecho el propio cliente SSH se niega a utilizar una clave privada cuyos permisos sean más permisivos que ese valor, precisamente como salvaguarda contra configuraciones descuidadas.
- **`id_rsa.pub`** (o `id_ed25519.pub`): esta es la **clave pública** correspondiente. Es un archivo de texto plano, de una única línea, que comienza con el nombre del algoritmo utilizado (por ejemplo `ssh-ed25519` o `ssh-rsa`), seguido de la propia clave codificada en Base64, y opcionalmente un comentario al final (habitualmente el correo electrónico o el nombre de la máquina desde la que se generó, útil para identificar de un vistazo a qué persona o equipo pertenece esa clave cuando se administran muchas). Este archivo sí puede y debe compartirse: es precisamente lo que se instala en cada servidor al que se desea acceder mediante esta clave.

```bash
# Contenido típico de una clave pública
❯ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkH8x... fnieto@ntech.studio
```

## El archivo authorized_keys

Para que un servidor SSH acepte la autenticación mediante una clave pública concreta, dicha clave pública debe estar registrada en un archivo específico dentro de la cuenta del usuario al que se desea acceder en ese servidor: `~/.ssh/authorized_keys` (es decir, `/home/<usuario>/.ssh/authorized_keys`). Este archivo es, en esencia, una lista de claves públicas autorizadas: cada línea del archivo representa una clave pública distinta que tiene permiso para iniciar sesión con esa cuenta de usuario, lo cual permite, por ejemplo, que varias personas distintas (cada una con su propio par de claves) puedan acceder legítimamente a una misma cuenta de servidor compartida, simplemente añadiendo la clave pública de cada una en líneas separadas.

```bash
# Estructura del directorio .ssh de un usuario en el servidor
/home/fnieto/.ssh/
├── authorized_keys   # Claves públicas autorizadas a entrar como este usuario
├── known_hosts       # Claves públicas de servidores a los que este usuario se ha conectado
├── id_ed25519        # Clave privada propia del usuario (para conectarse HACIA otros servidores)
└── id_ed25519.pub    # Clave pública propia del usuario
```

Es muy importante no confundir el propósito de `authorized_keys` con el del par de claves propio del usuario: `authorized_keys` almacena claves **públicas ajenas** (o propias, si el usuario se conecta a esa misma cuenta desde otra máquina) que tienen permiso para entrar como ese usuario, mientras que `id_ed25519`/`id_ed25519.pub` es el par de claves que ese usuario utiliza para autenticarse **hacia** otros servidores. Un mismo usuario puede perfectamente tener ambas cosas simultáneamente en su directorio `.ssh`: su propio par de claves para conectarse hacia afuera, y un archivo `authorized_keys` con las claves públicas de quienes tienen permiso para conectarse hacia esa cuenta desde fuera.

```bash
# Añade manualmente el contenido de una clave pública
# al archivo authorized_keys de la cuenta actual
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkH8x... fnieto@ntech.studio" >> ~/.ssh/authorized_keys

# Los permisos del directorio .ssh y del propio archivo
# authorized_keys son igualmente críticos: si son demasiado
# permisivos, sshd puede rechazar la autenticación por clave
# como medida de seguridad, asumiendo que el archivo podría
# haber sido manipulado por otro usuario del sistema
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## ssh-copy-id: automatizando la instalación de la clave pública

Copiar manualmente el contenido de una clave pública y añadirlo al `authorized_keys` remoto, asegurándose además de crear el directorio `.ssh` si no existiera y de establecer los permisos correctos, es un proceso propenso a pequeños errores. Para automatizarlo, OpenSSH incluye la utilidad `ssh-copy-id`, que realiza automáticamente todos estos pasos en una sola invocación.

Conviene aclarar con precisión quién ejecuta este comando y desde dónde, ya que es un punto que se presta a confusión: `ssh-copy-id` lo ejecuta el **cliente**, es decir, la persona que quiere poder conectarse sin contraseña a un servidor remoto, y lo ejecuta desde su propia máquina, indicando la clave pública que desea instalar y la cuenta del servidor remoto donde quiere instalarla. El comando se conecta al servidor remoto (en este primer paso, todavía pidiendo la contraseña de la cuenta remota, ya que aún no existe la clave instalada) y, una vez autenticado, añade la clave pública indicada al `authorized_keys` de esa cuenta remota.

```bash
# El USUARIO CLIENTE ejecuta esto desde SU PROPIA máquina.
# Le pedirá la contraseña de la cuenta remota UNA ÚLTIMA VEZ,
# y a partir de ese momento podrá conectarse sin contraseña
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@maquina_remota

# A partir de aquí, las siguientes conexiones ya no piden contraseña,
# porque la clave pública ya quedó registrada en el servidor remoto
ssh usuario@maquina_remota
```

Es importante notar que la opción `-i` de `ssh-copy-id` espera recibir la ruta de la clave **pública** (o, si se omite la extensión `.pub`, `ssh-copy-id` la añade automáticamente por convención), nunca la clave privada, ya que el propósito de este comando es precisamente instalar la parte pública del par en el servidor remoto. Cuando posteriormente se quiera efectivamente iniciar sesión utilizando ese par de claves (y no la clave por defecto que el cliente SSH intentaría usar automáticamente), se especifica explícitamente la clave **privada** correspondiente mediante la opción `-i` del propio comando `ssh`, no de `ssh-copy-id`:

```bash
# Aquí SÍ se indica la clave PRIVADA, porque es el propio
# cliente quien debe demostrar que la posee durante la conexión
ssh -i ~/.ssh/id_ed25519 usuario@maquina_remota
```

Si `ssh-copy-id` no estuviera disponible en el sistema (por ejemplo, en algunos entornos mínimos o en macOS sin instalarlo manualmente), el mismo resultado puede lograrse de forma completamente manual, combinando `cat` con una conexión SSH que ejecuta el comando de creación del archivo remoto:

```bash
# Forma manual, equivalente a ssh-copy-id, cuando esta
# utilidad no está disponible en el sistema
cat ~/.ssh/id_ed25519.pub | ssh usuario@maquina_remota \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

## Cómo funciona realmente la autenticación (más allá de la analogía del cifrado)

Las notas de partida describen el mecanismo de autenticación diciendo que "la clave pública puede usarse para cifrar mensajes que solo la clave privada puede descifrar", lo cual es una descripción conceptualmente correcta de una de las propiedades de la criptografía asimétrica, pero conviene precisar cómo se aplica exactamente esta propiedad dentro del protocolo SSH, ya que el mecanismo real es ligeramente distinto (y más eficiente) que "cifrar un mensaje completo" en cada conexión.

En lugar de que el servidor cifre un mensaje con la clave pública del cliente y el cliente lo descifre con su clave privada para demostrar que la posee (que sería un enfoque válido pero no es exactamente el que usa SSH), el protocolo SSH utiliza un esquema de **desafío-respuesta basado en firma digital**, que aprovecha la misma propiedad matemática subyacente pero aplicada de forma inversa a la del cifrado tradicional: en lugar de cifrar con la pública y descifrar con la privada, se **firma** con la clave privada, y esa firma puede **verificarse** con la clave pública correspondiente, sin que la clave privada llegue jamás a salir de la máquina del cliente.

El proceso, simplificado, ocurre así: una vez que el cliente indica al servidor con qué clave pública desea autenticarse (y el servidor comprueba que efectivamente esa clave pública figura en el `authorized_keys` de la cuenta solicitada), el servidor genera un valor aleatorio único para esa sesión concreta (el "desafío"). El cliente, utilizando su clave privada, calcula una firma digital sobre ese desafío (una operación matemática que solo puede realizarse correctamente si se posee la clave privada correspondiente a la clave pública anunciada) y envía esa firma de vuelta al servidor. El servidor, que únicamente posee la clave pública, verifica matemáticamente si esa firma es válida para el desafío que él mismo generó y para la clave pública registrada; si la verificación es correcta, el servidor tiene la certeza matemática de que quien está al otro lado de la conexión posee efectivamente la clave privada correspondiente, sin que dicha clave privada haya tenido que transmitirse ni exponerse en ningún momento del proceso.

Esta distinción entre "cifrar/descifrar" y "firmar/verificar" es más que un matiz técnico: es la razón por la cual algoritmos como Ed25519, que están específicamente diseñados y optimizados para operaciones de firma digital (y no para cifrado de propósito general), son perfectamente válidos y de hecho recomendables para claves SSH, a pesar de que conceptualmente "cifrar y descifrar un mensaje completo" no sea su operación nativa principal.

## Protección de la clave privada mediante passphrase

Dado que la clave privada es, en última instancia, el único secreto que determina si alguien puede o no autenticarse como un usuario determinado en todos los servidores donde su clave pública correspondiente esté registrada, su protección resulta crítica. Si un atacante lograse copiar el archivo de la clave privada de un usuario (por ejemplo, mediante malware, una copia de seguridad mal protegida, o el robo físico de un dispositivo), y esa clave privada no estuviera protegida de ninguna forma adicional, dicho atacante podría inmediatamente hacerse pasar por el usuario legítimo en cualquier servidor donde la clave pública correspondiente estuviera autorizada, sin necesidad de conocer ninguna contraseña adicional.

La _passphrase_ opcional que `ssh-keygen` permite establecer al generar el par de claves no es un mecanismo de autenticación adicional frente al servidor (el servidor nunca ve ni conoce esta passphrase, ya que jamás sale de la máquina del cliente), sino un mecanismo de **cifrado local** de la propia clave privada en el disco del cliente: el archivo de la clave privada se almacena cifrado, y para poder utilizarlo (es decir, para poder calcular la firma digital descrita en la sección anterior) es necesario primero descifrarlo introduciendo la passphrase correcta. Esto añade una capa adicional de defensa: aunque un atacante lograse copiar el archivo de la clave privada, no podría utilizarlo sin conocer también la passphrase con la que fue protegida, de la misma forma en que copiar una caja fuerte cerrada no sirve de nada sin también conocer su combinación.

```bash
# Al conectarse usando una clave protegida con passphrase,
# el cliente SSH la solicita antes de poder usar la clave
❯ ssh -i ~/.ssh/id_ed25519_protegida usuario@servidor
Enter passphrase for key '/home/fnieto/.ssh/id_ed25519_protegida':
```

Para no tener que introducir la passphrase en cada conexión individual (lo cual, sin este mecanismo, anularía buena parte de la comodidad que las claves SSH ofrecen frente a las contraseñas), existe `ssh-agent`, un proceso en segundo plano que, una vez que se le proporciona la passphrase una única vez, mantiene la clave privada descifrada en memoria durante el resto de la sesión del usuario, firmando los desafíos de autenticación en nombre del cliente sin necesidad de volver a pedir la passphrase en cada nueva conexión.

```bash
# Inicia el agente SSH (en muchos entornos de escritorio
# ya se inicia automáticamente al iniciar sesión gráfica)
eval "$(ssh-agent -s)"

# Carga la clave privada en el agente, pidiendo la passphrase
# una única vez para el resto de la sesión actual
ssh-add ~/.ssh/id_ed25519_protegida
```

## Buenas prácticas y recomendaciones

A modo de resumen práctico, conviene remarcar algunas recomendaciones que se derivan directamente de todo lo explicado. En primer lugar, generar siempre las claves con un algoritmo moderno (Ed25519 como primera opción, o RSA de al menos 4096 bits si se necesita compatibilidad con sistemas muy antiguos), evitando algoritmos obsoletos como DSA, considerado inseguro desde hace años. En segundo lugar, proteger siempre la clave privada con una passphrase robusta, particularmente en equipos portátiles o compartidos, apoyándose en `ssh-agent` para no perder comodidad operativa. En tercer lugar, utilizar un par de claves distinto para cada contexto o entorno relevante (por ejemplo, una clave para servidores personales y otra completamente distinta para servidores de un entorno laboral), de modo que la eventual revocación de una clave comprometida no afecte a otros contextos no relacionados. Y finalmente, revisar periódicamente el contenido de `authorized_keys` en los servidores administrados, eliminando claves de personas que ya no deberían tener acceso, de la misma manera en que se revocarían credenciales de acceso físico a una oficina cuando alguien deja de necesitarlas.
