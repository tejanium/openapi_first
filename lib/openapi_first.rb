# frozen_string_literal: true

require 'oas_parser'
require 'openapi_first/version'

module OpenapiFirst
  OPERATION = 'openapi_first.operation'
  PATH_PARAMS = 'openapi_first.path_params'
  REQUEST_BODY = 'openapi_first.parsed_request_body'
  QUERY_PARAMS = 'openapi_first.query_params'

  def self.load(spec_path)
    OasParser::Definition.resolve(spec_path)
  end

  class Error < StandardError; end
  # Your code goes here...
end
