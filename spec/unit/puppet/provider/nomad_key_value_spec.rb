# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe Puppet::Type.type(:nomad_key_value).provider(:default) do
  let(:resource) do
    Puppet::Type.type(:nomad_key_value).new(
      name: 'hello/kitty',
      value: { 'key10' => 'value12', 'key20' => 'value20' },
      binary_path: '/usr/bin/nomad'
    )
  end

  let(:kv_content) do
    {
      'Namespace' => 'default',
      'Path' => 'hello/kitty',
      'CreateIndex' => 6_458_825,
      'ModifyIndex' => 6_460_742,
      'CreateTime' => 1_731_520_237_405_899_500,
      'ModifyTime' => 1_731_577_297_768_117_574,
      'Items' => {
        'key10' => 'value12',
        'key20' => 'value20'
      }
    }
  end

  let(:resources) { { 'hello/kitty' => resource } }

  describe '.list_resources' do
    context 'when the first two attempts fail' do
      it 'retries and succeeds on the third attempt' do
        success_status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).
          with('/usr/bin/nomad var get -out json hello/kitty').
          and_return(['johnny', '', success_status]).
          and_return(['mary', '', success_status]).
          and_return([JSON.dump('sdfsfds'), '', success_status])

        described_class.reset
        described_class.prefetch(resources)

        output, _status = Open3.capture3('/usr/bin/nomad var get -out json hello/kitty')
        json_data = JSON.parse(output)

        expect(json_data['Items']).to eq({ 'key10' => 'value12', 'key20' => 'value20' })
      end
    end
  end

  describe '#exists?' do
    context 'when the key exists' do
      it 'returns true' do
        success_status = instance_double(Process::Status, success?: true)

        allow(Open3).to receive(:capture3).
          with('/usr/bin/nomad var get -out json hello/kitty').
          and_return([JSON.dump(kv_content), '', success_status])

        expect(provider.exists?).to be(true)
      end
    end

    context 'when the key does not exist' do
      it 'returns false' do
        failure_status = instance_double(Process::Status, success?: false)

        allow(Open3).to receive(:capture3).
          with('/usr/bin/nomad var get -out json byebye/kitty').
          and_return(['', '', failure_status])

        expect(provider.exists?).to be(false)
      end
    end
  end
end
#  describe '#create' do
#    context 'when key does not exist' do
#      it 'writes to consul' do
#        kv_content = [
#          { 'LockIndex' => 0,
#            'Key' => 'sample/key-different-key',
#            'Flags' => 0,
#            'Value' => 'RGlmZmVyZW50IHZhbHVl', # Different value
#            'CreateIndex' => 1_350_503,
#            'ModifyIndex' => 1_350_503 },
#        ]
#
#        stub_request(:get, 'http://localhost:8500/v1/kv/?dc=dc1&recurse').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: JSON.dump(kv_content), headers: {})
#
#        stub_request(:put, 'http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=0').
#          with(body: 'sampleValue',
#               headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
#          to_return(status: 200, body: '', headers: {})
#
#        described_class.reset
#        described_class.prefetch(resources)
#        resource.provider.create
#        resource.provider.flush
#      end
#    end
#
#    context 'when key does exist, with different value' do
#      it 'writes to consul' do
#        kv_content = [
#          { 'LockIndex' => 0,
#            'Key' => 'sample/key',
#            'Flags' => 0,
#            'Value' => 'RGlmZmVyZW50IHZhbHVl', # Different value
#            'CreateIndex' => 1_350_503,
#            'ModifyIndex' => 1_350_503 },
#        ]
#
#        stub_request(:get, 'http://localhost:8500/v1/kv/?dc=dc1&recurse').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: JSON.dump(kv_content), headers: {})
#
#        stub_request(:put, 'http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=0').
#          with(body: 'sampleValue',
#               headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
#          to_return(status: 200, body: '', headers: {})
#
#        described_class.reset
#        described_class.prefetch(resources)
#        resource.provider.create
#        resource.provider.flush
#      end
#    end
#
#    context 'when key does exist, with different flag' do
#      it 'writes to consul' do
#        kv_content = [
#          { 'LockIndex' => 0,
#            'Key' => 'sample/key',
#            'Flags' => 1,
#            'Value' => 'c2FtcGxlVmFsdWU=', # sampleValue
#            'CreateIndex' => 1_350_503,
#            'ModifyIndex' => 1_350_503 },
#        ]
#
#        resource = Puppet::Type.type(:nomad_key_value).new(
#          {
#            name: 'sample/key',
#            value: 'sampleValue',
#            flags: 2,
#            acl_api_token: 'sampleToken',
#            datacenter: 'dc1',
#          }
#        )
#        resources = { 'sample/key' => resource }
#
#        stub_request(:get, 'http://localhost:8500/v1/kv/?dc=dc1&recurse').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: JSON.dump(kv_content), headers: {})
#
#        stub_request(:put, 'http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=2').
#          with(body: 'sampleValue',
#               headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
#          to_return(status: 200, body: '', headers: {})
#
#        described_class.reset
#        described_class.prefetch(resources)
#        resource.provider.create
#        resource.provider.flush
#      end
#    end
#
#    context 'when consul returns an error' do
#      it 'raises Puppet::Error on failed create' do
#        kv_content = [
#          { 'LockIndex' => 0,
#            'Key' => 'sample/different-key',
#            'Flags' => 0,
#            'Value' => 'c2FtcGxlVmFsdWU=', # sampleValue
#            'CreateIndex' => 1_350_503,
#            'ModifyIndex' => 1_350_503 },
#        ]
#
#        stub_request(:get, 'http://localhost:8500/v1/kv/?dc=dc1&recurse').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: JSON.dump(kv_content), headers: {})
#
#        stub_request(:put, 'http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=0').
#          with(body: 'sampleValue',
#               headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
#          to_return(status: 400, body: '', headers: {})
#
#        described_class.reset
#        described_class.prefetch(resources)
#        resource.provider.create
#        expect { resource.provider.flush }.to raise_error(Puppet::Error, %r{Session sample/key create/update: invalid return code 400 uri:})
#      end
#    end
#  end
#
#  describe '#destroy' do
#    context 'when key exists' do
#      it 'deletes key' do
#        kv_content = [
#          { 'LockIndex' => 0,
#            'Key' => 'sample/key',
#            'Flags' => 0,
#            'Value' => 'RGlmZmVyZW50IHZhbHVl', # Different value
#            'CreateIndex' => 1_350_503,
#            'ModifyIndex' => 1_350_503 },
#        ]
#
#        stub_request(:get, 'http://localhost:8500/v1/kv/?dc=dc1&recurse').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: JSON.dump(kv_content), headers: {})
#
#        stub_request(:delete, 'http://localhost:8500/v1/kv/sample/key?dc=dc1').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: '', headers: {})
#
#        described_class.reset
#        described_class.prefetch(resources)
#        resource.provider.destroy
#        resource.provider.flush
#      end
#    end
#
#    context 'when key exists, but consul returns an error' do
#      it 'raises error on failed delete' do
#        kv_content = [
#          { 'LockIndex' => 0,
#            'Key' => 'sample/key',
#            'Flags' => 0,
#            'Value' => 'RGlmZmVyZW50IHZhbHVl', # Different value
#            'CreateIndex' => 1_350_503,
#            'ModifyIndex' => 1_350_503 },
#        ]
#
#        stub_request(:get, 'http://localhost:8500/v1/kv/?dc=dc1&recurse').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 200, body: JSON.dump(kv_content), headers: {})
#
#        stub_request(:delete, 'http://localhost:8500/v1/kv/sample/key?dc=dc1').
#          with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby', 'X-Consul-Token' => 'sampleToken' }).
#          to_return(status: 400, body: '', headers: {})
#
#        described_class.reset
#        described_class.prefetch(resources)
#        resource.provider.destroy
#
#        expect { resource.provider.flush }.to raise_error(Puppet::Error, %r{Session sample/key delete: invalid return code 400 uri:})
#      end
#    end
#  end
# end
