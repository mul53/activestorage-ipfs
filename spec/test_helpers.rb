module ActiveStorage
    class Service
        def instrument(_operation, _option = {})
            yield
        end
    end
end

class Model
    def update(params)
    end
end

class BlobStub
    class << self
        def find_by_key(key)
            Model.new
        end
    end
end

require 'active_storage/service/ipfs_service'
