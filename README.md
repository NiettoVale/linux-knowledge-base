<div align="center">

# Linux Knowledge Base

Base de conocimientos personal sobre **Linux**: teoría, ejercicios, proyectos y scripts que voy recopilando a medida que aprendo. Reúne apuntes de cursos, cosas que descubro resolviendo máquinas y retos, y utilidades que me resultan prácticas en el día a día.

Está orientada a **Linux y ciberseguridad**, y es un repositorio **vivo**: crece de forma continua conforme incorporo temas nuevos.

<br>

![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-1793D1?style=for-the-badge&logo=linux&logoColor=white)
![Docs](https://img.shields.io/badge/Docs-16-7000FF?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-FF0080?style=for-the-badge)

</div>

<div align="center">

## Contenido

</div>

El repositorio se organiza en tres bloques:

| Directorio   | Qué contiene                                                                 |
|--------------|------------------------------------------------------------------------------|
| `docs/`      | **Teoría y apuntes**: notas ordenadas por tema sobre Linux y ciberseguridad. |
| `scripts/`   | **Scripts y proyectos**: utilidades sueltas y proyectos más completos.       |
| `exercise/`  | **Ejercicios**: prácticas y retos para afianzar lo aprendido.                |

<div align="center">

## Teoría (`docs/`)

</div>

Apuntes en Markdown, numerados por orden de aprendizaje:

| #  | Documento | Tema |
|----|-----------|------|
| 00 | [Glosario](docs/00-glosario.md) | Glosario de comandos de Linux |
| 01 | [Comandos básicos](docs/01-comandos-basicos.md) | Comandos básicos orientados a ciberseguridad |
| 02 | [Control de la shell](docs/02-control-de-la-shell.md) | Control de flujo y redirecciones en Bash |
| 03 | [Permisos](docs/03-permisos.md) | Permisos en Linux |
| 04 | [Capabilities](docs/04-capabilities.md) | Linux Capabilities |
| 05 | [Directorios del sistema](docs/05-directorios-de-sistema.md) | Jerarquía de directorios (FHS) |
| 06 | [Búsquedas](docs/06-busquedas.md) | `find`, `locate` y `xargs` |
| 07 | [Conexiones SSH](docs/07-conexiones-ssh.md) | SSH (Secure Shell) |
| 08 | [Manejo avanzado de ficheros](docs/08-manejo-avanzado-ficheros-linux.md) | Lectura, filtrado y decodificación |
| 09 | [Descompresión recursiva](docs/09-descompresion-recursiva.md) | `sponge`, descompresión recursiva y dumps hexadecimales |
| 10 | [Claves SSH](docs/10-claves-ssh.md) | Autenticación sin contraseñas |
| 11 | [Conexiones con Netcat](docs/11-conexiones-con-netcat.md) | Netcat y conexiones de red |
| 12 | [Diagnóstico y SUID/SGID](docs/12-diagnostico-shells-suid-netcat.md) | Diagnóstico, shells restringidas y explotación de SUID/SGID |
| 13 | [Tareas programadas](docs/13-tareas-programadas.md) | Cron: programación de tareas |
| 14 | [Escapando del contexto](docs/14-escapando-del-contexto.md) | Escape de contextos restringidos hacia una shell completa |
| 15 | [Argumentos posicionales](docs/15-argumentos-posicionales.md) | Argumentos posicionales en Bash |

<div align="center">

## Scripts y proyectos (`scripts/`)

</div>

### Proyectos

- **[proyecto-1 — htbmachines](scripts/proyecto-1/)**: CLI en Bash para consultar las máquinas de Hack The Box (búsqueda por nombre, IP, dificultad, S.O., skills, enlace de YouTube y actualización de la base de datos). Proyecto modularizado con su propio [README](scripts/proyecto-1/README.md).

### Scripts sueltos

- **[decompressor.sh](scripts/decompressor.sh)**: descompresión recursiva automática de ficheros anidados con `7z`.

<div align="center">

## Ejercicios (`exercise/`)

</div>

Espacio reservado para prácticas y retos con los que consolidar la teoría. Se irá poblando a medida que avance.

<div align="center">

## Cómo usar este repositorio

</div>

```bash
git clone https://github.com/NiettoVale/linux-knowledge-base
cd linux-knowledge-base
```

- La **teoría** se lee directamente desde `docs/` en cualquier visor de Markdown.
- Cada **proyecto** incluye su propio README con instrucciones de instalación y uso.
- Los **scripts** están escritos en Bash; revisá su cabecera para conocer dependencias antes de ejecutarlos.

<div align="center">

## Sobre este repositorio

</div>

Es una base de conocimientos **en construcción permanente**. Parte del contenido proviene de cursos y formaciones (debidamente acreditados en cada proyecto o documento), y otra parte de la experiencia adquirida resolviendo máquinas, retos y trasteando con el sistema. El objetivo es tener un lugar único donde centralizar y consultar todo lo aprendido sobre Linux.

<div align="center">

Autor: **Valentín Francisco Nieto** ([NiettoVale](https://github.com/NiettoVale)) · Distribuido bajo licencia **MIT**.

</div>
