# frozen_string_literal: true

require 'erubis'

module Synvert::Core
  module Engine
    ERUBY_EXPR_SPLITTER = ';  ;'
    ERUBY_STMT_SPLITTER = ';   ;'

    class ERB
      class << self
        # convert erb to ruby code.
        #
        # @param source [String] erb source code.
        # @return [String] ruby source code.
        def encode(source)
          Erubis.new(source.gsub('-%>', '%>'), escape: false, trim: false).src
        end

        # convert ruby code to erb.
        #
        # @param source [String] ruby source code.
        # @return [String] erb source code.
        def decode(source)
          source = decode_ruby_stmt(source)
          source = decode_ruby_output(source)
          source = decode_html_output(source)
          source = remove_erubis_buf(source)
        end

        private

        def decode_ruby_stmt(source)
          source.gsub(/#{ERUBY_STMT_SPLITTER}(.+?)#{ERUBY_STMT_SPLITTER}/mo) { "<%#{Regexp.last_match(1)}%>" }
        end

        def decode_ruby_output(source)
          source.gsub(/@output_buffer.append=\((.+?)\);#{ERUBY_EXPR_SPLITTER}/mo) { "<%=#{Regexp.last_match(1)}%>" }.gsub(
            /@output_buffer.append= (.+?)\s+(do|\{)(\s*\|[^|]*\|)?\s*#{ERUBY_EXPR_SPLITTER}/mo
          ) { |m| "<%=#{m.sub('@output_buffer.append= ', '').sub(ERUBY_EXPR_SPLITTER, '')}%>" }
        end

        def decode_html_output(source)
          source.gsub(/@output_buffer.safe_append='(.+?)'.freeze;/m) { reverse_escape_text(Regexp.last_match(1)) }.gsub(
            /@output_buffer.safe_append=\((.+?)\);#{ERUBY_EXPR_SPLITTER}/mo
          ) { reverse_escape_text(Regexp.last_match(1)) }.gsub(
            /@output_buffer.safe_append=(.+?)\s+(do|\{)(\s*\|[^|]*\|)?\s*#{ERUBY_EXPR_SPLITTER}/mo
          ) { reverse_escape_text(Regexp.last_match(1)) }
        end

        def remove_erubis_buf(source)
          source
            .sub('@output_buffer = output_buffer || ActionView::OutputBuffer.new;', '')
            .sub('@output_buffer.to_s', '')
        end

        def reverse_escape_text(source)
          source.gsub("\\\\", "\\").gsub("\\'", "'")
        end
      end
    end

    # borrowed from rails
    class Erubis < ::Erubis::Eruby
      def add_preamble(src)
        @newline_pending = 0
        src << '@output_buffer = output_buffer || ActionView::OutputBuffer.new;'
      end

      def add_text(src, text)
        return if text.empty?

        if text == "\n"
          @newline_pending += 1
        else
          src << "@output_buffer.safe_append='"
          src << "\n" * @newline_pending if @newline_pending > 0
          src << escape_text(text)
          src << "'.freeze;"

          @newline_pending = 0
        end
      end

      # Erubis toggles <%= and <%== behavior when escaping is enabled.
      # We override to always treat <%== as escaped.
      def add_expr(src, code, indicator)
        case indicator
        when '=='
          add_expr_escaped(src, code)
        else
          super
        end
      end

      BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/

      def add_expr_literal(src, code)
        flush_newline_if_pending(src)
        if code =~ BLOCK_EXPR
          src << '@output_buffer.append= ' << code << ERUBY_EXPR_SPLITTER
        else
          src << '@output_buffer.append=(' << code << ');' << ERUBY_EXPR_SPLITTER
        end
      end

      def add_expr_escaped(src, code)
        flush_newline_if_pending(src)
        if code =~ BLOCK_EXPR
          src << '@output_buffer.safe_append= ' << code << ERUBY_EXPR_SPLITTER
        else
          src << '@output_buffer.safe_append=(' << code << ');' << ERUBY_EXPR_SPLITTER
        end
      end

      def add_stmt(src, code)
        flush_newline_if_pending(src)
        if code != "\n" && code != ''
          index =
            case code
            when /\A(\s*)\r?\n/
              Regexp.last_match(1).length
            when /\A(\s+)/
              Regexp.last_match(1).end_with?(' ') ? Regexp.last_match(1).length - 1 : Regexp.last_match(1).length
            else
              0
            end
          code.insert(index, ERUBY_STMT_SPLITTER)
          code.insert(-1, ERUBY_STMT_SPLITTER[0...-1])
        end
        super
      end

      def add_postamble(src)
        flush_newline_if_pending(src)
        src << '@output_buffer.to_s'
      end

      def flush_newline_if_pending(src)
        if @newline_pending > 0
          src << "@output_buffer.safe_append='#{"\n" * @newline_pending}'.freeze;"
          @newline_pending = 0
        end
      end
    end
  end
end
