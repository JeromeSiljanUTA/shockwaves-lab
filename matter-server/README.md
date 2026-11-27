# Matter Server

Matter controller used by Home Assistant's [Matter integration][matter].

Home Assistant runs as a plain container on NEMESIS (no HA OS supervisor), so
the Matter server has to run as its own container. The integration connects to
it over a WebSocket at `ws://localhost:5580/ws`.

## Start

Create the data directory first, owned by uid 1000 (the container's
unprivileged user, which is `jerome` on NEMESIS):

```bash
sudo mkdir -p ../../volumes/matter-server/data
sudo chown -R 1000:1000 ../../volumes/matter-server/data
make up SERVICE=matter-server
```

## Home Assistant setup

1. Settings → Devices & services → Add integration → **Matter**.
2. When asked how to run it, **uncheck** the box to install the official
   Matter Server app/add-on (there is no supervisor here), then **Submit**.
3. Enter the server URL: `ws://localhost:5580/ws`.
4. Commission devices from the **Home Assistant Companion app** on your phone
   (Settings → Companion app → Matter). Commissioning uses the phone's
   Bluetooth; Wi-Fi devices then join your 2.4 GHz network, Thread devices
   need a Thread border router.

## Requirements already handled

- The LAN has a stable ULA (`fdad:2cc4:4627:0::/64`) advertised by the MIRAGE
  router, so Matter has local IPv6 without needing an ISP prefix.
- Both Home Assistant and this container use host networking.

## Notes

- The dashboard is bound to loopback via `LISTEN_ADDRESS=127.0.0.1`. Remove
  that line to reach it from another machine.
- For battery/Thread devices, a stateful firewall can expire UDP conntrack
  entries between reports. The "sleepy end device" fix is to raise
  `net.netfilter.nf_conntrack_udp_timeout_stream` to `3600` on the host
  (NEMESIS), and to allow inbound UDP 5353 (mDNS) through the NixOS firewall.
- `python-matter-server` is end-of-life; `matterjs-server` is the current,
  API-compatible replacement.

[matter]: https://www.home-assistant.io/integrations/matter/
