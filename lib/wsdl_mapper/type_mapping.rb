require 'wsdl_mapper/type_mapping/mapping_set'
require 'wsdl_mapper/type_mapping/base'
require 'wsdl_mapper/type_mapping/base64_binary'
require 'wsdl_mapper/type_mapping/boolean'
require 'wsdl_mapper/type_mapping/date'
require 'wsdl_mapper/type_mapping/date_parts'
require 'wsdl_mapper/type_mapping/date_time'
require 'wsdl_mapper/type_mapping/decimal'
require 'wsdl_mapper/type_mapping/duration'
require 'wsdl_mapper/type_mapping/float'
require 'wsdl_mapper/type_mapping/hex_binary'
require 'wsdl_mapper/type_mapping/integer'
require 'wsdl_mapper/type_mapping/string'
require 'wsdl_mapper/type_mapping/time'
require 'wsdl_mapper/type_mapping/uri'

module WsdlMapper
  module TypeMapping
    DEFAULT = MappingSet.default
  end
end
