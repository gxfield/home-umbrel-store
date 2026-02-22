# Transmission OpenVPN for Umbrel

Transmission BitTorrent client routed through an OpenVPN tunnel, pre-configured for Radarr/Sonarr integration.

## Setup

All configuration is done over SSH. The app ships with empty VPN credentials — you must set them before the container will connect.

### Using a Custom .ovpn File (Recommended)

1. SSH into your Umbrel:
   ```bash
   ssh umbrel@umbrel.local
   ```

2. Create the OpenVPN config directory:
   ```bash
   mkdir -p ~/umbrel/app-data/home-transmission-openvpn/data/openvpn
   ```

3. Copy your `.ovpn` file to that directory:
   ```bash
   cp your-vpn.ovpn ~/umbrel/app-data/home-transmission-openvpn/data/openvpn/
   ```

4. Open the docker-compose.yml for editing:
   ```bash
   nano ~/umbrel/app-data/home-transmission-openvpn/docker-compose.yml
   ```

5. Set `OPENVPN_CONFIG` to the filename without the `.ovpn` extension. For example, if your file is `my-server.ovpn`, set:
   ```yaml
   OPENVPN_CONFIG: "my-server"
   ```

6. Set your VPN credentials:
   ```yaml
   OPENVPN_USERNAME: "your-vpn-username"
   OPENVPN_PASSWORD: "your-vpn-password"
   ```

7. Confirm `OPENVPN_PROVIDER` is set to `"CUSTOM"` (the default).

8. Restart the app from the Umbrel dashboard: Settings > Restart.

> **Note:** If your `.ovpn` file contains a `block-outside-dns` line, remove it. That directive is Windows-only and will cause the container to fail on Linux.

---

### Using a Named Provider (PIA, NordVPN, Mullvad, etc.)

1. SSH into your Umbrel and open docker-compose.yml:
   ```bash
   nano ~/umbrel/app-data/home-transmission-openvpn/docker-compose.yml
   ```

2. Change `OPENVPN_PROVIDER` from `"CUSTOM"` to your provider name:
   ```yaml
   OPENVPN_PROVIDER: "PIA"
   ```
   Common values: `PIA`, `NORDVPN`, `MULLVAD`, `SURFSHARK`, `PROTONVPN`, `EXPRESSVPN`, `IPVANISH`, `WINDSCRIBE`

3. Set the server or region. Some providers use their own env vars instead of `OPENVPN_CONFIG`:

   **NordVPN** — uses `NORDVPN_COUNTRY` (country code or full name) and requires UDP:
   ```yaml
   NORDVPN_COUNTRY: "CA"
   NORDVPN_PROTOCOL: "udp"
   ```

   > **Important:** NordVPN defaults to TCP, which causes connection timeouts on Umbrel's Docker network. Always set `NORDVPN_PROTOCOL: "udp"` when using NordVPN as a named provider.

   **Other providers** — use `OPENVPN_CONFIG`:
   ```yaml
   OPENVPN_CONFIG: "france"
   ```

   See the [full provider list and config options](https://haugene.github.io/docker-transmission-openvpn/supported-providers/) for valid values.

4. Set your VPN credentials:
   ```yaml
   OPENVPN_USERNAME: "your-vpn-username"
   OPENVPN_PASSWORD: "your-vpn-password"
   ```

5. Restart the app from the Umbrel dashboard: Settings > Restart.

---

## Verify It Works

After restarting, run these commands to confirm the VPN is connected:

```bash
# Check container logs for VPN connection status
docker logs home-transmission-openvpn_transmission-openvpn_1 2>&1 | grep -E "(Initialization Sequence Completed|AUTH_FAILED)"

# Verify the VPN IP (should NOT be your home IP)
docker exec home-transmission-openvpn_transmission-openvpn_1 wget -qO- https://api.ipify.org

# Check the container is running and not restarting
docker ps | grep transmission-openvpn
```

A successful connection shows `Initialization Sequence Completed` in the logs and an IP address different from your home IP.

---

## Radarr and Sonarr Integration

In Radarr or Sonarr: **Settings > Download Clients > Add > Transmission**

| Field | Value |
|---|---|
| **Name** | Transmission VPN |
| **Host** | `transmission-openvpn` |
| **Port** | `9091` |
| **URL Base** | `/transmission/` |
| **Username** | *(leave empty)* |
| **Password** | *(leave empty)* |

Click **Test** then **Save**.

### Why It Works

The key to Radarr/Sonarr integration is a shared download path:

```
Umbrel host path:         ${UMBREL_ROOT}/data/storage/downloads/
Transmission sees it as:  /downloads/
Radarr/Sonarr sees it as: /downloads/
```

Both apps mount the same host directory at `/downloads`, so Radarr and Sonarr can directly access completed downloads without any remote path mapping. Transmission saves to `/downloads/complete/` and Radarr/Sonarr read from the same location.

---

## Troubleshooting

**Container keeps restarting (crash loop)**
- Check logs for `AUTH_FAILED`: your VPN credentials are wrong or still empty
- Check logs for `No OpenVPN config found`: `OPENVPN_CONFIG` doesn't match any `.ovpn` filename in the openvpn directory, or no `.ovpn` file is present
- Verify `/dev/net/tun` exists on the host: `ls /dev/net/tun`

**App shows in Umbrel but web UI won't load**
- There may be a port mismatch in configuration — both `umbrel-app.yml` and `docker-compose.yml` should use port `9091`
- The container may not be running yet — check `docker ps` and look at logs

**AUTH_FAILED in logs**
- Your VPN credentials are incorrect
- Some providers require API credentials, not your account login — check your provider's documentation

**NordVPN disconnects every 3 minutes**
- The NordVPN provider defaults to TCP, which has a routing conflict on Umbrel's Docker network
- Add `NORDVPN_PROTOCOL: "udp"` to your docker-compose.yml environment variables
- Restart the app after making the change

**OpenVPN config parse error**
- Remove `block-outside-dns` from your `.ovpn` file (Windows-only directive that fails on Linux)
- Check for Windows line endings: `dos2unix your-vpn.ovpn`

**Radarr/Sonarr can't connect to download client**
- Verify the container is running and healthy: `docker ps` should show `(healthy)`
- Verify `LOCAL_NETWORK` in docker-compose.yml includes `10.21.0.0/16`
- Test RPC from another container:
  ```bash
  docker exec <radarr-container> curl -s http://home-transmission-openvpn_transmission-openvpn_1:9091/transmission/rpc
  ```

---

## Documentation

Full haugene/transmission-openvpn documentation: https://haugene.github.io/docker-transmission-openvpn/
