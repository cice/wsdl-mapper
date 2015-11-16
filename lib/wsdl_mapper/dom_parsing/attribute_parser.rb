require 'wsdl_mapper/dom_parsing/parser_base'
require 'wsdl_mapper/dom/attribute'

module WsdlMapper
  module DomParsing
    class AttributeParser < ParserBase
      # @param [Nokogiri::XML::Node] node
      def parse node
        parse_attribute node, @base.schema
      end

      def parse_attribute node, container
        name = parse_name_in_attribute 'name', node
        ref = parse_name_in_attribute 'ref', node

        attr = if name
          type_name = parse_name_in_attribute 'type', node

          Attribute.new name, type_name,
            default: fetch_attribute_value('default', node),
            use: fetch_attribute_value('use', node, 'optional'),
            fixed: fetch_attribute_value('fixed', node),
            form: fetch_attribute_value('form', node)
        elsif ref
          Attribute::Ref.new ref
        else
          log_msg node, :invalid_attribute
        end

        container.add_attribute attr

        each_element node do |child|
          case get_name child
          when ANNOTATION
            parse_annotation child, attr
          else
            log_msg child, :unknown
          end
        end
      end

      protected
      # @param [Nokogiri::XML::Node] node
      # @param [WsdlMapper::Dom::Element] element
      def parse_element_child node, element
        case get_name node
        when ANNOTATION
          parse_annotation node, element
        else
          log_msg node, :unknown
        end
      end
    end
  end
end