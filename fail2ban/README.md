# Fail2ban Configuration

Fail2ban protege la infraestructura bloqueando IPs después de múltiples intentos fallidos de autenticación.

## Instalación

```bash
# Instalar fail2ban
sudo apt update
sudo apt install fail2ban

# Crear symlink a la configuración
sudo ln -s /opt/infrastructure/fail2ban/jail.local /etc/fail2ban/jail.local

# Iniciar y habilitar fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Configuración actual

### Jails habilitados

| Jail | Puerto | Max Retry | Ban Time | Descripción |
|------|--------|-----------|----------|-------------|
| **sshd** | 22 | 3 | 1 hora | SSH del sistema |
| **forgejo-ssh** | 222 | 3 | 2 horas | SSH de Forgejo |
| **recidive** | - | 3 | 1 semana | Reincidentes (banned múltiples veces) |

### Jails deshabilitados (configurar según necesidad)

- **caddy-auth**: Requiere configurar logging en Caddy
- **forgejo-app**: Para login web de Forgejo (requiere parsing de logs)

## Comandos útiles

```bash
# Ver estado general
sudo fail2ban-client status

# Ver estado de un jail específico
sudo fail2ban-client status sshd
sudo fail2ban-client status forgejo-ssh

# Ver IPs baneadas actualmente
sudo fail2ban-client banned

# Desbanear una IP manualmente
sudo fail2ban-client set sshd unbanip 1.2.3.4

# Banear una IP manualmente
sudo fail2ban-client set sshd banip 1.2.3.4

# Ver logs de fail2ban
sudo tail -f /var/log/fail2ban.log

# Recargar configuración sin reiniciar
sudo fail2ban-client reload

# Reiniciar fail2ban
sudo systemctl restart fail2ban
```

## Testing

Después de configurar, puedes testear desde otra máquina:

```bash
# Intentar SSH con password incorrecto 3 veces
ssh usuario@77.42.24.90 -p 22

# Deberías ser baneado después del tercer intento
# Verificar en el servidor:
sudo fail2ban-client status sshd
```

## Monitoreo

```bash
# Ver actividad reciente
sudo tail -100 /var/log/fail2ban.log | grep "Ban"

# Ver todas las IPs baneadas en las últimas 24h
sudo grep "$(date +%Y-%m-%d)" /var/log/fail2ban.log | grep "Ban"

# Estadísticas por jail
sudo fail2ban-client status | grep "Jail list"
```

## Whitelist de IPs

Si tienes IPs de confianza que nunca deben ser baneadas, agrégalas a `ignoreip` en `jail.local`:

```ini
ignoreip = 127.0.0.1/8 ::1 tu.ip.fija.aqui
```

## Notificaciones por email (opcional)

Para recibir emails cuando se banea una IP:

1. Instalar sendmail o configurar SMTP
2. Editar `jail.local`:
   ```ini
   destemail = admin@luminessa.net
   sender = fail2ban@luminessa.net
   action = %(action_mwl)s
   ```

## Logs

Fail2ban logs van a:
- `/var/log/fail2ban.log` - Actividad de fail2ban
- `/var/log/auth.log` - Intentos de login SSH (leídos por fail2ban)

## Troubleshooting

### Fail2ban no inicia

```bash
# Verificar sintaxis de configuración
sudo fail2ban-client -t

# Ver errores en logs
sudo journalctl -u fail2ban -n 50
```

### Un jail no funciona

```bash
# Verificar que el logpath existe
ls -la /var/log/auth.log

# Testear el filtro manualmente
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```

### Demasiados falsos positivos

Aumenta `maxretry` o `findtime` en el jail específico.

## Seguridad adicional

Fail2ban es una capa de defensa, pero también deberías:
- Usar autenticación SSH por llave (deshabilitar passwords)
- Configurar firewall (ufw/iptables)
- Mantener el sistema actualizado
- Usar passwords fuertes en servicios web
