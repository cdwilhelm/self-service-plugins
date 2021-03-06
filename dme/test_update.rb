require 'uri'
require 'net/http'
require 'json'

  def put(path, body)
    request(path) do |uri|
      req = Net::HTTP::Put.new(uri.path)
      req.body = body.to_json
      req
    end

  end

  def request(path)
    uri = URI("#{path}")

    http = Net::HTTP.new(uri.host, uri.port)

    request = yield(uri)

    request_headers.each do |key, value|
      request[key] = value
    end

    response = http.request(request)
    puts response.body
    unparsed_json = response.body == "" ? "{}" : response.body

    puts response.code
    puts response.message

  end

  def request_headers
    {
      'Content-type' => 'application/json',
      'X-Api-Version' => '1.0'
    }
  end

  put('http://localhost:9292/record/dev.rightscaleit.com/15984155', {"name"=>"ryanolearytest","type"=>"A","value"=>"5.5.5.5"})
