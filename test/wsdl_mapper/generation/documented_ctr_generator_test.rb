require 'test_helper'

require 'wsdl_mapper/schema/parser'
require 'wsdl_mapper/generation/context'
require 'wsdl_mapper/generation/schema_generator'
require 'wsdl_mapper/generation/documented_ctr_generator'

require 'wsdl_mapper/dom/property'

module GenerationTests
  module GeneratorTests
    class DocumentedCtrGeneratorTest < Minitest::Test
      include WsdlMapper::Generation
      include WsdlMapper::Dom

      def setup
        @tmp_path = TestHelper.get_tmp_path
      end

      def teardown
        @tmp_path.unlink
      end

      def test_simple_class_generation
        schema = TestHelper.parse_schema 'basic_note_type_with_property_and_attribute_documentation.xsd'
        context = Context.new @tmp_path.to_s
        generator = SchemaGenerator.new context, ctr_generator_factory: DocumentedCtrGenerator

        result = generator.generate schema

        expected_file = @tmp_path.join("note_type.rb")

        generated_class = File.read expected_file
        assert_equal <<RUBY, generated_class
class NoteType
  attr_accessor :to
  attr_accessor :from
  attr_accessor :heading
  attr_accessor :body

  attr_accessor :uuid

  # This is the autogenerated default constructor.
  #
  # @param to [String] the recipient of this note
  # @param from [String] the sender of this note
  # @param heading [String]
  # @param body [String]
  #
  # @param uuid [String] a unique identifier
  #
  def initialize(to: nil, from: nil, heading: nil, body: nil)
    @to = to
    @from = from
    @heading = heading
    @body = body
  end
end
RUBY
      end
    end
  end
end
