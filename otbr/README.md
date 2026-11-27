# OpenThread Border Router

Thread radio for Matter-over-Thread devices, using the SONOFF Dongle Lite MG21
(EFR32MG21). Home Assistant is a plain container on NEMESIS, so there is no
supervisor to install the OTBR add-on; this is the standalone equivalent.

## Start

```bash
make up SERVICE=otbr
docker logs -f otbr
```

A healthy start logs `Starting otbr-agent...`, `Radio URL:
spinel+hdlc+uart:///dev/ttyUSB0...`, then the mesh details (BR ULA, OMR prefix)
and `Thread Border Agent` registration.

### `Init() at spinel_driver.cpp:87: Failure`

The Dongle Lite MG21 ships with Zigbee (EmberZNet/EZSP) firmware — it is sold as
"Zigbee/Thread", one or the other. `spinel_driver` init failing means it is
still speaking EZSP, so otbr-agent has nothing to talk to.

Flash the OpenThread firmware once with SONOFF's own tool: unplug the stick from
NEMESIS, plug it into a laptop, open <https://dongle.sonoff.tech/sonoff-dongle-flasher/>
in Chrome/Chromium (it uses WebSerial), pick **OpenThread**, flash. Then plug it
back in and restart this container. The stick keeps the same USB-UART, so
`/dev/ttyUSB0` does not change.

If the handshake still fails after flashing, try `uart-baudrate=115200` before
assuming anything else.

## Host prerequisites

- `net.ipv6.conf.all.forwarding = 1` — OTBR forwards between `wpan0` and the
  LAN, so this is set in `nixos/hosts/NEMESIS/configuration.nix`.
- UDP 5353 open — mDNS is how the Matter server, Home Assistant and the mesh
  find each other.
- The LAN's IPv6 ULA (`fdad:2cc4:4627::/64`) is advertised by MIRAGE, so Thread
  devices get on-link IPv6 without an ISP prefix.

## Joining a Thread network

The border router creates the network on first start:

```bash
docker exec -it otbr ot-ctl dataset active -x     # dataset to paste into the Matter server
docker exec -it otbr ot-ctl state                  # leader
docker exec -it otbr ot-ctl child table
```

Paste the dataset into the Matter server (dashboard → Thread credentials) before
commissioning the first device. Home Assistant's *Thread* integration is only
needed if you want it to push credentials to phones; the Matter server is the
only consumer here.

## Notes

- No Bluetooth is involved after pairing; Thread devices reach the Matter server
  over IPv6 through this container.
- The Zigbee stick (ITEAD Plus V2, `/dev/ttyACM0`) is unrelated and stays with
  ZHA.
