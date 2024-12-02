# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:nomad_key_value) do
  it 'fails if no name is provided' do
    expect do
      Puppet::Type.type(:nomad_key_value).new(type: 'client')
    end.to raise_error(Puppet::Error, %r{Title or name must be provided})
  end

  context 'with query parameters provided' do
    let(:key_value) do
      Puppet::Type.type(:nomad_key_value).new(
        name: 'sample/key',
        value: {
          'key1' => 'value1',
          'key2' => 'value2',
        }
      )
    end

    it 'defaults to http://127.0.0.1:4646' do
      expect(key_value[:address]).to eq('http://127.0.0.1:4646')
    end

    it 'defaults to /usr/bin/nomad' do
      expect(key_value[:binary_path]).to eq('/usr/bin/nomad')
    end
  end
end
