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

Flash it once with `universal-silabs-flasher`; it drives RTS/DTR into the Gecko
bootloader itself, so no button has to be held:

```bash
curl -LO https://dongle.sonoff.tech/dongle-flasher/dongle-hardware/donglelmg21_mg21_openthread_stable_2.4.4_115200.gbl
sudo env PATH="$PATH" nix shell nixpkgs#python3Packages.universal-silabs-flasher \
  -c universal-silabs-flasher \
  --device /dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Lite_MG21_3a3c0b13b9a2ef11b419966661ce3355-if00-port0 \
  flash --firmware donglelmg21_mg21_openthread_stable_2.4.4_115200.gbl
```

Expect `Detected bootloader version '2.4.2'` and then a ~20 s progress bar. The
`Failed to read firmware metadata: KeyError('No tag with id ...')` line is
harmless: vendor images do not carry that optional GBL tag.

The stick keeps the same USB-UART, so `/dev/ttyUSB0` does not change.

**The baud rate is part of the image**, so `OT_RCP_DEVICE` must match what was
flashed. SONOFF publishes no 460800 ot-rcp build for `dongle-lmg21` (only
[Nerivec/silabs-firmware-builder](https://github.com/Nerivec/silabs-firmware-builder)
ones), hence 115200 here.

### Why not the web flasher

<https://dongle.sonoff.tech/sonoff-dongle-flasher/> looks easier but wedges: it
leaves the port locked inside Chrome (`Failed to execute 'close' on 'SerialPort':
Cannot cancel a locked stream`) and then retries `close()` forever while the UI
shows a fake "estimated remaining time", nothing having been written to flash.
Its debug log is AES-encrypted; to read one:

```bash
base64 -d <logfile> | openssl enc -d -aes-256-ecb -md md5 \
  -pass pass:c3d08a9d-c673-4950-85e0-c29277e74bb9
```

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
