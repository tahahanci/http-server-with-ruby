# Ruby HTTP Server

A simple multithreaded HTTP server written in Ruby. This server supports various HTTP methods and features, including file serving, echo responses, user-agent display, and gzip compression.

## Features

- **GET Requests**:
    - `/`: Returns a simple 200 OK response.
    - `/user-agent`: Returns the User-Agent header sent by the client.
    - `/echo/{str}`: Returns the `{str}` parameter as a plain text response.
    - `/files/{filename}`: Serves files from the specified directory.

- **POST Requests**:
    - `/files/{filename}`: Creates a new file with the provided content in the specified directory.

- **HTTP Compression**:
    - Supports gzip compression if the client requests it via the `Accept-Encoding: gzip` header.

## Requirements

- Ruby 2.5 or later.

## Setup and Usage

### 1. Clone the Repository

```bash
git clone https://github.com/tahahanci/ruby-http-server.git
```

### 2. Run the server
    
```bash
ruby http_server.rb --directory /path/to/serve/files/
```

### 3. Test the server

```bash
curl -v http://localhost:4221/
```

- Echo Path (/echo/{str})

```bash
curl -v http://localhost:4221/echo/hello
```

- User-Agent Path (/user-agent)

```bash
curl -v -H "User-Agent: CustomUserAgent" http://localhost:4221/user-agent
```

- Files path (/files/{filename})

```bash
curl -v http://localhost:4221/files/yourfile.txt
curl -v --data "Hello, World!" -X POST http://localhost:4221/files/newfile.txt
```

- Gzip Compression

```bash
curl -v -H "Accept-Encoding: gzip" http://localhost:4221/echo/abc | hexdump -C
```
