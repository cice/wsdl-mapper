require 'nokogiri'

require 'wsdl_mapper/dom/name'
require 'wsdl_mapper/parsing/logging'

module WsdlMapper
  module Parsing
    class Base
      include WsdlMapper::Dom
      include Logging

      TARGET_NS = 'targetNamespace'
      NS_DECL_PREFIX = 'xmlns'

      def initialize(base)
        @base = base
        @log_msgs = []
      end

      # @param [Nokogiri::XML::Node] node
      # @return [WsdlMapper::Dom::Name]
      def self.get_name(node)
        ns = node.namespace ? node.namespace.href : nil
        name = node.name

        Name.get ns, name
      end

      protected
      # @param [Nokogiri::XML::Node] node
      def parse_node(node)
        name = get_name(node)

        parser = @base.parsers[name]

        if parser
          parser.parse node
        else
          log_msg node, :unknown
        end
      end

      # @param [Nokogiri::XML::Document] doc
      def parse_namespaces(doc)
        doc.namespaces.each do |key, ns|
          if key == NS_DECL_PREFIX
            @default_namespace = ns
          else
            code = key.sub /^#{NS_DECL_PREFIX}\:/, ''
            @namespaces[code] = ns
          end
        end
      end

      # @param [Nokogiri::XML::Node] node
      def parse_target_namespace(node)
        attr = node.attributes[TARGET_NS]
        if attr
          @target_namespace = attr.value
        end
      end

      # @param [Nokogiri::XML::Node] node
      # @return [WsdlMapper::Dom::Name]
      def get_name(node)
        self.class.get_name node
      end

      # @param [Nokogiri::XML::Node] node
      def is_element?(node)
        node.is_a? Nokogiri::XML::Element
      end

      # @param [Nokogiri::XML::Node] node
      def first_element(node)
        node.children.find { |n| is_element? n }
      end

      # @param [Nokogiri::XML::Node] node
      def first_element!(node)
        first_element(node) ||
          raise(ArgumentError.new("#{node.name} has no child elements."))
      end

      # @param [Nokogiri::XML::Node] node
      # @param [WsdlMapper::Dom::Name] name
      def select_nodes(node, name)
        node.children.select { |n| is_element?(n) && name_matches?(n, name) }
      end

      # @param [Nokogiri::XML::Node] node
      # @param [WsdlMapper::Dom::Name] name
      def find_node(node, name)
        node.children.find { |n| is_element?(n) && name_matches?(n, name) }
      end

      # @param [Nokogiri::XML::Node] node
      # @param [WsdlMapper::Dom::Name] name
      def name_matches?(node, name)
        return node.name == name.name && name.ns.nil? if node.namespace.nil?

        node.name == name.name && node.namespace.href == name.ns
      end

      # @param [Nokogiri::XML::Node] node
      # @yieldparam [Nokogiri::XML::Node] child
      def each_element(node)
        node.children.each do |child|
          next unless is_element? child
          yield child
        end
      end

      # @param [String] name
      # @param [Nokogiri::XML::Node] node
      # @param [String] default_value
      # @return [String]
      def fetch_attribute_value(name, node, default_value = nil)
        attr = node.attributes[name]
        attr ? attr.value : default_value
      end

      # @param [String] name
      # @param [Nokogiri::XML::Node] node
      # @return [WsdlMapper::Dom::Name]
      def parse_name_in_attribute(name, node)
        val = fetch_attribute_value name, node
        return unless val
        parse_name val, node
      end

      # @param [String] name_str
      # @return [WsdlMapper::Dom::Name]
      def parse_name(name_str, node)
        name, ns_code = name_str.split(':').reverse
        ns = if ns_code.nil?
          @base.target_namespace
        elsif ns_code == 'xml'
          'http://www.w3.org/XML/1998/namespace'
        else
          node.namespaces["xmlns:#{ns_code}"]
        end

        Name.get ns, name
      end
    end
  end
end
