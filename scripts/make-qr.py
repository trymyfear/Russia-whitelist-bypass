#!/usr/bin/env python3
import argparse
from pathlib import Path

try:
    import qrcode
except ImportError as exc:
    raise SystemExit("Install QR support with: py -m pip install qrcode[pil]") from exc

parser = argparse.ArgumentParser()
parser.add_argument("text")
parser.add_argument("output", type=Path)
args = parser.parse_args()

args.output.parent.mkdir(parents=True, exist_ok=True)
image = qrcode.make(args.text)
image.save(args.output)
print(args.output.resolve())

