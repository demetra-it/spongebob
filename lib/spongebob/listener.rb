# frozen_string_literal: true

module Spongebob
  # Implements a simple Kafka consumer which
  class Listener # rubocop:disable Metrics/ClassLength
    class << self
      def instance(*args)
        @instance ||= new(*args)
      end

      def on(event_type, &block)
        instance.register_callback(event_type, &block)
      end

      def unbind(event_type, &block)
        instance.find_callbacks(event_type).delete(block)
      end

      def start!
        instance.validate_config!
        instance.start!
      end

      def logger
        return @logger if @logger

        @logger = Spongebob.logger.clone
        @logger.progname = name

        @logger
      end
    end

    def initialize
      @callbacks = {}
      @started = false
    end

    # Returns Listener instance's configuration
    def config
      @config ||= Spongebob.config
    end

    # Configure the Listener instance (leave Spongebob.config untouched)
    def configure
      raise BlockRequiredError unless block_given?

      @config = Spongebob.clone_configs(config)

      yield @config
    end

    def client
      @client ||= config.kafka_client
    end

    def exclusive_topic
      config.exclusive_events_topic
    end

    def broadcast_topic
      config.broadcast_events_topic
    end

    def register_callback(event_type, &block)
      raise BlockRequiredError unless block_given?

      @callbacks[event_type] ||= []
      @callbacks[event_type] << block
    end

    def find_callbacks(event_type)
      @callbacks[event_type] || []
    end

    def validate_config!
      raise ConfigurationError, "Kafka client is not set" unless client
      raise ConfigurationError, "App name is not set" if config.app_name.to_s.strip == ""
      raise ConfigurationError, "Exclusive events topic is not set" if exclusive_topic.to_s.strip == ""
      raise ConfigurationError, "Broadcast events topic is not set" if broadcast_topic.to_s.strip == ""
    end

    def start!
      return if @started

      Thread.new do
        @started = true
        sleep 1 # give main thread some time to setup callbacks
        init_consumers!
        init_subscriptions!
      end
    end

    protected

    # Create broadcast and exclusive consumers in order to be able to consume broadcast and exclusive messages.
    def init_consumers!
      # Use the same group_id for exclusive consumer, so that the message is received only by one service instance
      @exclusive_consumer = client.consumer(group_id: config.app_name)

      # Generate a random group_id for broadcast consumer, so that it can receive the same message on multiple service
      # instances
      @broadcast_consumer = client.consumer(group_id: SecureRandom.uuid)

      at_exit do
        @broadcast_consumer.stop
        @exclusive_consumer.stop
      end
    end

    def init_subscriptions!
      # Create topics if doesn't exist
      create_topic_if_not_exist(exclusive_topic)
      create_topic_if_not_exist(broadcast_topic)

      # We will subscribe to the topic with two consumers, one for broadcast messages and one for single messages,
      # and then use message key to filter out messages that are not meant for us.
      @exclusive_consumer.subscribe(exclusive_topic, start_from_beginning: true)
      @broadcast_consumer.subscribe(broadcast_topic, start_from_beginning: false)

      consume_broadcast_messages!
      consume_exclusive_messages!
    end

    # Start consuming messages with broadcast consumer
    def consume_broadcast_messages!
      Thread.new do
        # Start consuming messages with broadcast consumer
        @broadcast_consumer.each_message do |message|
          logger.debug "Received BROADCAST message: #{message.value})"
          process_message(message)
        end
      end
    end

    # Start consuming messages with exclusive consumer
    def consume_exclusive_messages!
      Thread.new do
        # Start consuming messages with exclusive consumer
        @exclusive_consumer.each_message do |message|
          logger.debug "Received EXCLUSIVE message: #{message.value})"
          process_message(message)
        end
      end
    end

    # Process the message and call the registered callbacks
    def process_message(message)
      nifi_message = Spongebob::Message.new(message)
      callbacks = find_callbacks(nifi_message.event_type)

      callbacks.each do |callback|
        callback.call(nifi_message)
      end
    rescue StandardError => e
      logger.error "Failed to process message: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    def create_topic_if_not_exist(topic)
      client.create_topic(topic) unless client.topics.include?(topic)
    rescue Kafka::TopicAlreadyExists
      logger.warn "Topic #{topic} already exists"
    end

    def logger
      @logger ||= self.class.logger.clone
    end
  end
end
