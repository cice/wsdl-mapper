require 'thor'

require 'wsdl_mapper/dom_generation/facade'

module WsdlMapper
  module Cli
    class Cli < Thor
      desc "generate <xsd_file>", "Generates classes for the schema in <xsd_file>"
      option :out
      option :module
      option :docs, type: :boolean
      def generate xsd_file
        file_name = File.basename xsd_file, ".xsd"
        out = options[:out] || File.join(FileUtils.pwd, file_name)
        module_path = options[:module] ? options[:module].split("::").compact : []

        generator = WsdlMapper::DomGeneration::Facade.new file: xsd_file, out: out, module_path: module_path, docs: options[:docs]

        FileUtils.rmtree out
        generator.generate
      end
    end
  end
end
