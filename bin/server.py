#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess

class TestHandler(BaseHTTPRequestHandler):
    def _set_response(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write("TSA Test Server\n".encode('utf-8'))

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        with open("jreq.tsq", mode="wb") as file:
            file.write(post_data)
        subprocess.run([
            "/usr/bin/openssl",
            "ts",
            "-reply",
            "-config", 
            "../conf/openssl-ts.conf", 
            "-passin",
            "pass:1234",
            "-queryfile",
            "jreq.tsq",
            "-out", 
            "jresp.tsr"
        ]);
        self.send_response(200)
        self.send_header("Content-type", "application/timestamp-reply")
        self.end_headers()
        resp_data = None
        with open("jresp.tsr", mode="rb") as file:
            resp_data = file.read()
        self.wfile.write(resp_data)

if __name__ == '__main__':
    server_address = ('', 8080)
    httpd = HTTPServer(server_address, TestHandler)
    print("Timestamp server started, use Ctrl+C to stop, URL: http://127.0.0.1:8080/");
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()

