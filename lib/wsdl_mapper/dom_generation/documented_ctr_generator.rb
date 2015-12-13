require 'wsdl_mapper/dom_generation/default_ctr_generator'
require 'wsdl_mapper/generation/yard_doc_formatter'

module WsdlMapper
  module DomGeneration
    class DocumentedCtrGenerator < DefaultCtrGenerator
      def generate(ttg, f, result)
        yard = WsdlMapper::Generation::YardDocFormatter.new f

        props = ttg.type.each_property.to_a
        attrs = ttg.type.each_attribute.to_a
        base_props = get_base_props(ttg.type).to_a
        base_attrs = get_base_attrs(ttg.type).to_a
        props = (props + base_props).uniq &:name
        attrs = (attrs + base_attrs).uniq &:name

        yard.text 'This is the autogenerated default constructor.'
        yard.blank_line
        prop_params = props.map do |prop|
          name = @generator.namer.get_property_name(prop).attr_name
          type = if prop.type.name == WsdlMapper::Dom::BuiltinType[:boolean].name
            'true, false'
          else
            @generator.get_ruby_type_name prop.type
          end
          type ||= 'Object'

          if prop.array?
            type = "Array<#{type}>"
          end

          [name, type, prop.documentation.default]
        end

        attr_params = attrs.map do |attr|
          name = @generator.namer.get_attribute_name(attr).attr_name
          type = @generator.get_ruby_type_name attr.type
          [name, type, attr.documentation.default]
        end

        yard.params *prop_params
        yard.params *attr_params

        super
      end

      def generate_wrapping(ttg, f, result, var_name, par_name)
        f.in_def 'initialize', par_name do
          f.assignment var_name, par_name
        end
      end
    end
  end
end
