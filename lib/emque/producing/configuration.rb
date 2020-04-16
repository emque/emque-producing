module Emque
  module Producing
    ConfigurationError = Class.new(StandardError)

    class Configuration
      attr_accessor :app_name
      attr_accessor :publishers
      attr_accessor :error_handlers
      attr_accessor :log_publish_message
      attr_accessor :publish_messages
      attr_reader :rabbitmq_options
      attr_reader :google_cloud_pubsub_options
      attr_accessor :ignored_exceptions
      attr_reader :middleware

      def initialize
        @app_name = ""
        @publishers = []
        @error_handlers = []
        @log_publish_message = false
        @publish_messages = true
        @rabbitmq_options = {
          :url => "amqp://guest:guest@localhost:5672"
        }
        @google_cloud_pubsub_options = {}
        @ignored_exceptions = [Emque::Producing::Message::MessagesNotSentError]
        @middleware = []
      end

      def use(callable)
        unless callable.respond_to?(:call) and callable.arity == 1
          raise(
            ConfigurationError,
            "#{self.class.name}#use must receive a callable object with an " +
            "arity of one."
          )
        end

        @middleware << callable
      end
    end
  end
end
