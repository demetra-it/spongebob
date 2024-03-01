# frozen_string_literal: true

module Spongebob
  # Implements a simple Message class which wraps Kafka message and provides a simple interface to
  # access message data.
  class Message
    attr_reader :topic, :key, :event_type, :payload

    def initialize(message)
      @topic = message.topic
      @key = message.key
      @value = message.value

      extract_data!
    end

    def inspect
      [
        "#<Nifi::Message:#{object_id}",
        "topic=#{topic.inspect}",
        "key=#{key.inspect}",
        "event_type=#{event_type.inspect}",
        "payload=#{payload.inspect}>"
      ].join(" ")
    end

    def to_s
      inspect
    end

    private

    def extract_data!
      @data = Oj.load(@value).to_hash_with_indifferent_access
      @event_type = @data[:event_type]
      @payload = @data[:payload]
    end
  end
end
