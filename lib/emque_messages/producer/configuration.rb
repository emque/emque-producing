module Emque
  module Producer
    class Configuration
      attr_accessor :app_name
      attr_accessor :seed_brokers
      attr_accessor :error_handlers

      def initialize
        @app_name = ""
        @seed_brokers = ["localhost:9092"]
        @error_handlers = []
      end
    end
  end
end
