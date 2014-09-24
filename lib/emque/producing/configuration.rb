module Emque
  module Producing
    class Configuration
      attr_accessor :app_name
      attr_accessor :seed_brokers
      attr_accessor :error_handlers
      attr_accessor :log_publish_message

      def initialize
        @app_name = ""
        @seed_brokers = ["localhost:9092"]
        @error_handlers = []
        @log_publish_message = false
      end
    end
  end
end
