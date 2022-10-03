import sys
import socketserver
from http.server import SimpleHTTPRequestHandler

class WasmHandler(SimpleHTTPRequestHandler):
  def end_headers(self):
    # Cross-Origin-Embedder-Policyヘッダの設定
    self.send_header('Cross-Origin-Embedder-Policy','require-corp')
    # Cross-Origin-Opener-Policyヘッダの設定
    self.send_header('Cross-Origin-Opener-Policy','same-origin')
    SimpleHTTPRequestHandler.end_headers(self)

# Pythonのバージョン3.7.5未満ではWebAssemblyのメディアタイプがサポートされていないため
# 該当するバージョンのPythonを使用している場合は、WebAssemblyのメディアタイプのサポートを追加
if sys.version_info < (3, 7, 5):
  WasmHandler.extensions_map['.wasm'] = 'application/wasm'

if __name__ == '__main__':
  PORT = 8080
  with socketserver.TCPServer(("", PORT), WasmHandler) as httpd:
    print("Listening on port {}. Press Ctrl+C to stop.".format(PORT))
    httpd.serve_forever()