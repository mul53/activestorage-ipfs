require 'ipfs/client'
module ActiveStorage
  class Service::IpfsService < Service
    attr_reader :client

    def initialize(api_endpoint:, gateway_endpoint:)
      @client = Ipfs::Client.new(api_endpoint, gateway_endpoint)
    end

    # File is uploaded to Ipfs and a hash
    # is returned which is used to retrieve the file
    # Change the key of the blob to that of the hash
    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        data = @client.add(io.path)
        Blob.find_by_key(key).update(key: data['Hash'])
      end
    end

    def download(key, &block)
      if block_given?
        @client.download_chunks key, &block
      else
        instrument :download, key: key do
          @client.download(key)
        end
      end
    end

    def url(key, content_type: nil, filename: nil, expires_in: nil, disposition: nil)
      @client.build_file_url(key)
    end
  end
end
