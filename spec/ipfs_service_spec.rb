require 'spec_helper'

RSpec.describe ActiveStorage::Service::IpfsService do
  let(:subject) { ActiveStorage::Service::IpfsService.new(config) }

  describe '#new' do
    it 'initializes without failure' do
      subject
    end
  end
end
