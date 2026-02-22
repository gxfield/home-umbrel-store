# Transmission OpenVPN for Umbrel

Transmission BitTorrent client with all traffic routed through an OpenVPN tunnel. Pre-configured for seamless integration with Radarr and Sonarr on your Umbrel.

## Setup

### 1. Configure Your VPN Provider

After installing, SSH into your Umbrel and edit the docker-compose.yml:

```bash
# On umbrelOS:
nano ~/umbrel/app-data/home-transmission-openvpn/docker-compose.yml
```

Change these environment variables:

```yaml
OPENVPN_PROVIDER: "PIA"              # Your VPN provider
OPENVPN_CONFIG: "france"             # Server/region
OPENVPN_USERNAME: "your_username"    # VPN username
OPENVPN_PASSWORD: "your_password"    # VPN password
```

Then restart the app from the Umbrel UI.

### 2. Using a Custom .ovpn File

If your provider isn't supported or you prefer a custom config:

1. Place your `.ovpn` file in the app's data directory:
   ```bash
   cp your-vpn.ovpn ~/umbrel/app-data/home-transmission-openvpn/data/openvpn/
   ```

2. Uncomment the custom OpenVPN volume mount in `docker-compose.yml`:
   ```yaml
   - ${APP_DATA_DIR}/data/openvpn:/etc/openvpn/custom
   ```

3. Set the provider to CUSTOM:
   ```yaml
   OPENVPN_PROVIDER: "CUSTOM"
   OPENVPN_CONFIG: "your-vpn"  # filename without .ovpn
   ```

## Connecting Radarr & Sonarr

### Automatic (if using Umbrel's built-in Radarr/Sonarr)

Umbrel's Radarr and Sonarr are pre-configured to look for `transmission_server_1` as the download client hostname. Since this app uses a different container name, you'll need to add it manually.

### Manual Setup

In **Radarr** (or Sonarr): Settings → Download Clients → Add → Transmission

| Field | Value |
|---|---|
| **Name** | Transmission VPN |
| **Host** | `home-transmission-openvpn_transmission_1` |
| **Port** | `9091` |
| **URL Base** | `/transmission/` |
| **Username** | *(leave empty)* |
| **Password** | *(leave empty)* |

Click **Test** then **Save**.

### Why It Works

The key to Radarr/Sonarr integration is **shared download paths**:

```
Umbrel host path:        ${UMBREL_ROOT}/data/storage/downloads/
Transmission sees it as: /downloads/
Radarr/Sonarr sees it as: /downloads/
```

Since both apps mount the same host directory at `/downloads`, Radarr and Sonarr can directly access completed downloads without any remote path mapping. Transmission saves completed files to `/downloads/complete/`, and Radarr/Sonarr can read them from the same location.

## Supported VPN Providers

See the full list at: https://haugene.github.io/docker-transmission-openvpn/supported-providers/

Common providers include: PIA, NordVPN, Mullvad, Surfshark, ProtonVPN, ExpressVPN, IPVanish, Windscribe, AirVPN, and many more. You can also use any provider with the CUSTOM option and your own .ovpn file.

## Troubleshooting

**App won't start / restarts constantly:**
- Check logs: `docker logs home-transmission-openvpn_transmission_1`
- Verify your VPN credentials are correct
- Make sure `/dev/net/tun` exists on your Umbrel device

**Radarr/Sonarr can't connect:**
- Verify the container is healthy: `docker ps` should show `(healthy)`
- Test RPC: `curl http://home-transmission-openvpn_transmission_1:9091/transmission/rpc`
- Check that `LOCAL_NETWORK` includes your Docker subnet

**Downloads not appearing in Radarr/Sonarr:**
- Confirm both apps mount the same storage path
- Check file permissions (PUID/PGID should be 1000)

## Documentation

Full documentation: https://haugene.github.io/docker-transmission-openvpn/
