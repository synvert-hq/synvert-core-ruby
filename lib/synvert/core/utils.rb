# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'open-uri'

module Synvert::Core
  class Utils
    class << self
      def eval_snippet(snippet_name)
        eval(load_snippet(snippet_name))
      end

      def load_snippet(snippet_name)
        if is_valid_url?(snippet_name)
          uri = URI.parse(format_url(snippet_name))
          return uri.open.read if remote_snippet_exists?(uri)
          raise SnippetNotFoundError.new("#{snippet_name} nout found")
        elsif is_valid_file?(snippet_name)
          return File.read(snippet_name)
        else
          snippet_path = snippet_expand_path(snippet_name)
          return File.read(snippet_path) if File.exist?(snippet_path)
          snippet_uri = URI.parse(format_url(remote_snippet_url(snippet_name)))
          return snippet_uri.open.read if remote_snippet_exists?(snippet_uri)
          raise SnippetNotFoundError.new("#{snippet_name} nout found")
        end
      end

      private

      def is_valid_url?(url)
        /^http/.match?(url)
      end

      def is_valid_file?(path)
        File.exist?(path)
      end

      def remote_snippet_exists?(uri)
        req = Net::HTTP.new(uri.host, uri.port)
        req.use_ssl = uri.scheme == 'https'
        res = req.request_head(uri.path)
        res.code == "200"
      end

      def snippet_expand_path(snippet_name)
        File.join(default_snippets_home(), 'lib', "#{snippet_name}.rb")
      end

      def default_snippets_home
        ENV['SYNVERT_SNIPPETS_HOME'] || File.join(ENV['HOME'], '.synvert-ruby')
      end

      def remote_snippet_url(snippet_name)
        "https://github.com/xinminlabs/synvert-snippets-ruby/blob/main/lib/#{snippet_name}.rb"
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