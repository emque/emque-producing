module Emque
  module Producing
    class Configuration
      attr_accessor :app_name
      attr_accessor :publishing_adapter
      attr_accessor :kafka_options
      attr_accessor :rabbitmq_options
      attr_accessor :error_handlers
      attr_accessor :log_publish_message
      attr_accessor :publish_messages

      def initialize
        @app_name = ""
        @publishing_adapter = :rabbitmq
        @error_handlers = []
        @log_publish_message = false
        @publish_messages = true
        @kafka_options = { :seed_brokers => ["localhost:9092"],
                           :producer_options => {} }
        @rabbitmq_options = { :url => "amqp://guest:guest@localhost:5672" }
      end
    end
  end
end
