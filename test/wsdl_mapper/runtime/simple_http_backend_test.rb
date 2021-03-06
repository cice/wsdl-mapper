require 'test_helper'
require 'wsdl_mapper_testing/fake_operation'

require 'wsdl_mapper/runtime/simple_http_backend'

module RuntimeTests
  class SimpleHttpBackendTest < WsdlMapperTesting::Test
    def setup
      @operation = FakeOperation.new

      @cnx = WsdlMapperTesting::StubConnection.new
      @test_url = 'http://example.org/some-url'
      @test_action = 'SomeAction'
      @input = Object.new
      @output = Object.new
      @message = WsdlMapper::Runtime::Message.new @test_url, @test_action, @input
      @backend = WsdlMapper::Runtime::SimpleHttpBackend.new(connection: @cnx)
    end

    def setup_mock_request_response(request_xml, response_xml)
      @operation.input_s8r.xml_for_input @input, request_xml
      @operation.output_d10r.output_for_xml response_xml, @output
      @operation.input_for_body @input, @message
    end

    def test_a_successful_request
      setup_mock_request_response 'foo bar', 'lorem ipsum'
      @cnx.stub_request @test_url, 'foo bar', 'lorem ipsum'

      response = @backend.dispatch @operation, @input

      assert_kind_of WsdlMapper::Runtime::Response, response
      assert_equal 'lorem ipsum', response.body
      assert_equal @output, response.envelope
    end

    def test_a_transport_error
      setup_mock_request_response 'foo bar', 'lorem ipsum'
      @cnx.stub_error @test_url, Faraday::Error.new

      begin
        @backend.dispatch @operation, @input
        assert false, 'Expected an error'
      rescue => e
        assert_kind_of WsdlMapper::Runtime::Errors::TransportError, e
      end
    end
  end
end
