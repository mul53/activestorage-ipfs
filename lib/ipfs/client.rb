# frozen_string_literal: true

require 'http'
require 'json'

module Ipfs
  class Error < StandardError; end

  class Client
    attr_reader :endpoint, :http_client

    def initialize(endpoint)
      @endpoint = endpoint
      @http_client = HTTP
    end

    def add(path)
      response = @http_client.post(
        "#{@endpoint}/api/v0/add",
        form: {
          file: HTTP::FormData::File.new(path)
        }
      )

      if response.code >= 200 && response.code <= 299
        JSON.parse(response.body)
      else
        raise Error, response.body
      end
    end

    def build_file_url(hash)
      "#{@endpoint}/ipfs/#{hash}"
    end
  end
end
