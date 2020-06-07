# frozen_string_literal: true

require 'http'
require 'json'

module Ipfs
  class Error < StandardError; end
  class NotFoundError < Error; end

  class Client
    attr_reader :api_endpoint, :gateway_endpoint, :http_client

    def initialize(api_endpoint, gateway_endpoint)
      @api_endpoint = api_endpoint
      @gateway_endpoint = gateway_endpoint
      @http_client = HTTP
    end

    def add(path)
      res = @http_client.post(
        "#{@api_endpoint}/api/v0/add",
        form: {
          file: HTTP::FormData::File.new(path)
        }
      )

      if res.code >= 200 && res.code <= 299
        JSON.parse(res.body)
      else
        raise Error, res.body
      end
    end

    def cat(hash, offset, length)
      res = @http_client.get("#{@api_endpoint}/api/v0/cat?arg#{hash}&offset=#{offset}&length=#{length}")
      res.body
    end

    def dht_findProvs(hash, &block)
      res = @http_client.post("#{@api_endpoint}/api/v0/dht/findprovs?arg=#{hash}")
      res.body.each(&block)
    end

    def download(hash, &block)
      url = build_file_url(hash)
      res = @http_client.get(url)

      if block_given?
        res.body.each(&block)
      else
        res.body
      end
    end

    def file_exists?(key)
      dht_findProvs(key) do |chunk|
        res = chunk.split("\n")[0]
        res_json = JSON.parse res
        return res_json['Type'] == 4
      end
    end

    def build_file_url(hash, filename = '')
      query = filename.empty? ? '' : "?filename=#{filename}"
      "#{@gateway_endpoint}/ipfs/#{hash}#{query}"
    end
  end
end
