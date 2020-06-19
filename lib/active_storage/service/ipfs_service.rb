require 'ipfs/client'

class ActiveStorage::DirectUploadsController
  private
  def blob_args
      params.require(:blob).permit(:key, :filename, :byte_size, :checksum, :content_type, :metadata).to_h.symbolize_keys
  end
end

class ActiveStorage::Blob
  class << self
    def create_before_direct_upload!(key: nil, filename:, byte_size:, checksum:, content_type: nil, metadata: nil)
      find_or_create_by! key: key, filename: filename, byte_size: byte_size, checksum: checksum, content_type: content_type
    end
  end
end

module ActiveStorage
  class Service::IpfsService < Service
    attr_accessor :client

    def initialize(api_endpoint:, gateway_endpoint:)
      @client = Ipfs::Client.new api_endpoint, gateway_endpoint
    end

    # File is uploaded to Ipfs and a hash
    # is returned which is used to retrieve the file
    # Change the key of the blob to that of the hash
    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        data = @client.add io.path
        cid_key = data['Hash']

        if blob_exists?(cid_key)
          existing_blob = find_blob(cid_key)
          new_blob = find_blob(key)
          attachment = Attachment.last
          
          attachment.update blob_id: existing_blob.id
          new_blob.destroy!
        else
          find_blob(key).update key: cid_key
        end
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          @client.download key, &block
        end
      else
        instrument :download, key: key do
          @client.download key
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        @client.cat key, range.begin, range.size
      end
    end

    def url(key, content_type: nil, filename: nil, expires_in: nil, disposition: nil)
      instrument :url, key: key do
        @client.build_file_url key, filename.to_s
      end
    end

    def exists?(key)
      instrument :exist, key: key do
        @client.file_exists?(key)
      end
    end

    def url_for_direct_upload(key, expires_in: nil, content_type: nil, content_length: nil, checksum: nil)
      instrument :url_for_direct_upload, key: key do
        "#{@client.api_endpoint}/api/v0/add"
      end
    end

    private

    def find_blob(key)
      Blob.find_by_key key
    end

    def blob_exists?(key)
      Blob.exists?(key: key)
    end
  end
end
