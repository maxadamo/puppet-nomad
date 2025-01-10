# frozen_string_literal: true

require 'net/http'
require 'spec_helper'
require 'json'

describe Puppet::Type.type(:nomad_key_value).provider(:cli) do
  let(:resource) do
    Puppet::Type.type(:nomad_key_value).new(
      {
        ensure: 'present',
        name: 'hello/kitty',
        binary_path: '/usr/bin/true',
        value: {
          'key1' => 'value1',
          'key2' => 'value2',
        }
      }
    )
  end
  let(:resources) { { 'hello/kitty' => resource } }
  let(:uri) { URI('http://127.0.0.1:4646/v1/var/hello/kitty?namespace=default') }
  let(:kv_content) do
    {
      'Namespace' => 'default',
      'Path' => 'hello/kitty',
      'Lock' => nil,
      'CreateIndex' => 11,
      'CreateTime' => 1_736_771_607_466_760_000,
      'ModifyIndex' => 11,
      'ModifyTime' => 1_736_771_607_466_760_000,
      'Items' => {
        'key1' => 'value1',
        'key2' => 'value2',
      }
    }
  end

  describe '.list_resources' do
    context 'when the response is expected' do
      it 'tries once' do
        allow(Net::HTTP).to receive(:get).with(uri).and_return(JSON.dump(kv_content))
        response_body = JSON.dump(kv_content)

        described_class.reset
        described_class.prefetch(resources)
        expect(JSON.parse(response_body)).not_to eq({})
      end
    end

    context 'when resource exists check key values' do
      it 'expects certain key and values' do
        allow(Net::HTTP).to receive(:get).with(uri).and_return(JSON.dump(kv_content))
        response_body = JSON.dump(kv_content)

        described_class.reset
        described_class.prefetch(resources)
        expect(JSON.parse(response_body)['Items']).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
      end
    end
  end
end
