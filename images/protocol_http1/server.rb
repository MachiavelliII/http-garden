# frozen_string_literal: true

require 'base64'
require 'json'
require 'socket'
require 'protocol/http1/connection'
require 'protocol/http/body/buffered'

def handle_connection(connection)
  loop do
    begin
      request = connection.read_request
    rescue EOFError, Protocol::HTTP::DuplicateHeaderError
      break
    end
    break unless request

    authority, method, path, version, headers, body_reader = request
    begin
      body = body_reader ? body_reader.join : nil
    rescue EOFError, NoMethodError
      break
    end
    if not body
      body = ''
    end
    b64_headers = headers.fields.map do |k, v|
      [Base64.encode64(k).strip, Base64.encode64(v).strip]
    end
    b64_headers += [[Base64.encode64('Host').strip, Base64.encode64(authority).strip]] if authority
    result = {
      'headers': b64_headers,
      'method': Base64.encode64(method).strip,
      'uri': Base64.encode64(path).strip,
      'version': Base64.encode64(version).strip,
      'body': Base64.encode64(body).strip
    }.to_json

    connection.write_response(version, 200, [])
    connection.write_body(version, Protocol::HTTP::Body::Buffered.wrap(result))

    break unless connection.persistent
  rescue Protocol::HTTP1::InvalidRequest, Protocol::HTTP1::BadRequest, Protocol::HTTP1::BadHeader, Protocol::HTTP1::LineLengthError
    break
  end
end

Addrinfo.tcp('0.0.0.0', 80).listen do |server|
  loop do
    client, _address = server.accept
    connection = Protocol::HTTP1::Connection.new(client)
    handle_connection(connection)
  end
end
