require 'ipfs/client'
module ActiveStorage
  class Service::IpfsService < Service
    attr_reader :client

    def initialize(api_endpoint:, gateway_endpoint:)
      @client = Ipfs::Client.new api_endpoint, gateway_endpoint
    end

    # File is uploaded to Ipfs and a hash
    # is returned which is used to retrieve the file
    # Change the key of the blob to that of the hash
    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        data = @client.add io.path
        find_blob_by_key(key).update(key: data['Hash'])
        # TODO: Ensure integrity of checksum
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          @client.download key, &block
        end
      else
        instrument :download, key: key do
          # Make a query to check if file exists before
          # making download request to prevent hanging
          # requests when file doesn't exist
          @client.file_exists! key
          @client.download key
        rescue Ipfs::NotFoundError
          raise ActiveStorage::FileNotFoundError
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        @client.file_exists! key
        @client.cat key, range.begin, range.size
      rescue Ipfs::NotFoundError
        raise ActiveStorage::FileNotFoundError
      end
    end

    def url(key, content_type: nil, filename: nil, expires_in: nil, disposition: nil)
      @client.build_file_url key, filename.to_s
    end

    def exists?(key)
      instrument :exist, key: key do |payload|
        answer = @client.file_exists?(key)
        payload[:exist] = answer
        answer
      end
    end

    private

    def find_blob_by_key(key)
      Blob.find_by_key key
    end
  end
end
