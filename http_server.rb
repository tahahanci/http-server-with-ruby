require 'socket'
require 'zlib'
require 'stringio'

server = TCPServer.new('localhost', 4221)

loop do
  Thread.start(server.accept) do |client_socket|
    begin
      # Read the request line
      method, path, http_version = client_socket.readline.split

      if path == '/'
        # Respond with 200 OK for the root path
        client_socket.send "HTTP/1.1 200 OK\r\n\r\n", 0

      elsif path == '/user-agent'
        # Read headers
        headers = {}
        while (line = client_socket.readline.chomp) != ''
          key, value = line.split(': ', 2)
          headers[key] = value
        end

        user_agent = headers['User-Agent']

        # Respond with the User-Agent header value
        client_socket.send "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{user_agent.length}\r\n\r\n#{user_agent}", 0

      elsif path.start_with?('/echo/')
        # Handle /echo/{content} path
        content = path.split('/echo/').last

        # Read headers to check for Accept-Encoding
        headers = {}
        while (line = client_socket.readline.chomp) != ''
          key, value = line.split(': ', 2)
          headers[key] = value
        end

        accept_encoding = headers['Accept-Encoding']

        if accept_encoding && accept_encoding.split(',').map(&:strip).include?('gzip')
          # Compress the content using gzip
          compressed_content = StringIO.new
          gzip_writer = Zlib::GzipWriter.new(compressed_content)
          gzip_writer.write(content)
          gzip_writer.close
          compressed_body = compressed_content.string

          # Send the compressed response
          client_socket.send "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Encoding: gzip\r\nContent-Length: #{compressed_body.bytesize}\r\n\r\n", 0
          client_socket.write(compressed_body)
        else
          # If gzip is not supported or invalid encoding is provided, respond normally
          client_socket.send "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{content.length}\r\n\r\n#{content}", 0
        end

      elsif path.start_with?('/files/')
        # Handle /files/{filename} path
        directory = ARGV[1] # Get directory from command-line arguments
        filename = path.split('/files/').last
        file_path = File.join(directory, filename)

        if method == 'POST'
          # Read headers to find Content-Length
          headers = {}
          while (line = client_socket.readline.chomp) != ''
            key, value = line.split(': ', 2)
            headers[key] = value
          end

          content_length = headers['Content-Length'].to_i
          request_body = client_socket.read(content_length)

          # Write the request body to the file
          File.open(file_path, 'w') { |file| file.write(request_body) }

          # Respond with 201 Created
          client_socket.send "HTTP/1.1 201 Created\r\n\r\n", 0

        elsif method == 'GET'
          begin
            # Read the file contents
            content = File.read(file_path)
            client_socket.send "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{content.length}\r\n\r\n#{content}", 0
          rescue Errno::ENOENT
            # Respond with 404 if the file does not exist
            client_socket.send "HTTP/1.1 404 Not Found\r\n\r\n", 0
          end
        else
          # Respond with 405 Method Not Allowed for unsupported methods
          client_socket.send "HTTP/1.1 405 Method Not Allowed\r\n\r\n", 0
        end

      else
        # Respond with 404 Not Found for unknown paths
        client_socket.send "HTTP/1.1 404 Not Found\r\n\r\n", 0
      end

    rescue => e
      puts "An error occurred: #{e.message}"
      client_socket.send "HTTP/1.1 500 Internal Server Error\r\n\r\n", 0
    ensure
      # Ensure the client socket is closed
      client_socket.close
    end
  end
end