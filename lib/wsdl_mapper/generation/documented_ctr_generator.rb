require 'wsdl_mapper/generation/documented_ctr_generator'
require 'wsdl_mapper/generation/yard_doc_formatter'

module WsdlMapper
  module Generation
    class DocumentedCtrGenerator < DefaultCtrGenerator
      def generate ttg, f, result
        yard = YardDocFormatter.new f

        props = ttg.type.each_property
        attrs = ttg.type.each_attribute

        yard.text "This is the autogenerated default constructor."
        yard.blank_line
        prop_params = props.map do |prop|
          name = @generator.namer.get_property_name(prop).attr_name
          type = @generator.get_ruby_type_name prop.type
          [name, type, prop.documentation.default]
        end

        attr_params = attrs.map do |attr|
          name = @generator.namer.get_attribute_name(attr).attr_name
          type = @generator.get_ruby_type_name attr.type
          [name, type, attr.documentation.default]
        end

        yard.params *prop_params
        yard.params *attr_params

        f.begin_def 'initialize', get_prop_kw_args(props)
        f.assignment *get_prop_assigns(props)
        f.end
      end

      def generate_wrapping ttg, f, result, var_name, par_name
        f.begin_def "initialize", [par_name]
        f.assignment [var_name, par_name]
        f.end
      end
    end
  end
end