# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe Puppet::Type.type(:nomad_key_value).provider(:cli) do
  let(:resource) do
    Puppet::Type.type(:nomad_key_value).new(
      {
        name: 'hello/kitty',
        value: {
          'key1' => 'value1',
          'key2' => 'value2',
        }
      }
    )
  end

  let(:resources) { { 'hello/kitty' => resource } }

  describe '.list_resources' do
    context 'when the first two responses are unexpected' do
      it 'retries 3 times' do
        success_status = instance_double(Process::Status, success?: true)
        failure_status = instance_double(Process::Status, success?: false)

        allow(Open3).to receive(:capture3).
          with('/usr/bin/nomad var get -out json hello/kitty').
          and_return(['', '', failure_status]). # First attempt fails
          and_return(['', '', failure_status]). # Second attempt fails
          and_return([
                       JSON.dump(
                         'Namespace' => 'default',
                         'Path' => 'hello/kitty',
                         'CreateIndex' => 1_350_503,
                         'ModifyIndex' => 1_350_503,
                         'Items' => {
                           'key1' => 'value1',
                           'key2' => 'value2',
                         }
                       ),
                       success_status
                     ])

        described_class.prefetch(resources)
        expect(resource.provider.exists?).to be true

        output, _status = Open3.capture3('/usr/bin/nomad var get -out json hello/kitty')
        json_data = JSON.parse(output)

        expect(json_data['Items']).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
      end
    end
  end
end
