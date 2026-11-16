"""Contact sheets of golden PNGs for the min-size audit (docs/design/m11/min-sizes.md), rendered by headless Chrome.

    python docs/design/m11/min-sizes/make_sheets.py OUT_DIR SHEET_NAME SCALE COLS glob [glob ...]

Each golden is drawn at SCALE (1 = one golden pixel per sheet pixel, which is one point) with its file name under it.
"""
import glob
import os
import pathlib
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
GOLD = os.environ.get('GOLD') or os.path.join(ROOT, 'app', 'test', 'goldens')  # GOLD=dir sheets a snapshot (git archive)
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'


def size_of(path):
    with open(path, 'rb') as f:
        head = f.read(24)
    return int.from_bytes(head[16:20], 'big'), int.from_bytes(head[20:24], 'big')


def sheet(out, files, scale, cols):
    cells, rows, row, rw, rh, total_h, width = [], [], [], 0, 0, 0, 0
    sizes = [size_of(f) for f in files]
    cw = max(w for w, _ in sizes) * scale + 12
    for f, (w, h) in zip(files, sizes):
        cells.append('<div style="display:inline-block;vertical-align:top;margin:4px;width:%dpx">'
                     '<img src="%s" style="width:%dpx;height:%dpx;outline:1px solid #999">'
                     '<div style="font:600 13px/1.3 sans-serif;color:#B23A3A">%s (%dx%d)</div></div>' % (
                         cw - 8, pathlib.Path(f).as_uri(), w * scale, h * scale, os.path.basename(f)[:-4], w, h))
    width = int(cw * cols + 8)
    n_rows = (len(files) + cols - 1) // cols
    row_h = [max(sizes[i][1] for i in range(r * cols, min(len(files), (r + 1) * cols))) * scale + 30 for r in range(n_rows)]
    height = int(sum(row_h) + 16)
    doc = '<html><head><meta charset="utf-8"><style>body{margin:4px;background:#fff;width:%dpx}</style></head><body>%s</body></html>' % (
        width, ''.join(cells))
    tmp = tempfile.mkdtemp(prefix='sheet_')
    p = os.path.join(tmp, 'p.html')
    open(p, 'w', encoding='utf-8').write(doc)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=4000', '--screenshot=' + out,
                    '--window-size=%d,%d' % (width, height), pathlib.Path(p).as_uri()], check=True, capture_output=True)


if __name__ == '__main__':
    out_dir, name, scale, cols = os.path.abspath(sys.argv[1]), sys.argv[2], float(sys.argv[3]), int(sys.argv[4])
    os.makedirs(out_dir, exist_ok=True)
    files = []
    for g in sys.argv[5:]:
        files += sorted(glob.glob(os.path.join(GOLD, g)))
    per = int(os.environ.get('PER', '12'))
    for k in range(0, len(files), per):
        part = files[k:k + per]
        out = os.path.join(out_dir, '%s_%02d.png' % (name, k // per))
        sheet(out, part, scale, cols)
        print(out, len(part))
