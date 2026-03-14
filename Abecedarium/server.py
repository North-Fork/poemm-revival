#!/usr/bin/env python3
"""
Abecedarium dev server.
Serves static files AND handles save/load for state files.

Endpoints:
  POST /save          body: JSON   → writes to ./state/{name}.json
  GET  /saves         → JSON list of saved file stems
  GET  /saves/{name}  → JSON content of ./state/{name}.json

Usage:
  python3 server.py [port]   (default port 8080)
"""

import functools, http.server, json, os, pathlib, sys, urllib.parse

SAVE_DIR  = pathlib.Path(__file__).parent / 'state'
SERVE_ROOT = pathlib.Path(__file__).parent.parent   # PoEMM/ — gives shared/ access
SAVE_DIR.mkdir(exist_ok=True)


class Handler(http.server.SimpleHTTPRequestHandler):

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_POST(self):
        if self.path == '/save':
            length = int(self.headers.get('Content-Length', 0))
            raw    = self.rfile.read(length)
            try:
                data = json.loads(raw)
                name = (data.get('name') or 'unnamed').strip()
                # Sanitise: keep alphanumeric, hyphen, underscore, space → hyphen
                safe = ''.join(c if c.isalnum() or c in '-_' else '-' for c in name).strip('-')
                if not safe:
                    safe = 'unnamed'
                out  = SAVE_DIR / f'{safe}.json'
                out.write_bytes(raw)
                self._json(200, {'ok': True, 'file': safe + '.json'})
            except Exception as e:
                self._json(400, {'ok': False, 'error': str(e)})
        elif self.path.startswith('/save-video'):
            qs   = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            name = (qs.get('name', ['unnamed'])[0]).strip()
            ext  = (qs.get('ext',  ['webm'])[0]).strip().lstrip('.')
            if ext not in ('mp4', 'webm'):
                ext = 'webm'
            safe = ''.join(c if c.isalnum() or c in '-_' else '-' for c in name).strip('-') or 'unnamed'
            length = int(self.headers.get('Content-Length', 0))
            raw    = self.rfile.read(length)
            out    = SAVE_DIR / f'{safe}.{ext}'
            out.write_bytes(raw)
            self._json(200, {'ok': True, 'file': f'{safe}.{ext}'})
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path == '/saves':
            files = sorted(f.stem for f in SAVE_DIR.glob('*.json'))
            self._json(200, files)
        elif self.path.startswith('/saves/'):
            stem = urllib.parse.unquote(self.path[7:]).replace('/', '_').replace('..', '')
            f    = SAVE_DIR / f'{stem}.json'
            if f.exists():
                body = f.read_bytes()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            else:
                self.send_response(404)
                self.end_headers()
        else:
            super().do_GET()

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        import sys
        print(fmt % args, flush=True, file=sys.stderr)


if __name__ == '__main__':
    port    = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    addr    = ('', port)
    handler = functools.partial(Handler, directory=str(SERVE_ROOT))
    httpd   = http.server.HTTPServer(addr, handler)
    print(f'Abecedarium server → http://macmighty.local:{port}/Abecedarium/')
    print(f'Serve root         → {SERVE_ROOT}')
    print(f'Saves directory    → {SAVE_DIR}')
    httpd.serve_forever()
