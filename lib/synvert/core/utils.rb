# frozen_string_literal: true

require 'uri'

module Synvert::Core
  class Utils
    class << self
      def eval_snippet(snippet_name)
        if is_valid_url?(snippet_name)
          uri = URI.parse(format_url(snippet_name))
          eval(uri.open.read)
        elsif is_valid_file?(snippet_name)
          eval(File.read(snippet_name))
        else
          eval(File.read(File.join(default_snippets_home, 'lib', "#{snippet_name}.rb")))
        end
      end

      private

      def is_valid_url?(url)
        /^http/.match?(url)
      end

      def is_valid_file?(path)
        File.exist?(path)
      end

      def default_snippets_home
        ENV['SYNVERT_SNIPPETS_HOME'] || File.join(ENV['HOME'], '.synvert-ruby')
      end

      def format_url(url)
        convert_to_github_raw_url(url)
      end

      def convert_to_github_raw_url(url)
        return url unless url.include?('//github.com/')

        url.sub('//github.com/', '//raw.githubusercontent.com/').sub('/blob/', '/')
      end
    end
  end
end