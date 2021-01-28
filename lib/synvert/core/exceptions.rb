# frozen_string_literal: true

module Synvert::Core
  # Rewriter not found exception.
  class RewriterNotFound < RuntimeError; end

  # Gemfile.lock not found exception.
  class GemfileLockNotFound < RuntimeError; end

  # Method not supported exception.
  class MethodNotSupported < RuntimeError; end
end
