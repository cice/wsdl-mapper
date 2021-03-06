require 'wsdl_mapper/svc_desc_parsing/parser_base'
require 'wsdl_mapper/svc_desc/wsdl11/service'

module WsdlMapper
  module SvcDescParsing
    class ServiceParser < ParserBase
      def parse(node)
        name = parse_name_in_attribute 'name', node

        service = Service.new name

        each_element node do |child|
          parse_service_child child, service
        end

        @base.description.add_service service
      end

      def parse_service_child(node, service)
        case get_name node
        when PORT
          parse_service_port node, service
        when DOCUMENTATION
          @base.parse_documentation node, service
        else
          log_msg node, :unknown
        end
      end

      def parse_service_port(node, service)
        name = parse_name_in_attribute 'name', node

        port = Service::Port.new name
        port.binding_name = parse_name_in_attribute 'binding', node

        success = true
        each_element node do |child|
          success = parse_port_child(child, port) && success
        end

        service.add_port(port) if success
      end

      def parse_port_child(node, port)
        case get_name node
        when Soap::ADDRESS
          parse_port_address node, port
        when Soap12::ADDRESS
          log_msg node, :unsupported
          return false
        when Http::ADDRESS
          log_msg node, :unsupported
          return false
        when DOCUMENTATION
          @base.parse_documentation node, port
        else
          log_msg node, :unknown
        end
      end

      def parse_port_address(node, port)
        port.address_location = fetch_attribute_value 'location', node
      end
    end
  end
end
