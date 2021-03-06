require 'wsdl_mapper/dom/name'

require 'wsdl_mapper/naming/type_name'
require 'wsdl_mapper/naming/property_name'
require 'wsdl_mapper/naming/enumeration_value_name'

require 'wsdl_mapper/naming/namer_base'

module WsdlMapper
  module Naming
    # This is the default Namer implementation. It provides the de-facto standard of organizing and naming
    # classes in ruby:
    #
    # 1. Class/Module names are CamelCase (e.g. `SomeType`)
    # 2. File names are under_score (e.g. `some_type.rb`)
    # 3. Each class in its own file
    # 4. (De)Serializers are put within the same module as XSD Types
    class DefaultNamer < NamerBase
      include WsdlMapper::Dom

      class InlineType < Struct.new(:name)
      end

      # Initializes a new {DefaultNamer} instance.
      #
      # @param [Array<String>] module_path the root module for the generated classes, e.g. `['MyApi', 'Types']` => `MyApi::Types::SomeClass` in `my_api/types/some_class.rb`
      # @param [String] content_attribute_name the accessor name for {file:concepts/wrapping_types.md wrapping types} (complex _type with simple content and simple types with restrictions)
      def initialize(module_path: [],
          content_attribute_name: 'content',
          soap_array_item_name: 'item')
        super module_path: module_path

        @content_attribute_name = content_attribute_name
        @soap_array_item_name = soap_array_item_name
      end

      # Returns a _type name for the given _type (simple or complex).
      #
      # @param [WsdlMapper::Dom::ComplexType, WsdlMapper::Dom::SimpleType] type
      # @return [TypeName]
      def get_type_name(type)
        type_name = TypeName.new get_class_name(type), get_class_module_path(type), get_class_file_name(type), get_class_file_path(type)
        type_name.parent = make_parents get_class_module_path(type)
        type_name
      end

      # @param [String] name
      # @return [TypeName]
      def get_support_name(name)
        type_name = TypeName.new get_support_class_name(name), get_support_module_path(name), get_support_file_name(name), get_support_file_path(name)
        type_name.parent = make_parents get_support_module_path(name)
        type_name
      end

      def get_s8r_type_directory_name
        get_support_name 'S8rTypeDirectory'
      end

      def get_global_s8r_name
        get_support_name 'Serializer'
      end

      def get_d10r_type_directory_name
        get_support_name 'D10rTypeDirectory'
      end

      def get_d10r_element_directory_name
        get_support_name 'D10rElementDirectory'
      end

      def get_global_d10r_name
        get_support_name 'Deserializer'
      end

      # @param [WsdlMapper::Dom::ComplexType, WsdlMapper::Dom::SimpleType] type
      # @return [TypeName]
      def get_s8r_name(type)
        type_name = TypeName.new get_s8r_class_name(type), get_s8r_module_path(type), get_s8r_file_name(type), get_s8r_file_path(type)
        type_name.parent = make_parents get_s8r_module_path(type)
        type_name
      end

      # @param [WsdlMapper::Dom::ComplexType, WsdlMapper::Dom::SimpleType] type
      # @return [TypeName]
      def get_d10r_name(type)
        type_name = TypeName.new get_d10r_class_name(type), get_d10r_module_path(type), get_d10r_file_name(type), get_d10r_file_path(type)
        type_name.parent = make_parents get_d10r_module_path(type)
        type_name
      end

      # @param [WsdlMapper::Dom::Property] property
      # @return [PropertyName]
      def get_property_name(property)
        PropertyName.new get_accessor_name(property.name.name), get_var_name(property.name.name)
      end

      # @param [WsdlMapper::Dom::Attribute] attribute
      # @return [PropertyName]
      def get_attribute_name(attribute)
        PropertyName.new get_accessor_name(attribute.name.name), get_var_name(attribute.name.name)
      end

      # @param [WsdlMapper::Dom::SimpleType] _type
      # @param [WsdlMapper::Dom::EnumerationValue] enum_value
      # @return [EnumerationValueName]
      def get_enumeration_value_name(_type, enum_value)
        EnumerationValueName.new get_constant_name(enum_value.value), get_key_name(enum_value.value)
      end

      # @param [WsdlMapper::Dom::ComplexType, WsdlMapper::Dom::SimpleType] _type
      # @return [PropertyName]
      def get_content_name(_type)
        @content_name ||= PropertyName.new get_accessor_name(@content_attribute_name), get_var_name(@content_attribute_name)
      end

      # @param [WsdlMapper::Dom::Property, WsdlMapper::Dom::Element] element
      # @return [InlineType]
      def get_inline_type(element)
        name = element.name.name + 'InlineType'
        InlineType.new WsdlMapper::Dom::Name.get(element.name.ns, name)
      end

      # @param [WsdlMapper::Dom::ComplexType] _type
      # @return [String]
      def get_soap_array_item_name(_type)
        @soap_array_item_name
      end

      protected
      def get_class_name(type)
        camelize type.name.name
      end

      def get_class_file_name(type)
        underscore(type.name.name) + '.rb'
      end

      def get_class_module_path(type)
        @module_path
      end
      alias_method :get_s8r_module_path, :get_class_module_path
      alias_method :get_d10r_module_path, :get_class_module_path

      def get_class_file_path(type)
        get_file_path get_class_module_path type
      end
      alias_method :get_s8r_file_path, :get_class_file_path
      alias_method :get_d10r_file_path, :get_class_file_path

      def get_d10r_file_name(type)
        underscore(type.name.name) + '_deserializer.rb'
      end

      def get_d10r_class_name(type)
        camelize type.name.name + 'Deserializer'
      end

      def get_s8r_file_name(type)
        underscore(type.name.name) + '_serializer.rb'
      end

      def get_s8r_class_name(type)
        camelize type.name.name + 'Serializer'
      end

      def get_support_class_name(name)
        camelize name
      end

      def get_support_module_path(_name)
        @module_path
      end

      def get_support_file_path(name)
        get_file_path get_support_module_path name
      end

      def get_support_file_name(name)
        get_file_name name
      end
    end
  end
end
