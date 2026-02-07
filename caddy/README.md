# Caddy Configuration

Caddy actúa como reverse proxy central y maneja automáticamente certificados TLS vía Let's Encrypt.

## Estructura

```
caddy/
├── Caddyfile           # Configuración principal
├── docker-compose.yml  # Definición del servicio
├── data/              # Certificados TLS (persistente, no en git)
└── config/            # Configuración de Caddy (persistente, no en git)
```

## Configuración actual

### Servicios expuestos

| Dominio | Backend | Protecciones |
|---------|---------|--------------|
| git.luminessa.net | forgejo:3000 | Headers, body size limit |
| blog.luminessa.net | /var/www/luminessa-blog | Headers (static files) |
| sync.luminessa.net | syncthing:8384 | Headers, body size limit |

### Security Headers

Todos los servicios incluyen:
- `X-Frame-Options: SAMEORIGIN` - Previene clickjacking
- `X-Content-Type-Options: nosniff` - Previene MIME sniffing
- `Referrer-Policy: strict-origin-when-cross-origin` - Protege URLs privadas

### Request Body Limits

Límites de tamaño de peticiones para prevenir ataques de payload grandes:

- **Forgejo**: 10MB para endpoints de login/API
- **Syncthing**: 10MB (maneja archivos grandes internamente vía su propio protocolo)
- **Blog**: Sin límite (archivos estáticos)

## Rate Limiting avanzado

La configuración actual usa límites de tamaño de body como protección básica. Para rate limiting real basado en IPs, necesitas el plugin `caddy-ratelimit`.

### Opción 1: Usar imagen Caddy con plugins

Crear un Dockerfile personalizado:

```dockerfile
# caddy/Dockerfile
FROM caddy:2-builder AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-ratelimit

FROM caddy:2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

Actualizar `docker-compose.yml`:
```yaml
services:
  caddy:
    build: .
    # ... resto de configuración
```

Luego en Caddyfile:
```caddy
git.luminessa.net {
    rate_limit {
        zone git_login {
            key {remote_host}
            events 10
            window 1m
        }
        match {
            path /user/login /api/*
        }
    }
    reverse_proxy forgejo:3000
}
```

### Opción 2: Usar fail2ban (implementado)

Fail2ban complementa Caddy bloqueando IPs a nivel de firewall después de múltiples intentos fallidos.

Ver `fail2ban/README.md` para más detalles.

## Comandos útiles

```bash
# Validar Caddyfile antes de recargar
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Recargar configuración (sin downtime)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Ver configuración actual
docker exec caddy caddy config

# Ver logs
docker logs caddy
docker logs -f caddy --tail 100

# Forzar renovación de certificados (normalmente automático)
docker exec caddy caddy reload --force
```

## Agregar un nuevo servicio

1. Editar `Caddyfile`:
   ```caddy
   newservice.luminessa.net {
       request_body {
           max_size 10MB
       }

       reverse_proxy service-name:port

       header {
           X-Frame-Options "SAMEORIGIN"
           X-Content-Type-Options "nosniff"
           Referrer-Policy "strict-origin-when-cross-origin"
       }
   }
   ```

2. Validar y recargar:
   ```bash
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

3. Asegurarse que el servicio está en la red `proxy`:
   ```yaml
   # En docker-compose.yml del servicio
   networks:
     - proxy
   ```

## Troubleshooting

### Error: "certificate verification failed"

Caddy necesita acceso a internet para obtener certificados de Let's Encrypt. Verifica:
```bash
docker logs caddy | grep -i "certificate\|acme"
```

### Servicio no accesible

1. Verificar que el container está en la red correcta:
   ```bash
   docker network inspect proxy | grep <container-name>
   ```

2. Verificar que el servicio está corriendo:
   ```bash
   docker ps | grep <container-name>
   ```

3. Testear conexión directa al backend:
   ```bash
   docker exec caddy wget -O- http://forgejo:3000
   ```

### Cambios en Caddyfile no se aplican

Asegúrate de recargar Caddy después de cambios:
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

Si hay errores de sintaxis, el reload fallará. Valida primero:
```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## Monitoreo

### Ver peticiones en tiempo real

```bash
docker logs -f caddy
```

### Estadísticas de certificados

```bash
# Ver certificados gestionados
docker exec caddy ls -la /data/caddy/certificates/

# Ver fecha de expiración
docker exec caddy caddy list-certificates
```

## Seguridad adicional

### Headers adicionales recomendados (opcional)

```caddy
header {
    # HSTS - Fuerza HTTPS (implementar con cuidado)
    Strict-Transport-Security "max-age=31536000; includeSubDomains"

    # CSP - Requiere testing extensivo
    # Content-Security-Policy "default-src 'self'"

    # Permissions Policy
    Permissions-Policy "geolocation=(), microphone=(), camera=()"
}
```

**⚠️ Advertencia**: `Strict-Transport-Security` con `preload` es difícil de revertir. Testea primero con `max-age` bajo.

### Logging avanzado

Para habilitar logs de acceso estructurados:

```caddy
git.luminessa.net {
    log {
        output file /var/log/caddy/git-access.log {
            roll_size 100mb
            roll_keep 5
        }
        format json
    }
    # ... resto de configuración
}
```

Luego montar el volumen en docker-compose.yml:
```yaml
volumes:
  - ./logs:/var/log/caddy
```

## Recursos

- [Documentación de Caddy](https://caddyserver.com/docs/)
- [Caddyfile Directives](https://caddyserver.com/docs/caddyfile/directives)
- [Caddy Community Forum](https://caddy.community/)
