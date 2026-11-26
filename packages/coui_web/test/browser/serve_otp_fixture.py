#!/usr/bin/env python3
"""Serve a built docs fixture without its unrelated Flutter embed.

The embed installs a document-wide keyboard listener, even if its DOM node
is later removed. The actual Jaspr OTP scripts and other assets are unchanged.
"""

import argparse
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--directory', required=True, type=Path)
parser.add_argument('--port', type=int, default=19883)
args = parser.parse_args()
root = args.directory.resolve()


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *positional, **keyword):
        super().__init__(*positional, directory=str(root), **keyword)

    def do_GET(self):
        if self.path.split('?', 1)[0] == '/components/input-otp/':
            html = (root / 'components/input-otp/index.html').read_text()
            embed = '<script async src="/flutter_bootstrap.js"></script>'
            if html.count(embed) != 1:
                self.send_error(500, 'Expected exactly one Flutter bootstrap')
                return
            body = html.replace(embed, '').encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


HTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
