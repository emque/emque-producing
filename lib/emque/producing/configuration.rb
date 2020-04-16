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
      attr_accessor :ignored_exceptions
      attr_reader :middleware

      def initialize
        @app_name = ""
        @publishers = {}
        @error_handlers = []
        @log_publish_message = false
        @publish_messages = true
        @ignored_exceptions = [Emque::Producing::Message::MessagesNotSentError]
        @middleware = []
      end

      def publisher(adapter, *args)
        if adapter == :rabbitmq
          require "emque/producing/publisher/rabbitmq"
          publishing_adapter = Emque::Producing::Publisher::RabbitMq.new(
            url: args.first.fetch(:url)
          )
        elsif adapter == :google_cloud_pubsub
          require "emque/producing/publisher/google_cloud_pubsub"
          publishing_adapter = Emque::Producing::Publisher::GoogleCloudPubsub.new(
            project_id: args.first.fetch(:project_id),
            credentials: args.first.fetch(:credentials)
          )
        else
          raise "publisher not available"
        end

        self.publishers[:adapter] = publishing_adapter
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
