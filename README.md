# Luminessa Infrastructure (Personal Lab)

<a href="#"><img src="https://img.shields.io/static/v1?label=Infrastructure&message=Self-Hosted&color=blue" alt="Infrastructure"></a>
<a href="#"><img src="https://img.shields.io/static/v1?label=Security&message=Hardened&color=green" alt="Security"></a>
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](#english) | [Español](#español)

---

<a name="english"></a>

## 🇬🇧 English

### Core Philosophy: Pragmatism > Over-engineering

This is a **personal infrastructure project** built and maintained by a single person for learning and daily utility. The core principle is finding the sweet spot between industry best practices and realistic maintainability. I prioritize solutions that are robust enough to trust but simple enough to manage in my spare time.

### Dynamic Evolution

This stack is not a static enterprise solution; it is a **perpetual work in progress** that evolves alongside my life needs and technical curiosity. Services are added, removed, or refactored as I discover better tools or as the requirements change in my digital life.

### Configuration Management

To keep the infrastructure manageable and secure, I use a **centralized `.env` strategy**:

* All environment files are stored in a single, protected directory outside the Git tree.
* Each service directory contains a **symlink** to its respective `.env` file.
* **Why?** This provides a single point of truth for all secrets, simplifies backups of sensitive configuration, and makes it easy to audit the entire stack's environment from one location.

### Data Protection

Data integrity is the highest priority. I use **Backrest** (a modern WebUI for Restic) to perform:

* **Daily automated backups** of all critical databases and application volumes.
* **Offsite Replication:** Encrypted snapshots are pushed daily to **Backblaze B2 (free tier)**, ensuring recovery even in the event of local hardware failure. I am still thinking of somewhere else to put backups, just so it does not reside on a single offsite.

### Current Services in Use

The following services form the core of my current setup:

* **Caddy (v2):** Edge proxy with automatic HTTPS and security-hardened headers.
* **Forgejo:** Private Git hosting with integrated Forgejo Actions (CI/CD).
* **PostgreSQL (v17.7):** High-performance relational database, restricted to internal network access.
* **Syncthing:** Continuous, decentralized, and encrypted file synchronization.
* **Fail2ban:** Intrusion prevention monitoring SSH and application logs.

### Installation & Deployment

1. **Environment Setup:** Create your centralized secrets folder and symlink the `.env` files to each service directory.
2. **Network Scaffolding:**
   
   ```bash
   docker network create proxy
   docker network create database
   ```
3. **Launch:** Navigate to any service directory and run `docker compose up -d`.

### Roadmap

- [ ] **Media Management:** Deployment of **Kavita** or **Komga** for personal library hosting.
- [ ] **Monitoring:** Integration of **Prometheus and Grafana** for system health metrics.
- [ ] **Availability:** **Uptime Kuma** for service status notifications and heartbeat monitoring.

---

<a name="español"></a>

## 🇪🇸 Español

### Filosofía Central: Practicidad > Sobre-ingeniería

Este es un **proyecto de infraestructura personal** construido y mantenido por una sola persona para aprendizaje y utilidad diaria. El principio fundamental es encontrar el equilibrio entre las mejores prácticas de la industria y una mantenibilidad realista. Priorizo soluciones que sean lo suficientemente robustas para confiar en ellas, pero lo suficientemente simples para gestionar en mi tiempo libre.

### Evolución Dinámica

Este stack no es una solución empresarial estática; es un **eterno trabajo en progreso** que evoluciona junto con mis necesidades personales y curiosidad técnica. Los servicios se agregan, eliminan o refactorizan a medida que descubro mejores herramientas o a medida que los requisitos cambian en mi vida digital.

### Gestión de Configuración

Para mantener la infraestructura manejable y segura, utilizo una **estrategia de archivos `.env` centralizada**:

* Todos los archivos de entorno se almacenan en un único directorio protegido fuera del árbol de Git.
* Cada directorio de servicio contiene un **enlace simbólico (symlink)** a su respectivo archivo `.env`.
* **¿Por qué?** Esto proporciona un punto único de verdad para todos los secretos, simplifica los backups de configuraciones sensibles y facilita la auditoría de todo el stack desde una sola ubicación.

### Protección de Datos

La integridad de los datos es la máxima prioridad. Utilizo **Backrest** (una interfaz web moderna para Restic) para realizar:

* **Backups automáticos diarios** de todas las bases de datos críticas y volúmenes de aplicaciones.
* **Replicación Externa:** Los snapshots cifrados se envían diariamente a **Backblaze B2 (nivel gratuito)**, asegurando la recuperación incluso en caso de fallo total del hardware local. Actualmente estoy evaluando otras opciones para añadir redundancia y no depender de un único proveedor externo.

### Servicios Actuales en Uso

Los siguientes servicios forman el núcleo de mi configuración actual:

* **Caddy (v2):** Proxy de borde con HTTPS automático y headers de seguridad reforzados.
* **Forgejo:** Hosting de Git privado con CI/CD integrado (Forgejo Actions).
* **PostgreSQL (v17.7):** Base de datos relacional de alto rendimiento, restringida a la red interna.
* **Syncthing:** Sincronización de archivos continua, descentralizada y cifrada.
* **Fail2ban:** Prevención de intrusiones monitoreando logs de SSH y aplicaciones.

### Instalación y Despliegue

1. **Configuración del Entorno:** Crear la carpeta centralizada de secretos y crear los enlaces simbólicos de los archivos `.env` en cada directorio de servicio.
2. **Preparación de Redes:**
   
   ```bash
   docker network create proxy
   docker network create database
   ```
3. **Lanzamiento:** Navegar a cualquier directorio de servicio y ejecutar `docker compose up -d`.

### Hoja de Ruta

- [ ] **Gestión de Medios:** Despliegue de **Kavita** o **Komga** para hosting de biblioteca personal.
- [ ] **Monitoreo:** Integración de **Prometheus y Grafana** para métricas de salud del sistema.
- [ ] **Disponibilidad:** **Uptime Kuma** para notificaciones de estado y monitoreo de latidos (heartbeats).
