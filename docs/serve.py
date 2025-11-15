# serve.py
from http import server
import sys

class CORSRequestHandler(server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # These headers are required for Godot 4 Web functionality
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        # Allow custom JavaScript fetch to work securely
        self.send_header("Access-Control-Allow-Origin", "*")
        server.SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    port = 8000
    print(f"Serving on http://localhost:{port}")
    server.test(HandlerClass=CORSRequestHandler, port=port)