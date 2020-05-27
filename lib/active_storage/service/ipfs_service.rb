module ActiveStorage
  class Service::IpfsService < Service
    attr_reader :client

    def initialize(endpoint:)
      @client = Ipfs::Client.new(endpoint)
    end

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        @client.add(io.path)
      end
    end
  end
end
