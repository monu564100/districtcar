"""
District Car Admin Web — Local Development & Production Preview Server
Runs on Python 3 http.server with correct MIME types and automatic port selection.
"""

import http.server
import socketserver
import os
import sys
import webbrowser

DEFAULT_PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Enable CORS and caching headers for dev preview
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

def run_server(port=DEFAULT_PORT):
    current_port = port
    max_tries = 10
    
    for attempt in range(max_tries):
        try:
            with socketserver.TCPServer(("", current_port), Handler) as httpd:
                print("=" * 60)
                print("  [*] DISTRICT CAR ADMIN WEB PORTAL")
                print("=" * 60)
                print(f"  Hosting Directory : {DIRECTORY}")
                print(f"  Local URL         : http://localhost:{current_port}/")
                print(f"  Network URL       : http://127.0.0.1:{current_port}/")
                print("=" * 60)
                print("  Press CTRL+C to stop the server.")
                print("=" * 60)

                # Attempt to open browser if not in headless mode
                try:
                    if "--no-browser" not in sys.argv:
                        webbrowser.open(f"http://localhost:{current_port}/")
                except Exception:
                    pass

                httpd.serve_forever()
                return
        except OSError as e:
            if getattr(e, 'errno', None) == 10048 or "Address already in use" in str(e):
                print(f"  [Notice] Port {current_port} is busy, trying port {current_port + 1}...")
                current_port += 1
            else:
                raise e

if __name__ == '__main__':
    run_server()
