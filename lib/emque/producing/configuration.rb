module Emque
  module Producing
    class Configuration
      attr_accessor :app_name
      attr_accessor :error_handlers
      attr_accessor :log_publish_message
      attr_accessor :kafka_seed_brokers
      attr_accessor :kafka_producer_options

      def initialize
        @app_name = ""
        @error_handlers = []
        @log_publish_message = false
        @kafka_seed_brokers = ["localhost:9092"]
        @kafka_producer_options = {}
      end
    end
  end
end
