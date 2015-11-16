require 'wsdl_mapper/naming/default_namer'
require 'wsdl_mapper/generation/result'
require 'wsdl_mapper/generation/default_formatter'
require 'wsdl_mapper/generation/type_to_generate'
require 'wsdl_mapper/generation/default_module_generator'
require 'wsdl_mapper/dom/complex_type'
require 'wsdl_mapper/dom/simple_type'

module WsdlMapper
  module S8rGeneration
    class S8rGenerator
      include WsdlMapper::Generation

      attr_reader :context

      def initialize context, namer: WsdlMapper::Naming::DefaultNamer.new, formatter_factory: DefaultFormatter, module_generator_factory: DefaultModuleGenerator
        @context = context
        @namer = namer
        @formatter_factory = formatter_factory
        @module_generator = module_generator_factory.new self
      end

      def generate schema
        result = Result.new schema

        schema.each_type do |type|
          generate_type type, result
        end

        result.module_tree.each do |module_node|
          @module_generator.generate module_node, result
        end

        result
      end

      def generate_type type, result
        name = if type.name
          @namer.get_s8r_name type
        elsif type.containing_element
          @namer.get_s8r_name @namer.get_inline_type type.containing_element
        elsif type.containing_property
          @namer.get_s8r_name @namer.get_inline_type type.containing_property
        end
        file_name = @context.path_for name
        modules = name.parents.reverse

        File.open file_name, 'w' do |io|
          f = get_formatter io
          ttg = TypeToGenerate.new type, name

          open_modules f, modules
          open_class f, ttg
          def_build_method f, ttg
          close_class f, ttg
          close_modules f, modules
        end

        result.add_type name
        result.files << file_name
      end

      def get_formatter io
        @formatter_factory.new io
      end

      protected
      def def_simple_build_method_body f, ttg
        ns = ttg.type.name.ns.inspect
        tag = tag_string_for_name ttg.type.name
        f.block "x.simple(#{ns}, #{tag})", ["x"] do
          root_type = ttg.type.root.name.name
          f.statement "x.text_builtin(obj, #{root_type.inspect})"
        end
      end

      def def_complex_build_method_body f, ttg
        f.literal_array 'attributes', collect_attributes(ttg)
        ns = ttg.type.name.ns.inspect
        tag = tag_string_for_name ttg.type.name
        # TODO: wrong! -> property name, not type name!
        f.block "x.complex(#{ns}, #{tag}, attributes)", ["x"] do
          if ttg.type.simple_content?
            write_content_statement f, ttg
          elsif ttg.type.soap_array?
            write_soap_array_statements f, ttg
          else
            write_property_statements f, ttg
          end
        end
      end

      def write_content_statement f, ttg
        content_name = @namer.get_content_name ttg.type
        type = ttg.type.base.name.name
        f.statement "x.text_builtin(obj.#{content_name.attr_name}, #{type.inspect})"
      end

      def write_property_statements f, ttg
        ttg.type.each_property do |prop|
          if prop.array?
            write_property_array_statement f, prop
          else
            write_property_statement f, prop
          end
        end
      end

      def collect_attributes ttg
        if ttg.type.soap_array?
          soap_array_attributes(ttg)
        else
          ttg.type.each_attribute.map do |attr|
            name = attr.name
            attr_name = @namer.get_attribute_name(attr).attr_name
            type = attr.type.root.name.name

            %<[#{name.ns.inspect}, #{name.name.inspect}, obj.#{attr_name}, #{type.inspect}]>
          end
        end
      end

      def write_soap_array_statements f, ttg
        s8r_name = @namer.get_s8r_name ttg.type.soap_array_type
        f.block 'obj.each', ['itm'] do
          f.statement "x.get(#{s8r_name.require_path.inspect}).build(x, itm)"
        end
      end

      def soap_array_attributes ttg
        # Use String#inspect to get the proper escaping, but cut off the last quotemark and append the array length
        name = ttg.type.soap_array_type_name.name.inspect[0..-2] + "[\#{obj.length}]\""
        [
          %<[x.soap_enc, "arrayType", #{name}, "string"]>
        ]
      end

      def write_property_array_statement f, prop
        name = "obj.#{@namer.get_property_name(prop).attr_name}.each"
        f.block name, ["itm"] do
          case prop.type
          when ::WsdlMapper::Dom::BuiltinType
            write_builtin_property_statement f, prop, "itm"
          when ::WsdlMapper::Dom::ComplexType
            write_complex_property_statement f, prop, "itm"
          when ::WsdlMapper::Dom::SimpleType
            write_simple_property_statement f, prop, "itm"
          end
        end
      end

      def write_property_statement f, prop
        name = "obj.#{@namer.get_property_name(prop).attr_name}"
        case prop.type
        when ::WsdlMapper::Dom::BuiltinType
          write_builtin_property_statement f, prop, name
        when ::WsdlMapper::Dom::ComplexType
          write_complex_property_statement f, prop, name
        when ::WsdlMapper::Dom::SimpleType
          write_simple_property_statement f, prop, name
        end
      end

      def write_simple_property_statement f, prop, name
        s8r_name = get_s8r_name(prop)
        f.statement "x.get(#{s8r_name.require_path.inspect}).build(x, #{name})"
      end

      def write_complex_property_statement f, prop, name
        s8r_name = get_s8r_name(prop)
        f.statement "x.get(#{s8r_name.require_path.inspect}).build(x, #{name})"
      end

      def get_s8r_name prop
        if prop.type.name
          @namer.get_s8r_name prop.type
        else
          @namer.get_s8r_name @namer.get_inline_type prop
        end
      end

      def write_builtin_property_statement f, prop, name
        tag = tag_string_for_name prop.name
        ns = prop.name.ns.inspect
        type = prop.type_name.name.inspect
        f.statement "x.value_builtin(#{ns}, #{tag}, #{name}, #{type})"
      end

      def def_build_method f, ttg
        f.begin_def 'build', [:x, :obj]
        case ttg.type
        when ::WsdlMapper::Dom::ComplexType
          def_complex_build_method_body f, ttg
        when ::WsdlMapper::Dom::SimpleType
          def_simple_build_method_body f, ttg
        end
        f.end
      end

      def close_class f, ttg
        f.end
      end

      def open_class f, ttg
        f.begin_class ttg.name.class_name
      end

      def tag_for_name name
        name.name
      end

      def tag_string_for_name name
        tag_for_name(name).inspect
      end

      def close_modules f, modules
        modules.each { f.end }
      end

      def open_modules f, modules
        modules.each do |mod|
          f.begin_module mod.module_name
        end
      end
    end
  end
end
