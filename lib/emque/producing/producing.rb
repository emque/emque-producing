module Emque
  module Producing
    class << self
      attr_accessor :publisher
      attr_writer :configuration

      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Emque::Producing::Configuration.new
      end

      def host_name
        Socket.gethostbyname(Socket.gethostname).first
      end

      def publisher
        return @publisher unless @publisher.nil?

        if (configuration.publishing_adapter == :kafka)
          require "emque/producing/publisher/kafka"
          @publisher = Emque::Producing::Publisher::Kafka.new
        elsif (configuration.publishing_adapter == :rabbitmq)
          require "emque/producing/publisher/rabbitmq"
          @publisher = Emque::Producing::Publisher::RabbitMq.new
        else
          raise "No publisher configured"
        end
        @publisher
      end

      def logger
        Emque::Producing::Logging.logger
      end

      def logger=(log)
        Emque::Producing::Logging.logger = log
      end
    end
  end
end
