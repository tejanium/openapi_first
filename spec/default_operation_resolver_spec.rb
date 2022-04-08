# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'openapi_first/default_operation_resolver'

RSpec.describe OpenapiFirst::DefaultOperationResolver do
  let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }

  let(:subject) { described_class.new(Web) }

  before do
    stub_const(
      'Web',
      Module.new do
        def self.some_method(_params, _res); end

        def self.create_pets(_params, _res); end
      end
    )
    stub_const(
      'Web::Things',
      Class.new do
        def self.some_class_method(_params, _res); end
      end
    )
    stub_const(
      'Web::Things::Index',
      Class.new do
        def call(_params, _res); end
      end
    )
    stub_const(
      'Web::Things::Show',
      Class.new do
        def call(_params, _res); end
      end
    )
  end

  describe '#call' do
    it 'finds the method in namespace' do
      expect(Web).to receive(:list_pets)
      operation = spec.operations.first
      subject.call(operation).call
    end
  end

  describe '#find_handler' do
    let(:env) { double }
    let(:params) { double(:params, env: env) }

    it 'finds some_method' do
      expect(Web).to receive(:some_method)
      subject.find_handler('some_method').call
    end

    it 'finds things.some_method' do
      expect(Web::Things).to receive(:some_class_method)
      subject.find_handler('things.some_class_method').call
    end

    it 'finds things#index' do
      expect_any_instance_of(Web::Things::Index).to receive(:call)
      subject.find_handler('things#index').call(params, double)
    end

    it 'finds things#show with initializer' do
      handler = subject.find_handler('things#show')
      response = double
      action = ->(params, res) {}
      expect(Web::Things::Show).to receive(:new) { action }
      expect(action).to receive(:call).with(params, response)
      handler.call(params, response)
    end

    it 'does not find unknown class' do
      expect(subject.find_handler('things#mautz')).to be_nil
    end

    it 'does not find inherited constants' do
      expect(subject.find_handler('string.to_s')).to be_nil
      expect(subject.find_handler('::string.to_s')).to be_nil
    end

    it 'does not find nested constants' do
      expect(subject.find_handler('foo.bar.to_s')).to be_nil
      expect(subject.find_handler('::foo::baz.to_s')).to be_nil
    end
  end
end
