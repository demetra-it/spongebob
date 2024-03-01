# frozen_string_literal: true

module Spongebob
  # Error raised when a block is required but not provided
  class BlockRequiredError < ArgumentError
    def initialize(message = "Block is required")
      super(message)
    end
  end

  # Error raised when a configuration error is detected
  class ConfigurationError < StandardError
  end
end
