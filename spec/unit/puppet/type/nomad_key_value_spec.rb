# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:nomad_key_value) do
  it 'fails if no name is provided' do
    Puppet::Type.type(:nomad_key_value).new(name: 'hello/kitty')
  end

  context 'with query parameters provided' do
    let(:key_value) do
      Puppet::Type.type(:nomad_key_value).new(
        name: 'hello/kitty',
        value: {
          'key1' => 'value1',
          'key2' => 'value2',
        }
      )
    end

    it 'has its name set' do
      expect(key_value[:name]).to eq('hello/kitty')
    end

    it 'defaults to http://127.0.0.1:4646' do
      expect(key_value[:address]).to eq('http://127.0.0.1:4646')
    end

    it 'defaults to global' do
      expect(key_value[:protocol]).to eq('global')
    end

    it 'defaults to default' do
      expect(key_value[:namespace]).to eq('default')
    end
  end
end
