#!/usr/bin/env bash
# Exports the YOLOv9 ONNX model that the onnx detector needs and writes it into
# this directory.
#
# Frigate 0.18 dropped the amd64 TensorRT detector, so the container no longer
# builds a detection model from YOLO_MODELS at startup. The ONNX detector takes
# a model file, so the artifact lives in this repo and is mounted read-only at
# /models -- see docker-compose.yml. That keeps a fresh host reproducible from
# the repo alone instead of needing a one-off export by hand.
set -euo pipefail

MODEL_SIZE="${MODEL_SIZE:-t}"
IMG_SIZE="${IMG_SIZE:-320}"

cd "$(dirname "$0")"

OUT="yolov9-${MODEL_SIZE}-${IMG_SIZE}.onnx"

if [[ -f "$OUT" ]]; then
    echo "$OUT already exists; delete it to re-export." >&2
    exit 0
fi

docker build . \
    --build-arg MODEL_SIZE="$MODEL_SIZE" \
    --build-arg IMG_SIZE="$IMG_SIZE" \
    --output . \
    -f- <<'EOF'
FROM python:3.11 AS build
RUN apt-get update && apt-get install --no-install-recommends -y cmake libgl1 && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.10.4 /uv /bin/
WORKDIR /yolov9
ADD https://github.com/WongKinYiu/yolov9.git .
RUN uv pip install --system -r requirements.txt
RUN uv pip install --system onnx==1.18.0 onnxruntime onnx-simplifier==0.4.* onnxscript
ARG MODEL_SIZE
ARG IMG_SIZE
ADD https://github.com/WongKinYiu/yolov9/releases/download/v0.1/yolov9-${MODEL_SIZE}-converted.pt yolov9-${MODEL_SIZE}.pt
RUN sed -i "s/ckpt = torch.load(attempt_download(w), map_location='cpu')/ckpt = torch.load(attempt_download(w), map_location='cpu', weights_only=False)/g" models/experimental.py
RUN python3 export.py --weights ./yolov9-${MODEL_SIZE}.pt --imgsz ${IMG_SIZE} --simplify --include onnx
FROM scratch
ARG MODEL_SIZE
ARG IMG_SIZE
COPY --from=build /yolov9/yolov9-${MODEL_SIZE}.onnx /yolov9-${MODEL_SIZE}-${IMG_SIZE}.onnx
EOF

echo "wrote $(pwd)/$OUT"
