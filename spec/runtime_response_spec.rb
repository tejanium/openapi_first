# frozen_string_literal: true

RSpec.describe OpenapiFirst::RuntimeResponse do
  subject(:response) do
    definition.request(rack_request).response(rack_response)
  end

  let(:rack_request) do
    Rack::Request.new(Rack::MockRequest.env_for('/pets/1'))
  end

  let(:rack_response) { Rack::Response.new(JSON.dump([]), 200, { 'Content-Type' => 'application/json' }) }

  let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

  describe '#status' do
    it 'returns the HTTP status code of the response' do
      expect(response.status).to eq(200)
    end
  end

  describe '#content_type' do
    it 'returns the content-type of the response' do
      expect(response.content_type).to eq('application/json')
    end
  end

  describe '#body' do
    let(:rack_response) do
      Rack::Response.new(JSON.dump({ foo: :bar }), 200, { 'Content-Type' => 'application/json' })
    end

    it 'returns the parsed body' do
      expect(response.body).to eq('foo' => 'bar')
    end

    context 'without json content-type' do
      let(:rack_response) do
        Rack::Response.new(JSON.dump({ foo: :bar }))
      end

      it 'does not parse the body' do
        expect(response.body).to eq(JSON.dump({ foo: :bar }))
      end
    end
  end

  describe '#name' do
    it 'returns a name to identify the operation' do
      expect(response.name).to eq('GET /pets/{petId} (showPetById)')
    end
  end

  describe '#known?' do
    it 'returns true' do
      expect(response.known?).to be true
    end

    context 'when response is not defined' do
      let(:rack_response) do
        Rack::Response.new('', 209)
      end

      it 'returns false' do
        expect(response.known?).to be false
      end
    end
  end

  describe '#known_status?' do
    it 'returns true' do
      expect(response.known_status?).to be true
    end

    context 'when status is not defined' do
      let(:rack_response) do
        Rack::Response.new('', 209)
      end

      it 'returns false' do
        expect(response.known_status?).to be false
      end
    end
  end

  describe '#headers' do
    let(:definition) { OpenapiFirst.load('./spec/data/response-header.yaml') }

    subject(:response) do
      operation = definition.path('/echo').operation('post')
      described_class.new(operation, rack_response)
    end

    let(:rack_response) do
      headers = {
        'Content-Type' => 'application/json',
        'Unknown' => 'Cow',
        'X-Id' => '42'
      }
      Rack::Response.new('', 201, headers)
    end

    it 'returns the unpacked headers as defined in the API description' do
      expect(response.headers).to eq(
        'Content-Type' => 'application/json',
        'X-Id' => 42
      )
    end

    context 'when response has no headers' do
      let(:rack_response) { Rack::Response.new }

      it 'is empty' do
        expect(response.headers).to eq({})
      end
    end

    context 'when no headers are defined' do
      let(:rack_response) do
        Rack::Response.new('', 204)
      end

      it 'is empty' do
        expect(response.headers).to eq({})
      end
    end

    context 'when response is not defined' do
      let(:rack_response) do
        Rack::Response.new('', 209)
      end

      it 'is empty' do
        expect(response.headers).to eq({})
      end
    end
  end

  describe '#validate!' do
    context 'if response is valid' do
      it 'returns nil' do
        expect(response.validate!).to be_nil
      end
    end

    context 'if response is invalid' do
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'raises ResponseInvalidError' do
        expect do
          response.validate!
        end.to raise_error(OpenapiFirst::ResponseInvalidError)
      end
    end

    context 'if request is unknown' do
      let(:rack_request) { Rack::Request.new(Rack::MockRequest.env_for('/unknown')) }
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'skips response validation and returns nil' do
        expect(response.validate!).to be_nil
      end
    end
  end

  describe 'validate' do
    context 'if response is valid' do
      it 'returns nil' do
        expect(response.validate).to be_nil
      end
    end

    context 'if response is invalid' do
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns a Failure' do
        result = response.validate
        expect(result).to be_a(OpenapiFirst::Failure)
        expect(result.error_type).to eq :invalid_response_body
      end
    end
  end
end