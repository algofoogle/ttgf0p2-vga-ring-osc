#!/usr/bin/env python3
"""
Convert black pixels in a PNG to an array of rectangles (LL + UR corners).

Coordinate system:
  - Image pixels: origin at top-left (standard for images)
  - Output coords: origin at bottom-left, with y increasing upwards
  - Each pixel becomes a unit square:
        (x,   y)   -> lower-left corner
        (x+1, y+1) -> upper-right corner
    after flipping vertically and applying scale/offset.

Example:
  python png_to_rects.py ring.png --scale 1.0 --offset-x 0 --offset-y 0 > rects.json
"""

import argparse
import json
from typing import List, Tuple

from PIL import Image


def is_black(pixel, threshold: int) -> bool:
    """
    Return True if the pixel should be treated as 'black'.

    threshold: 0-255. Pixel is considered black if all RGB channels <= threshold.
    Alpha is ignored except that fully transparent pixels are treated as non-black.
    """
    # Ensure we have RGBA or RGB
    if len(pixel) == 4:
        r, g, b, a = pixel
        if a == 0:
            return False  # fully transparent
    else:
        r, g, b = pixel[:3]

    return r <= threshold and g <= threshold and b <= threshold


def png_to_rectangles(
    path: str,
    scale_x: float = 1.0,
    scale_y: float = 1.0,
    offset_x: float = 0.0,
    offset_y: float = 0.0,
    threshold: int = 0,
) -> List[Tuple[Tuple[float, float], Tuple[float, float]]]:
    """
    Convert black pixels in a PNG to a list of rectangles.

    Each rectangle is ((x_min, y_min), (x_max, y_max)) in the transformed
    coordinate system.
    """
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    pixels = img.load()

    rects = []

    for y in range(height):
        for x in range(width):
            if not is_black(pixels[x, y], threshold):
                continue

            # Pixel coordinates in image space (top-left origin):
            # pixel occupies [x, x+1] in X and [y, y+1] in Y

            # Convert to bottom-left origin:
            # y_top = 0 at top; want y_bottom = 0 at bottom.
            # Bottom-left y of pixel:
            y_bl = height - (y + 1)
            # Top-right y of pixel:
            y_tr = height - y

            # Apply scaling and offset
            llx = x * scale_x + offset_x
            lly = y_bl * scale_y + offset_y
            urx = (x + 1) * scale_x + offset_x
            ury = y_tr * scale_y + offset_y

            rects.append(((llx, lly), (urx, ury)))

    return rects


def main():
    parser = argparse.ArgumentParser(
        description="Convert black pixels in a PNG into an array of rectangle coordinates."
    )
    parser.add_argument("input", help="Input PNG file (e.g. /mnt/data/ring.png)")
    parser.add_argument(
        "--scale",
        type=float,
        default=None,
        help="Uniform scale factor for both X and Y (default 1.0).",
    )
    parser.add_argument(
        "--scale-x",
        type=float,
        default=None,
        help="Scale factor in X (overrides --scale if given).",
    )
    parser.add_argument(
        "--scale-y",
        type=float,
        default=None,
        help="Scale factor in Y (overrides --scale if given).",
    )
    parser.add_argument(
        "--offset-x",
        type=float,
        default=0.0,
        help="Offset added to all X coordinates (default 0).",
    )
    parser.add_argument(
        "--offset-y",
        type=float,
        default=0.0,
        help="Offset added to all Y coordinates (default 0).",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=0,
        help=(
            "Black threshold (0-255). A pixel is black if all RGB channels "
            "<= threshold. Default is 0 (pure black only)."
        ),
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default=None,
        help="Optional output file (JSON). If omitted, prints to stdout.",
    )

    args = parser.parse_args()

    # Resolve scale factors
    scale_x = args.scale_x if args.scale_x is not None else (args.scale if args.scale is not None else 1.0)
    scale_y = args.scale_y if args.scale_y is not None else (args.scale if args.scale is not None else 1.0)

    rects = png_to_rectangles(
        args.input,
        scale_x=scale_x,
        scale_y=scale_y,
        offset_x=args.offset_x,
        offset_y=args.offset_y,
        threshold=args.threshold,
    )

    # Convert to a JSON-serialisable structure:
    # [ [ [llx, lly], [urx, ury] ], ... ]
    json_rects = [[ll[0], ll[1], ur[0], ur[1]] for (ll, ur) in rects]
    out_str = f"[{',\n'.join(str(x) for x in json_rects)}]\n"
    # out_str = json.dumps(json_rects, indent=2)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(out_str + "\n")
    else:
        print(out_str)


if __name__ == "__main__":
    main()
