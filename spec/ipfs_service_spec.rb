require 'spec_helper'

RSpec.describe ActiveStorage::Service::IpfsService do
  let(:api_endpoint) { 'http://localhost:5001' }
  let(:gateway_endpoint) { 'http://localhost:8080' } 
  let(:key) { 'some-key' }
  let(:file) { double }
  let(:filename) { 'text.txt' }
  let(:checksum) { 'ushagte' }
  
  let(:subject) { ActiveStorage::Service::IpfsService.new(api_endpoint: api_endpoint, gateway_endpoint: gateway_endpoint) }

  before do
    stub_const('ActiveStorage::Blob', BlobStub)

    allow(file).to receive(:path).and_return('spec/image.png')
  end

  describe '#new' do
    it 'initializes without failure' do
      subject
    end
  end

  describe '#upload' do
    it 'calls the add method on client with given args' do
      client = instance_double('Ipfs::Client')
      allow(client)
        .to receive(:add).and_return({ 'hash' => 'some-key' })
      
      subject.client = client

      expect(client)
        .to receive(:add).with('spec/image.png')

      subject.upload(key, file)
    end

    it 'instruments the operation' do
      options = { key: key, checksum: checksum }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:upload, options)

      subject.upload(key, file, checksum: checksum)
    end
  end

  describe '#exists' do
    it 'calls file_exists? method on client with given args' do
      client = instance_double('Ipfs::Client')
      allow(client)
        .to receive(:file_exists?).and_return(true)

      subject.client = client

      expect(client)
        .to receive(:file_exists?).with(key)

      subject.exists?(key)
    end

    it 'instruments the operation' do
      options = { key: key }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:exist, options)

      subject.exists?(key)
    end
  end

  describe '#download' do
    it 'calls download method with key' do
      client = instance_double('Ipfs::Client')

      subject.client = client

      expect(client)
        .to receive(:download).with(key)

      subject.download(key)
    end

    it 'calls download method with key and block' do
      client = instance_double('Ipfs::Client')
      block = -> { 'some block' }

      subject.client = client

      expect(client)
        .to receive(:download).with(key) { |&blk| expect(blk).to be(block) }

      subject.download(key, &block)
    end

    it 'instruments the normal download operation' do
      options = { key: key }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:download, options)

      subject.download(key)
    end

    it 'instruments the streaming download operation' do
      options = { key: key }
      block = -> { 'some block' }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:streaming_download, options)

      subject.download(key, &block)
    end
  end

  describe '#download_chunk' do
    let(:range) { 1..5 }

    it 'calls cat method on client with given args' do
      client = instance_double('Ipfs::Client')

      subject.client = client

      expect(client)
        .to receive(:cat).with(key, 1, 5)

      subject.download_chunk(key, range)
    end

    it 'instruments the operation' do
      options = { key: key, range: range }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:download_chunk, options)

      subject.download_chunk(key, range)
    end
  end

  describe '#url' do
    it 'returns url for file at specified key' do
      client = instance_double('Ipfs::Client')
      allow(client)
        .to receive(:build_file_url).and_return("#{gateway_endpoint}/#{key}")

      subject.client = client

      expect(subject.url(key))
        .to eq("#{gateway_endpoint}/#{key}");
    end

    it 'returns url for file at specified key and adds filename' do
      client = instance_double('Ipfs::Client')
      allow(client)
        .to receive(:build_file_url).and_return("#{gateway_endpoint}/#{key}?filename=#{filename}")

      subject.client = client

      expect(subject.url(key))
        .to eq("#{gateway_endpoint}/#{key}?filename=#{filename}");
    end

    it 'instruments the operation' do
      options = { key: key }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:url, options)

      subject.url(key)
    end
  end

  describe '#url_for_direct_upload' do
    it 'returns direct upload url for file' do
      client = instance_double('Ipfs::Client')
      allow(client)
        .to receive(:api_endpoint).and_return(api_endpoint)

      subject.client = client

      expect(subject.url_for_direct_upload(key))
        .to eq("#{api_endpoint}/api/v0/add");
    end

    it 'instruments the operation' do
      options = { key: key }

      expect_any_instance_of(ActiveStorage::Service)
        .to receive(:instrument).with(:url_for_direct_upload, options)

      subject.url_for_direct_upload(key)
    end
  end
end
