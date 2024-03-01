# frozen_string_literal: true

require "configatron"
require "logger"
require "oj"

require_relative "spongebob/version"
require_relative "spongebob/errors"
require_relative "spongebob/message"
require_relative "spongebob/listener"
require_relative "spongebob/event_processor"
require_relative "spongebob/publisher"

# Spongebob module provides the feature for Spongebob configuration and access to a Logger instance.
module Spongebob
  class Error < StandardError; end

  class << self
    def config
      @config ||= generate_config
    end

    def configure
      raise ArgumentError, "Block is required" unless block_given?

      yield config
    end

    def clone_configs(from_config)
      config = Configatron::RootStore.new
      config.configure_from_hash(from_config.to_h)

      config
    end

    def logger
      return @logger if @logger

      @logger = Rails.logger.clone if defined?(Rails)
      @logger ||= Fleck.logger.clone if defined?(Fleck)
      @logger ||= Logger.new(File.exist?("/proc/1/fd/1") ? "/proc/1/fd/1" : $stdout)
      @logger.progname = name

      @logger
    end

    private

    def generate_config
      config = Configatron::RootStore.new
      config.kafka_client = nil
      config.app_name = "MyApp"
      config.queue_topic = Configatron::Dynamic.new { "#{config.app_name}.nifi.queue" }
      config.events_topic = Configatron::Dynamic.new { "#{config.app_name}.nifi.events" }
      config.broadcast_events_topic = Configatron::Dynamic.new { "#{config.events_topic}.broadcast" }
      config.exclusive_events_topic = Configatron::Dynamic.new { "#{config.events_topic}.exclusive" }
      config.producer_delivery_interval = 1

      config
    end
  end
end
