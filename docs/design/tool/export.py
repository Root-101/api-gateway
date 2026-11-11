"""Exports the console design and the brand images from the files of the Claude Design canvas.

    python docs/design/tool/export.py <folder>

<folder> holds the canvas files as the artifact serves them: `project/canvas.json` and
`project/*.dc.html`. It renders the artboards listed in SCREENS and BRAND with headless Chrome
(support.js stands in for the canvas runtime) and rewrites `docs/design/screens/`,
`docs/design/brand/images/` and `docs/design/api-gateway-console-design.pdf`. Needs Chrome and
ffmpeg.
"""
import json
import shutil
import subprocess
import sys
import tempfile
import threading
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

DESIGN = Path(__file__).resolve().parent.parent
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe' if sys.platform == 'win32' \
    else 'google-chrome'

# (section, file name, artboard, caption, props): the screens worth keeping, in reading order.
# props is the query that puts the artboard in another state (its props in the canvas)
SCREENS = [
    ('Access', 'splash', 'Splash', 'The console while it starts', ''),
    ('Access', 'login', 'Main', 'Log in', ''),
    ('Access', 'login-error', 'Main', 'Log in: wrong credentials', 'state=error'),
    ('Routes', 'routes', 'Routes', 'Routes', ''),
    ('Routes', 'routes-empty', 'Routes', 'Routes: none yet', 'state=empty'),
    ('Routes', 'route-create', 'RouteForm', 'Create a route', 'mode=create'),
    ('Routes', 'route-edit', 'RouteForm', 'Edit a route', 'mode=edit'),
    ('Routes', 'route-duplicate', 'RouteForm', 'Duplicate a route', 'mode=duplicate'),
    ('Routes', 'route-delete', 'Routes', 'Delete a route', 'state=delete'),
    ('Routes', 'routes-restore', 'RoutesRestore', 'Restore routes from a backup', ''),
    ('Routes', 'routes-restore-confirm', 'Routes', 'Restore routes: confirm the replacement',
     'state=restore-confirm'),
    ('HTTP logs', 'logs', 'Logs', 'HTTP logs', ''),
    ('HTTP logs', 'logs-filter', 'LogsFilter', 'HTTP logs: filters', ''),
    ('HTTP logs', 'log-details', 'LogDetails', 'HTTP logs: details of a request', ''),
    ('HTTP logs', 'logs-empty', 'Logs', 'HTTP logs: no results', 'state=empty'),
    ('States', 'loading', 'Routes', 'A screen while it loads: a skeleton of itself', 'state=loading'),
    ('States', 'offline', 'Routes', 'The gateway can\'t be reached', 'state=offline'),
    ('States', 'session-expired', 'Routes', 'Session expired: log in again', 'state=session'),
    ('States', 'not-found', 'NotFound', 'A URL that doesn\'t exist', ''),
    ('Navigation', 'rail-expanded', 'Routes', 'Navigation rail, expanded', 'menu=true'),
]

# (file name, artboard, props): the brand images, at their size on the canvas
BRAND = [
    ('identity.png', 'Identity-Final', ''),
    ('app-icon-dark.png', 'AppIcon', 'variant=dark'),
    ('app-icon-lilac.png', 'AppIcon', 'variant=lilac'),
    ('app-icon-light.png', 'AppIcon', 'variant=light'),
]


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def shot(port: int, board: str, props: str, w: int, h: int, out: Path, spare: int = 0) -> None:
    raw = out.with_suffix('.raw.png')
    # Headless Chrome takes ~96 px of the window height: render taller and crop. The background
    # stays transparent where the artboard has none (the rounded corners of the app icon)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--default-background-color=00000000',
                    # Chrome has a minimum window width, and a fixed-width artboard loses the
                    # scrollbar's width: those render wider (spare), then cropped
                    '--force-device-scale-factor=1', f'--window-size={max(w + spare, 800)},{h + 96}',
                    '--virtual-time-budget=8000', f'--screenshot={raw}',
                    f'http://127.0.0.1:{port}/{board}.dc.html?{props}'],
                   check=True, capture_output=True)
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(raw),
                    '-vf', f'crop={w}:{h}:0:0', str(out)], check=True)
    raw.unlink()
    print(out.relative_to(DESIGN))


def fresh(folder: Path) -> Path:
    # Emptied rather than deleted: on Windows a folder open elsewhere can't be removed
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob('*.png'):
        old.unlink()
    return folder


def main(source: Path) -> None:
    canvas = json.loads((source / 'project/canvas.json').read_text(encoding='utf-8'))
    work = Path(tempfile.mkdtemp(prefix='api-gateway-design-'))
    for f in (source / 'project').glob('*.dc.html'):
        shutil.copy(f, work)
    shutil.copy(Path(__file__).parent / 'support.js', work)

    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=work))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    port = server.server_address[1]

    screens = fresh(DESIGN / 'screens')
    pages = []
    for i, (section, name, board, caption, props) in enumerate(SCREENS, 1):
        frame = canvas['boards'][f'{board}.dc.html']
        out = screens / f'{i:02d}-{name}.png'
        shot(port, board, props, frame['w'], frame['h'], out)
        pages.append(f'<div class="p"><div><div class="s">{section}</div><h1>{caption}</h1></div>'
                     f'<img src="{out.as_uri()}"></div>')

    images = fresh(DESIGN / 'brand/images')
    for name, board, props in BRAND:
        frame = canvas['boards'][f'{board}.dc.html']
        shot(port, board, props, frame['w'], frame['h'], images / name, spare=40)

    html = work / 'print.html'
    html.write_text(PRINT.replace('<!--pages-->', '\n'.join(pages)), encoding='utf-8')
    pdf = DESIGN / 'api-gateway-console-design.pdf'
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--no-pdf-header-footer',
                    '--virtual-time-budget=8000', f'--print-to-pdf={pdf}', html.as_uri()],
                   check=True, capture_output=True)
    server.shutdown()
    shutil.rmtree(work)
    print(pdf.name)


PRINT = """<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;700&family=DM+Mono:wght@500&display=swap">
<style>
@page{size:1600px 900px;margin:0}
body{margin:0;background:#0d0c12;color:#fff;font-family:"DM Sans",system-ui,sans-serif}
.p{width:1600px;height:900px;box-sizing:border-box;padding:36px 32px;page-break-after:always;
   display:flex;flex-direction:column;gap:18px}
.p img{width:1536px;border:1px solid #2c2939;border-radius:8px}
.s{color:#9d8fd0;font-size:16px;letter-spacing:1px;text-transform:uppercase}
h1{margin:0;font-size:28px}
.cover{justify-content:center;align-items:center;text-align:center}
.cover h1{font-family:"DM Mono",monospace;font-weight:500;font-size:72px;letter-spacing:-2px}
.cover h1 span{color:#d0bcff}
</style></head><body>
<div class="p cover"><h1><span>api</span>-gateway</h1>
<p style="font-size:24px;color:#8f8e9b">Console design · 6.0.0</p></div>
<!--pages-->
</body></html>"""

if __name__ == '__main__':
    main(Path(sys.argv[1]))
