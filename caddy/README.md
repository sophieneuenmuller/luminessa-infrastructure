# Caddy: The Front Door / La Puerta de Entrada

[English](#english) | [Español](#español)

---

## English

### 1. Introduction

Caddy serves as the **Front Door (Edge Proxy)** for the entire Luminessa lab. It is the single point of entry for all external traffic, responsible for routing requests to the appropriate internal services.

**Why Caddy?**

* **Simplicity:** A human-readable configuration (Caddyfile) that is easy to maintain and version control.
* **Automatic TLS:** Out-of-the-box HTTPS via Let's Encrypt or ZeroSSL, eliminating the manual toil of certificate management.
* **Modern Performance:** Written in Go, it provides a fast, memory-safe, and highly concurrent foundation for our infrastructure.

### 2. Configuration Management

To maintain a "Single Source of Truth," Caddy follows our centralized environment strategy:

* **Secrets & Env Vars:** Managed via the root `.env` file.
* **Symlink Strategy:** A symlink from the root `.env` to `caddy/.env` ensures that environment variables are shared without duplication, keeping secrets secure and centralized.

### 3. Security Focus (Pragmatic Security)

We don't just add headers for the sake of it; we apply **Pragmatic Security** to mitigate real-world risks while maintaining usability.

* **Security Headers:** Standard headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`) are applied to prevent common attacks like clickjacking and MIME-sniffing.
* **Request Body Limits:** Explicit `max_size` limits (e.g., 10MB for Forgejo) are set to prevent "Large Payload" attacks that could exhaust server resources (DoS).

### 4. Operational Guide

Practical commands for day-to-day SysAdmin operations:

```bash
# Validate Caddyfile syntax before applying changes
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload configuration without downtime (Graceful Reload)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check current running configuration
docker exec caddy caddy config

# Monitor logs in real-time
docker logs -f caddy --tail 100

# If a configuration change does not take effect, force a full restart
docker compose down && docker compose up -d
```

### 5. Troubleshooting

* **Certificate Failures:** Check internet connectivity and Caddy logs for ACME errors:
  `docker logs caddy | grep -i "acme"`
* **Service Unreachable:** Ensure the target container is on the `proxy` network:
  `docker network inspect proxy`
* **Config Not Applying:** Always `validate` before `reload`. If `reload` fails, the old config remains active.

### 6. Roadmap: Future Hardening

My infrastructure is a **Perpetual Work in Progress**. The following enhancements are planned for future iterations:

* **Advanced Rate Limiting:** Implementing `caddy-ratelimit` for granular IP-based protection on sensitive endpoints (/login, /api).
* **Strict Hardening:** Gradual rollout of `Strict-Transport-Security` (HSTS) and `Content-Security-Policy` (CSP) once service compatibility is fully verified.
* **Structured Logging:** Transitioning to JSON-formatted access logs for better integration with log aggregators.

---

## Español

### 1. Introducción

Caddy actúa como la **Front Door (Edge Proxy)** de todo el laboratorio Luminessa. Es el punto único de entrada para todo el tráfico externo, encargado de dirigir las peticiones a los servicios internos correspondientes.

**¿Por qué Caddy?**

* **Simplicidad:** Una configuración legible por humanos (Caddyfile) fácil de mantener y versionar.
* **TLS Automático:** HTTPS nativo vía Let's Encrypt o ZeroSSL, eliminando el trabajo manual de gestión de certificados.
* **Rendimiento Moderno:** Escrito en Go, proporciona una base rápida, segura en memoria y altamente concurrente para nuestra infraestructura.

### 2. Gestión de Configuración

Para mantener una "Fuente Única de Verdad", Caddy sigue nuestra estrategia de entorno centralizada:

* **Secretos y Variables de Entorno:** Gestionados vía el archivo `.env` en la raíz.
* **Estrategia de Symlinks:** Un enlace simbólico desde el `.env` raíz hacia `caddy/.env` asegura que las variables se compartan sin duplicación, manteniendo los secretos seguros y centralizados.

### 3. Foco en Seguridad (Seguridad Pragmática)

No añadimos cabeceras por deporte; aplicamos **Seguridad Pragmática** para mitigar riesgos reales manteniendo la usabilidad.

* **Security Headers:** Se aplican cabeceras estándar (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`) para prevenir ataques comunes como clickjacking y MIME-sniffing.
* **Límites de Body:** Se establecen límites explícitos de `max_size` (ej: 10MB para Forgejo) para prevenir ataques de "Large Payload" que podrían agotar los recursos del servidor (DoS).

### 4. Guía Operativa

Comandos prácticos para operaciones diarias de SysAdmin:

```bash
# Validar la sintaxis del Caddyfile antes de aplicar cambios
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Recargar configuración sin tiempo de inactividad (Graceful Reload)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Ver la configuración actual en ejecución
docker exec caddy caddy config

# Monitorear logs en tiempo real
docker logs -f caddy --tail 100

# Si un cambio en la configuración no surte efecto, forzar un reinicio completo
docker compose down && docker compose up -d
```

### 5. Troubleshooting

* **Fallos de Certificados:** Verificar conectividad a internet y buscar errores ACME en los logs:
  `docker logs caddy | grep -i "acme"`
* **Servicio Inalcanzable:** Asegurarse de que el contenedor destino esté en la red `proxy`:
  `docker network inspect proxy`
* **Cambios no Aplicados:** Siempre `validate` antes de `reload`. Si el `reload` falla, la configuración anterior sigue activa.

### 6. Roadmap: Futuro Hardening

Mi infraestructura es un **Trabajo en Progreso Perpetuo**. Las siguientes mejoras están planeadas para futuras iteraciones:

* **Rate Limiting Avanzado:** Implementación de `caddy-ratelimit` para protección granular basada en IP en endpoints sensibles (/login, /api).
* **Hardening Estricto:** Despliegue gradual de `Strict-Transport-Security` (HSTS) y `Content-Security-Policy` (CSP) una vez verificada la compatibilidad total.
* **Logging Estructurado:** Transición a logs de acceso en formato JSON para mejor integración con agregadores de logs.
