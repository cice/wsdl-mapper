require 'wsdl_mapper/deserializers/deserializer'

module WsdlMapper
  module Deserializers
    class LazyLoadingDeserializer < Deserializer
      def initialize(element_directory,
          type_mapping: WsdlMapper::TypeMapping::DEFAULT,
          qualified_elements: false,
          qualified_attributes: false,
          skip_unknown_elements: false)
        super(type_mapping: type_mapping,
            qualified_elements: qualified_elements,
            qualified_attributes: qualified_attributes,
            skip_unknown_elements: skip_unknown_elements
        )
        @element_directory = element_directory
        reload
      end

      def get_element_type(element_name)
        if @element_directory.load element_name
          reload
        end
        super
      end

      protected
      def reload
        @element_type_mappings.clear
        @element_directory.each_element do |(elm_name, item)|
          @element_mappings[elm_name] = item.type_name
        end
        @element_directory.each_type do |(type_name, class_mapping)|
          @type_mappings[type_name] = class_mapping
        end
      end
    end
  end
end
