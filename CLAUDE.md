# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Este repositorio contiene la **configuración de infraestructura** para servicios auto-hospedados de luminessa.net, implementada con Docker Compose. La arquitectura utiliza Caddy como reverse proxy central y redes Docker externas para aislar y conectar servicios de forma segura.

**Propósito del repositorio**: Este repositorio solo contiene configuración de infraestructura (archivos `docker-compose.yml`, `Caddyfile`, etc.) y plantillas de variables de entorno (`.env.example`). NO contiene credenciales reales ni datos persistentes. En el servidor, este repositorio se clona en `/opt/infrastructure/` y se combina con secretos desde `/opt/secrets/` mediante symlinks para formar los directorios de trabajo en `/opt/<servicio>/`.

**Mirrors del repositorio**: Este repositorio está sincronizado en tres ubicaciones para redundancia:
- **luminessa** (principal): `ssh://git@git.luminessa.net:222/sophie/luminessa-infrastructure.git` - Instancia Forgejo auto-hospedada
- **gitea**: `git@gitea.com:sophie.neuenmuller/luminessa-infrastructure.git` - Mirror en Gitea.com
- **github**: `git@github.com:sophieneuenmuller/luminessa-infrastructure.git` - Mirror en GitHub

Los tres repositorios deben mantenerse sincronizados. Usa `git pushall` para hacer push a todos a la vez.

## Arquitectura

### Networking

Todos los servicios utilizan redes Docker externas predefinidas:
- **`proxy`**: Red compartida para servicios que necesitan exposición externa a través de Caddy
- **`database`**: Red privada para conectar servicios con PostgreSQL

Estas redes deben existir antes de iniciar los servicios. Para crearlas:
```bash
docker network create proxy
docker network create database
```

### Caddy Reverse Proxy

Caddy (ubicado en `caddy/`) actúa como punto de entrada único para todos los servicios web. Se ejecuta con usuario `999:1002` y expone:
- Puertos 80/443 (HTTP/HTTPS)
- Puerto 443/udp (HTTP/3 con QUIC)

El archivo `Caddyfile` define las rutas para cada servicio y maneja automáticamente certificados TLS vía Let's Encrypt.

**Rutas configuradas actualmente:**
- `git.luminessa.net` → forgejo:3000
- `blog.luminessa.net` → `/var/www/luminessa-blog` (archivos estáticos)
- `sync.luminessa.net` → syncthing:8384
- `bookmarks.luminessa.net` → grimoire:5173 (con security headers)

Para agregar un nuevo servicio:
1. Añadir el bloque de configuración al `Caddyfile`
2. Validar: `docker exec caddy caddy validate --config /etc/caddy/Caddyfile`
3. Recargar: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

Ejemplo de nueva ruta:
```caddy
subdomain.luminessa.net {
    reverse_proxy service-name:port
}
```

### Servicios

Cada servicio está en su propio directorio con:
- `docker-compose.yml`: Configuración del servicio
- `.env.example`: Plantilla de variables de entorno (cuando aplique)

**Nota importante:** Los archivos `.env` con credenciales reales NUNCA deben commitearse al repositorio.

**Servicios actuales:**

| Servicio | Dominio | Puertos | Base de datos | Notas |
|----------|---------|---------|---------------|-------|
| **forgejo** | git.luminessa.net | 3000 (web), 222 (SSH) | PostgreSQL | Git forge con Actions habilitado |
| **forgejo-runner** | - | - | - | Runner de CI/CD para Forgejo Actions |
| **postgres** | - | 127.0.0.1:5432 | - | PostgreSQL 17.7, solo accesible localmente |
| **syncthing** | sync.luminessa.net | 22000 (sync), 21027/udp (discovery), 8384 (web) | - | Usa `/opt/syncthing/.env` como ruta absoluta |
| **grimoire** | bookmarks.luminessa.net | 5173 | SQLite | Gestor de marcadores, storage en volumen |
| **blog** | blog.luminessa.net | - | - | Sitios estáticos desde `/var/www/luminessa-blog` |

## Comandos Comunes

**Nota importante**: Todos los comandos de `docker compose` deben ejecutarse desde los directorios de trabajo en `/opt/<servicio>/`, NO desde el repositorio en `/opt/infrastructure/`.

### Comandos de Git

```bash
# Push a todos los remotes (luminessa, gitea, github)
git pushall

# Push individual a cada remote
git push luminessa main
git push gitea main
git push github main

# Pull desde el remote principal
git pull luminessa main

# Ver todos los remotes configurados
git remote -v

# Ver estado del repositorio
git status
```

### Gestión de Servicios

```bash
# Iniciar un servicio
cd /opt/<servicio>
docker compose up -d

# Ver logs
docker logs <container-name>
docker logs -f <container-name>  # Seguir logs en tiempo real
docker logs --tail 100 <container-name>  # Ver últimas 100 líneas

# Reiniciar un servicio
cd /opt/<servicio>
docker compose restart

# Detener un servicio
cd /opt/<servicio>
docker compose down

# Actualizar imágenes y reiniciar
cd /opt/<servicio>
docker compose pull
docker compose up -d

# Verificar estado de un container
docker ps | grep <container-name>
docker inspect <container-name>
```

### Gestión de Redes

```bash
# Listar redes Docker
docker network ls

# Ver qué containers están en una red
docker network inspect proxy
docker network inspect database

# Crear las redes necesarias (si no existen)
docker network create proxy
docker network create database

# Conectar un container a una red (si es necesario)
docker network connect proxy <container-name>
```

### Recargar Caddy

Después de modificar el Caddyfile:
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

Para validar la sintaxis antes de recargar:
```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

### Gestión de PostgreSQL

```bash
# Conectarse a PostgreSQL (requiere credenciales del .env)
docker exec -it postgres psql -U <POSTGRES_USER>

# Crear una nueva base de datos para un servicio
CREATE DATABASE dbname;
CREATE USER username WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE dbname TO username;

# Listar bases de datos
docker exec -it postgres psql -U <POSTGRES_USER> -c '\l'

# Backup de una base de datos
docker exec postgres pg_dump -U <POSTGRES_USER> <DB_NAME> > backup.sql

# Restaurar un backup
cat backup.sql | docker exec -i postgres psql -U <POSTGRES_USER> <DB_NAME>
```

### Backups

La estrategia de backup cubre tres áreas:

**1. Código de infraestructura** (`/opt/infrastructure/`):
- Versionado en git, no requiere backup tradicional
- Se restaura simplemente clonando el repositorio

**2. Secretos** (`/opt/secrets/`):
```bash
# Backup de secretos (DEBE ser cifrado)
sudo tar czf secrets-backup-$(date +%Y%m%d).tar.gz -C /opt secrets/

# Restaurar secretos
sudo tar xzf secrets-backup.tar.gz -C /opt/
```

**3. Datos persistentes de servicios** (volúmenes Docker y directorios de datos):
```bash
# Backup de volumen Docker nombrado
docker run --rm -v <volume-name>:/data -v $(pwd):/backup alpine \
  tar czf /backup/<volume-name>-$(date +%Y%m%d).tar.gz -C /data .

# Backup de directorio de datos (ejemplo: forgejo)
sudo tar czf forgejo-data-$(date +%Y%m%d).tar.gz -C /opt/forgejo data/

# Restaurar volumen Docker
docker run --rm -v <volume-name>:/data -v $(pwd):/backup alpine \
  sh -c "cd /data && tar xzf /backup/backup.tar.gz"

# Restaurar directorio de datos
sudo tar xzf forgejo-data-backup.tar.gz -C /opt/forgejo/
```

**Qué respaldar por servicio:**
- **PostgreSQL**: `/opt/postgres/data/` o usar `pg_dump` (ver sección PostgreSQL)
- **Forgejo**: `/opt/forgejo/data/`
- **Grimoire**: Volumen Docker `grimoire-data`
- **Syncthing**: `/opt/syncthing/config/` y `/opt/syncthing/data/`
- **Caddy**: `/opt/caddy/data/` (certificados TLS) y `/opt/caddy/config/`
- **Secretos**: `/opt/secrets/` (CRÍTICO, debe estar cifrado)

## Seguridad

### Principios aplicados

- **Principio de privilegio mínimo**: Todos los servicios se ejecutan con permisos restringidos
- **Separación de secretos**: Las credenciales están físicamente separadas del código versionado
  - Infraestructura en `/opt/infrastructure/` (versionada en git)
  - Secretos en `/opt/secrets/` (solo en backups cifrados, NUNCA en git)
- **Aislamiento de red**: Uso de redes Docker segregadas (`proxy`, `database`)
- **Acceso restringido a base de datos**: PostgreSQL solo accesible desde localhost (bind: `127.0.0.1:5432`)
- **TLS automático**: Caddy maneja certificados TLS vía Let's Encrypt
- **Permisos de filesystem**: Usuarios de containers especificados con PUID/PGID para evitar escalación

### Seguridad por servicio

- **Caddy**: Maneja todos los certificados TLS, renovación automática
- **Forgejo**: Registro público deshabilitado (`DISABLE_REGISTRATION=true`), SSH en puerto no estándar (222)
- **Grimoire**:
  - Security headers en Caddyfile (X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
  - Registro debe deshabilitarse después de crear cuenta admin
- **PostgreSQL**: Solo escucha en localhost, credenciales por servicio separadas
- **Syncthing**: Datos cifrados en `/opt/syncthing/data`

### Protección de secretos

**CRÍTICO**: Los archivos en `/opt/secrets/` contienen credenciales reales y NUNCA deben:
- Commitearse a git
- Enviarse por canales no cifrados
- Tener permisos de lectura para usuarios no autorizados

```bash
# Verificar permisos de secretos
ls -la /opt/secrets/*/

# Deberían ser 600 (rw-------) o 640 con grupo restringido
sudo chmod 600 /opt/secrets/*/.env
```

### Backups de secretos

Los backups de `/opt/secrets/` deben:
1. Estar cifrados (ejemplo: GPG, LUKS, o cifrado de Syncthing)
2. Almacenarse en ubicación segura separada
3. Tener acceso restringido solo a administradores autorizados

## Problemas Conocidos

**Forgejo docker-compose.yml** (`forgejo/docker-compose.yml:6-7`):
- Hay un bug donde `USER_UID=${PGID}` aparece en la línea 7, cuando debería ser `USER_GID=${PGID}`
- Actualmente ambas líneas 6 y 7 dicen `USER_UID`, lo cual es incorrecto
- Esto podría causar que el GID no se configure correctamente

## Workflow de Git

### Hacer cambios y sincronizar

Cuando hagas cambios a la infraestructura, **SIEMPRE** debes hacer push a los tres repositorios para mantenerlos sincronizados:

```bash
# Hacer cambios
git add .
git commit -m "Descripción del cambio"

# Push a todos los remotes (IMPORTANTE: siempre usar este comando)
git pushall main

# O manualmente a cada uno
git push luminessa main
git push gitea main
git push github main
```

### Verificar sincronización

```bash
# Ver el último commit en cada remote
git ls-remote luminessa main
git ls-remote gitea main
git ls-remote github main
```

## Variables de Entorno

Los archivos `.env` con credenciales reales se almacenan en `/opt/secrets/<servicio>/.env` en el servidor (NO en git, solo en backups). El repositorio proporciona archivos `.env.example` como plantillas.

### Ubicaciones

- **En el repositorio**: `/opt/infrastructure/<servicio>/.env.example` (plantilla versionada)
- **En el servidor**: `/opt/secrets/<servicio>/.env` (credenciales reales en backup)
- **En directorio de trabajo**: `/opt/<servicio>/.env` → symlink a `/opt/secrets/<servicio>/.env`

### Configuración por servicio

**PostgreSQL** (`postgres/.env.example`):
```bash
PUID=1000  # Usuario del sistema
PGID=1000  # Grupo del sistema
POSTGRES_USER=usuario
POSTGRES_PASSWORD=contraseña_segura
```

**Forgejo** (`forgejo/.env.example`):
```bash
PUID=1000
PGID=1000
FORGEJO_DB_NAME=nombre_db
FORGEJO_DB_USER=usuario_db
FORGEJO_DB_PASSWORD=contraseña_db
```

**Grimoire** (`grimoire/.env.example`):
```bash
GRIMOIRE_SIGNUP_DISABLED=false  # Cambiar a true después de crear cuenta admin
```

**Syncthing**: No tiene `.env.example` en el repositorio. Su `docker-compose.yml` usa `env_file: /opt/syncthing/.env` apuntando directamente al directorio de trabajo.

### Crear un .env para un nuevo servicio

```bash
# Copiar plantilla desde el repositorio
cp /opt/infrastructure/<servicio>/.env.example /opt/secrets/<servicio>/.env

# Editar con credenciales reales
nano /opt/secrets/<servicio>/.env

# Crear symlink en el directorio de trabajo
cd /opt/<servicio>
ln -s /opt/secrets/<servicio>/.env .
```

### Patrón común de variables

- `PUID`/`PGID`: UID/GID del usuario del sistema que ejecutará el container (evita problemas de permisos en volúmenes)
- `POSTGRES_USER`/`POSTGRES_PASSWORD`: Credenciales master de PostgreSQL
- `<SERVICE>_DB_NAME`/`<SERVICE>_DB_USER`/`<SERVICE>_DB_PASSWORD`: Credenciales específicas por servicio que usa PostgreSQL

## Estructura de Deployment

### Arquitectura del servidor

El servidor sigue una arquitectura que separa código de infraestructura (versionado con git) de datos sensibles (en backups):

```
/opt/
├── infrastructure/          # Clon de este repositorio git
│   ├── caddy/
│   │   ├── docker-compose.yml
│   │   ├── Caddyfile
│   │   └── .env.example
│   ├── forgejo/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── ...
│
├── secrets/                 # NO está en git, solo en backups
│   ├── caddy/
│   │   └── .env            # Credenciales reales
│   ├── forgejo/
│   │   └── .env
│   ├── syncthing/
│   │   └── .env
│   └── ...
│
├── caddy/                   # Directorio de trabajo del servicio
│   ├── docker-compose.yml  → symlink a /opt/infrastructure/caddy/docker-compose.yml
│   ├── Caddyfile          → symlink a /opt/infrastructure/caddy/Caddyfile
│   ├── .env               → symlink a /opt/secrets/caddy/.env
│   ├── data/              # Volúmenes persistentes (no en git)
│   └── config/
│
├── forgejo/
│   ├── docker-compose.yml  → symlink a /opt/infrastructure/forgejo/docker-compose.yml
│   ├── .env               → symlink a /opt/secrets/forgejo/.env
│   └── data/
│
└── syncthing/
    ├── docker-compose.yml  → symlink a /opt/infrastructure/synthing/docker-compose.yml
    ├── .env               → symlink a /opt/secrets/syncthing/.env
    ├── config/
    └── data/
```

### Filosofía de la arquitectura

1. **Separación de concerns**:
   - `/opt/infrastructure/`: Configuración de infraestructura (versionada en git)
   - `/opt/secrets/`: Datos sensibles (passwords, API keys, usuarios) - solo en backups
   - `/opt/<servicio>/`: Directorios de trabajo con symlinks y datos persistentes

2. **Ventajas**:
   - Todo el código de infraestructura tiene seguimiento por git
   - Los secretos nunca se commitean accidentalmente
   - Fácil restauración: clonar repo + restaurar backup + crear symlinks + levantar servicios
   - Los cambios a la infraestructura se pueden versionar y revertir

3. **Nota sobre rutas absolutas**: Algunos servicios como `syncthing` tienen rutas absolutas en su `docker-compose.yml` (ej: `env_file: /opt/syncthing/.env`) porque el archivo se diseñó para el directorio de trabajo, no para el repositorio.

### Agregar un nuevo servicio

**En el repositorio (`/opt/infrastructure/`):**

1. Crear directorio `<servicio>/` con:
   - `docker-compose.yml` con la configuración del servicio
   - `.env.example` si requiere variables de entorno sensibles
   - Otros archivos de configuración necesarios

2. Configurar redes en el docker-compose.yml:
   - Red `proxy`: Para servicios que necesitan exposición web vía Caddy
   - Red `database`: Para servicios que consumen PostgreSQL

3. Si necesita exposición web:
   - Añadir bloque de configuración en `caddy/Caddyfile`

**En el servidor:**

4. Crear estructura de directorios:
   ```bash
   sudo mkdir -p /opt/<servicio>
   sudo mkdir -p /opt/secrets/<servicio>
   ```

5. Crear archivo de secretos:
   ```bash
   # Copiar plantilla y editar
   cp /opt/infrastructure/<servicio>/.env.example /opt/secrets/<servicio>/.env
   nano /opt/secrets/<servicio>/.env
   ```

6. Crear symlinks:
   ```bash
   cd /opt/<servicio>
   ln -s /opt/infrastructure/<servicio>/docker-compose.yml .
   ln -s /opt/secrets/<servicio>/.env .
   # Crear symlinks para otros archivos de configuración según sea necesario
   ```

7. Iniciar servicio:
   ```bash
   cd /opt/<servicio>
   docker compose up -d
   ```

8. Si es un servicio web, recargar Caddy:
   ```bash
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

### Configuración del repositorio clonado

Después de clonar el repositorio, configura los remotes y el alias de push:

```bash
cd /opt/infrastructure

# Agregar todos los remotes (si clonaste desde uno solo)
git remote add luminessa ssh://git@git.luminessa.net:222/sophie/luminessa-infrastructure.git
git remote add gitea git@gitea.com:sophie.neuenmuller/luminessa-infrastructure.git
git remote add github git@github.com:sophieneuenmuller/luminessa-infrastructure.git

# Crear alias para push a todos los remotes
git config --local alias.pushall '!git push luminessa "$@" && git push gitea "$@" && git push github "$@"'
```

### Procedimiento de restauración completa

Este es el flujo para restaurar la infraestructura en un servidor nuevo:

1. Clonar el repositorio:
   ```bash
   cd /opt
   git clone ssh://git@git.luminessa.net:222/sophie/luminessa-infrastructure.git infrastructure
   # O desde cualquier otro mirror: gitea o github
   ```

2. Configurar remotes y alias (ver sección anterior)

3. Restaurar backup de secretos:
   ```bash
   # Restaurar /opt/secrets/ desde backup
   tar xzf secrets-backup.tar.gz -C /opt/
   ```

4. Crear redes Docker:
   ```bash
   docker network create proxy
   docker network create database
   ```

5. Para cada servicio, crear directorio de trabajo y symlinks:
   ```bash
   # Ejemplo para caddy
   mkdir -p /opt/caddy
   cd /opt/caddy
   ln -s /opt/infrastructure/caddy/docker-compose.yml .
   ln -s /opt/infrastructure/caddy/Caddyfile .
   ln -s /opt/secrets/caddy/.env .
   ```

6. Levantar servicios en orden:
   ```bash
   # Primero la base de datos
   cd /opt/postgres && docker compose up -d

   # Luego Caddy
   cd /opt/caddy && docker compose up -d

   # Finalmente los demás servicios
   cd /opt/forgejo && docker compose up -d
   cd /opt/syncthing && docker compose up -d
   # etc...
   ```

**Nota**: Eventualmente este proceso se automatizará con un script de restauración.

## Troubleshooting

### El servicio no puede conectarse a PostgreSQL

1. Verificar que el container de PostgreSQL está corriendo: `docker ps | grep postgres`
2. Verificar que ambos containers están en la red `database`: `docker network inspect database`
3. Verificar credenciales en el `.env` del servicio
4. Revisar logs de PostgreSQL: `docker logs postgres`

### No puedo acceder a un servicio vía dominio

1. Verificar que el container está corriendo: `docker ps`
2. Verificar que está en la red `proxy`: `docker network inspect proxy`
3. Verificar que el Caddyfile tiene la configuración: `docker exec caddy cat /etc/caddy/Caddyfile`
4. Verificar logs de Caddy: `docker logs caddy`
5. Probar acceso directo al puerto: `curl http://localhost:<puerto>`

### Problemas de permisos en volúmenes

Los servicios usan PUID/PGID para mapear el usuario del container al usuario del sistema host:

```bash
# Verificar el UID/GID del usuario actual
id

# Ajustar ownership de un volumen (si es necesario)
sudo chown -R 1000:1000 /ruta/al/volumen

# Para servicios que usan volúmenes Docker nombrados
docker volume inspect <volume-name>
# Luego ajustar permisos en el Mountpoint mostrado
```

### Caddy no recarga la configuración

```bash
# Validar sintaxis primero
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Si hay errores de sintaxis, corregirlos antes de recargar
# Una vez válido, recargar
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Container reinicia constantemente

```bash
# Ver logs para identificar el error
docker logs <container-name>

# Verificar variables de entorno
docker inspect <container-name> | grep -A 20 '"Env"'

# Verificar que las redes existen
docker network ls | grep -E "proxy|database"
```

## Licencia

Este proyecto está licenciado bajo AGPL-3.0-or-later. Cualquier modificación debe mantener la misma licencia.
