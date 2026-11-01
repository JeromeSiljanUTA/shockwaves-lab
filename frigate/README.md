# Frigate

[NVR][frigate] for the IP camera. Records, detects objects, and integrates
with Home Assistant over MQTT.

Camera: `http://192.168.10.146:8080/stream` (MJPEG).

## Hardware

- **NVIDIA GPU** — shared with Jellyfin/Ollama via the
  nvidia-container-toolkit CDI device (`nvidia.com/gpu=all`). Used for the
  ONNX/TensorRT object detector and `preset-nvidia` ffmpeg decode. Image tag is
  `stable-tensorrt` (the only build with TensorRT support).
- **Intel iGPU** — not currently used. See "Intel QuickSync" below if you want
  to move decoding off the NVIDIA card.

## Config

- `docker-compose.yml` — the service. Image, GPU, ports, and volumes.
- `config.yml` — the Frigate config, bind-mounted read-only into the
  container. This is the file you edit.

Runtime state (`frigate.db`, `model_cache/`, recordings) lives under
`../../volumes/frigate/`, which is not tracked here.

## Access

- `http://frigate.nemesis.home.arpa` — authenticated UI (proxied by nginx to
  loopback `:8971`).
- Ports `5000` (internal API) and `8554` (RTSP restream) are bound to
  **loopback only**. `8555` (WebRTC) and `8971` are on the LAN.

## First-run checklist

1. Create the volume directories:

   ```bash
   sudo mkdir -p ../../volumes/frigate/config ../../volumes/frigate/storage
   ```

   The container runs as root by default, so no chown is needed, but if you
   later pin a `user:` make the dirs match that uid.

2. Start it:

   ```bash
   make up SERVICE=frigate
   ```

3. Watch the logs. On first start Frigate downloads the YOLO model into
   `volumes/frigate/config/model_cache/` — this needs internet access and can
   take a minute. Then confirm:
   - **Detector**: the log should mention TensorRT/ONNX, not the CPU detector.
   - **ffmpeg**: no "no hardware acceleration" warning, and `nvidia-smi` on
     NEMESIS should show `ffmpeg` processes.

4. Open `http://frigate.nemesis.home.arpa`, go to **Settings → Camera
   configuration**, and adjust detect resolution / zones / masks for your view.

## Follow-up: get a proper stream

The camera is MJPEG-only right now. That works but is CPU-expensive to decode
and **cannot use GPU (NVDEC) decode**, so `preset-nvidia` will not apply.
Most of these cameras also expose RTSP/H.264 on port 554 — probe the camera
(e.g. `ffprobe rtsp://192.168.10.146:554/...`, or check the vendor web UI) and,
once known, switch the `go2rtc.streams.camera` URL and the ffmpeg input to the
RTSP URL. Detection/recording quality and GPU load both improve significantly.

## Intel QuickSync (optional)

The Intel iGPU is currently not passed to the container and `/dev/dri` is not
enabled in the NEMESIS host config. To use it for decoding instead of the
NVIDIA card you would need to, on NEMESIS:

- ensure `hardware.graphics.enable = true` (already set) exposes the iGPU
  (`/dev/dri`), and
- add `- /dev/dri:/dev/dri` to the service's `devices:` and set
  `ffmpeg.hwaccel_args: preset-intel-qsv-h264` (or `preset-vaapi`) in
  `config.yml`.

Not enabled by default — the NVIDIA path is already set up for the other
services and one GPU for NVDEC + one for TensorRT can contend.

[frigate]: https://frigate.video/
