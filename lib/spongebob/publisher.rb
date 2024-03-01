# frozen_string_literal: true

module Spongebob
  # Implements a simple Publisher class which wraps Kafka producer and provides a simple interface to
  # publish messages to Kafka.
  class Publisher
    class << self
      def instance
        @instance ||= new
      end

      def configure(&block)
        raise BlockRequiredError unless block_given?

        instance.configure(&block)
      end

      def publish(event_type: nil, payload: nil, partition_key: nil)
        instance.publish(event_type: event_type, payload: payload, partition_key: partition_key)
      end
    end

    def initialize
      @producer = config.kafka_client.async_producer(
        delivery_interval: config.producer_delivery_interval
      )
    end

    # Returns Publisher instance's configuration
    def config
      @config ||= Spongebob.config
    end

    # Configure the Publisher instance (leave Spongebob.config untouched)
    def configure
      raise BlockRequiredError unless block_given?

      @config = Spongebob.clone_configs(config)

      yield @config
    end

    # Publish an event of specific type (ex. 'account.create') and a payload
    # which contains the data of the event to send to Nifi.
    def publish(event_type: nil, payload: nil, partition_key: nil)
      raise ArgumentError, "event_type is required" if event_type.nil?

      message = wrap_message(event_type, payload)
      @producer.produce(message.to_json, topic: config.topic, key: event_type, partition_key: partition_key)
    end

    # Deliver all messages in the producer buffer
    def deliver_messages
      @producer.deliver_messages
    end

    protected

    # Add some metadata to the message payload.
    def wrap_message(event_type, payload)
      payload = JSON.parse(payload) if payload.is_a?(String)

      {
        service: config.app_name,
        event_type: event_type,
        payload: payload
      }
    end
  end
end
