# frozen_string_literal: true

module Spongebob
  class EventProcessor
    class << self
      attr_reader :event_type
      attr_accessor :callback

      def inherited(subclass)
        super
        register_processor(subclass)
      end

      def handle(event_name)
        logger.debug "Registering processor for event type: #{event_name}"
        Spongebob::Listener.unbind(@event_type, &callback) if @event_type
        @event_type = event_name.to_s
        Spongebob::Listener.on(@event_type, &callback)
      end

      def failure_options(retry: nil, max_attempts: nil, retry_delay: nil)
        @options ||= options
        %i[retry max_attempts retry_delay].each do |key|
          value = binding.local_variable_defined?(key) ? binding.local_variable_get(key) : nil
          @options[key] = value
        end
      end

      def options
        @options ||= { retry: false, max_attempts: 3, retry_delay: 5 }

        @options
      end

      def add_processor(processor)
        @processors ||= []
        @processors << processor
      end

      def register_processor(subclass)
        # extract event type from class name
        event_name = subclass.name.gsub("::", ".").gsub(/(.)([A-Z])/, "\1_\2").downcase.gsub(/_processor$/, "")

        subclass.callback = generate_callback_for(subclass)

        subclass.handle(event_name)
        add_processor(subclass)
      end

      def generate_callback_for(subclass)
        lambda do |message|
          subclass.logger.debug "Processing event: #{message}"
          attempts = 0
          begin
            subclass.new(message).on_event
          rescue StandardError => e
            subclass.logger.error "Error processing event: #{e.message}\n#{e.backtrace.join("\n")}"
            if subclass.options[:retry] && attempts < subclass.options[:max_attempts]
              attempts += 1
              sleep subclass.options[:retry_delay]
              retry
            else
              subclass.logger.error "Failed to process event after #{attempts} attempts"
            end
          end
        end
      end

      def logger
        return @logger if @logger

        @logger = Spongebob.logger.clone
        @logger.progname = name

        @logger
      end
    end

    attr_reader :message

    def initialize(message)
      @message = message
    end

    def on_event; end

    def logger
      @logger ||= self.class.logger.clone
    end
  end
end
