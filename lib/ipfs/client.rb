# frozen_string_literal: true

require 'http'
require 'json'

module Ipfs
  class Error < StandardError; end

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

    def download_chunks(hash, &block)
      url = build_file_url(hash)
      res = @http_client.get(url)
      res.body.each(&block)
    end

    def download(hash)
      url = build_file_url(hash)
      res = @http_client.get(url)
      res.body
    end

    def build_file_url(hash)
      "#{@gateway_endpoint}/ipfs/#{hash}"
    end
  end
end
