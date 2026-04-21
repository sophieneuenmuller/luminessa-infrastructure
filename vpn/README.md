# Wireguard Easy (VPN)

This service provides a simple web interface for managing Wireguard clients and configurations.

## Features
- User-friendly web UI for client management.
- Experimental AmneziaWG support (`EXPERIMENTAL_AWG=true`).
- Proxied administrative interface via `vpn.luminessa.net`.

## Requirements
- **Kernel Support**: The host must support Wireguard.
- **Firewall**: Port `51820/udp` MUST be open on the host to allow VPN tunnel connections.

## Configuration
1. Create a symlink for the `.env` file (see root README).
2. Ensure the `proxy` network exists: `docker network create proxy`.
3. Start the service: `docker compose up -d`.

## Persistence
All configuration and client data is stored in the `./data/` directory.
