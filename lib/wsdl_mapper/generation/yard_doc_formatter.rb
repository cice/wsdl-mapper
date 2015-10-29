module WsdlMapper
  module Generation
    class YardDocFormatter
      def initialize formatter
        @formatter = formatter
        @i = 0
      end

      def line line
        buf = "# "
        buf << "  " * @i
        buf << strip(line)
        @formatter.statement buf
        self
      end

      def inc_indent
        @i += 1
        self
      end

      def dec_indent
        @i -= 1
        self
      end

      def class_doc type
        if type.documentation.present?
          text type.documentation.default
          blank_line
        end
        tag :xml_name, type.name.name

        if type.name.ns
          tag :xml_namespace, type.name.ns
        end
      end

      def text text
        lines = text.strip.split("\n")

        lines.each do |l|
          line l
        end
        self
      end

      def blank_line
        @formatter.blank_comment
        self
      end

      def tag tag, text
        line "@#{tag} #{text}"
      end

      def type_tag tag, type, text = nil
        buf = "@#{tag} [#{type}]"
        buf << " #{text}" if text
        line buf
      end

      def attribute! name, type, text, &block
        tag "!attribute", name
        inc_indent
        type_tag "return", type, strip(text)
        block.call
        dec_indent
      end

      def param name, type, text = nil
        buf = "@param #{name} [#{type}]"
        buf << " #{text}" if text
        line buf
      end

      def params *params
        params.each do |p|
          param *p
        end
        blank_line
      end

      protected
      def strip text
        return "" if text.nil?
        text.gsub(/[\n\r]/, " ").gsub(/\s+/, " ").strip
      end
    end
  end
end
