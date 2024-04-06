# frozen_string_literal: true

require 'forwardable'
require 'openapi_parameters'
require_relative 'runtime_response'
require_relative 'body_parser'
require_relative 'response_validation/validator'

module OpenapiFirst
  # RuntimeRequest represents how an incoming request (Rack::Request) matches a request definition.
  class RuntimeRequest
    extend Forwardable

    def initialize(request:, path_item:, operation:, path_params:)
      @request = request
      @path_item = path_item
      @operation = operation
      @original_path_params = path_params
    end

    def_delegators :@request, :content_type, :media_type, :path
    def_delegators :@operation, :operation_id, :request_method
    def_delegator :@path_item, :path, :path_definition

    # Returns the path_item object.
    # @return [PathItem, nil] The path_item object or nil if this request path is not known.
    attr_reader :path_item

    # Returns the operation object.
    # @return [Operation, nil] The operation object or nil if this request method is not known.
    attr_reader :operation

    # Returns the error object if validation failed.
    # @return [Failure, nil]
    attr_accessor :error

    # Checks if the path and request method are known.
    # @return [Boolean] true if the path and request method are known, false otherwise.
    def known?
      known_path? && known_request_method?
    end

    # Checks if the path is known.
    # @return [Boolean] true if the path is known, false otherwise.
    def known_path?
      !!path_item
    end

    # Checks if the request method is known.
    # @return [Boolean] true if the request method is known, false otherwise.
    def known_request_method?
      !!operation
    end

    # Returns the parsed path parameters of the request.
    # @return [Hash]
    def path_parameters
      @path_parameters ||= begin
        parameters = Array(path_item&.path_parameters) + Array(operation&.path_parameters)
        parameters ? OpenapiParameters::Path.new(parameters).unpack(@original_path_params) : {}
      end
    end

    # Returns the parsed query parameters.
    # This only includes parameters that are defined in the API description.
    # @note This method is aliased as query_parameters.
    # @return [Hash]
    def query
      @query ||= begin
        parameters = Array(path_item&.query_parameters) + Array(operation&.query_parameters)
        parameters ? OpenapiParameters::Query.new(parameters).unpack(request.env[Rack::QUERY_STRING]) : {}
      end
    end

    # Returns the parsed header parameters.
    # This only includes parameters that are defined in the API description.
    # @return [Hash]
    def headers
      @headers ||= begin
        parameters = Array(path_item&.header_parameters) + Array(operation&.header_parameters)
        OpenapiParameters::Header.new(parameters).unpack_env(request.env) || {}
      end
    end

    # Returns the parsed cookie parameters.
    # This only includes parameters that are defined in the API description.
    # @return [Hash]
    def cookies
      @cookies ||= begin
        parameters = Array(path_item&.cookie_parameters) + Array(operation&.cookie_parameters)
        parameters ? OpenapiParameters::Cookie.new(parameters).unpack(request.env[Rack::HTTP_COOKIE]) : {}
      end
    end

    # Returns the parsed request body.
    # This returns the whole request body with default values applied as defined in the API description.
    # This does not remove any fields that are not defined in the API description.
    # @return [Hash, Array, String, nil] The parsed body of the request.
    def body
      @body ||= BodyParser.new.parse(request, request.media_type)
    end

    private

    def validated?
      defined?(@error)
    end

    attr_reader :request
  end
end
