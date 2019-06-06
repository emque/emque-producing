module Emque
  module Producing
    class << self
      attr_accessor :publisher
      attr_writer :configuration

      def message(opts = {})
        with_changeset = opts.fetch(:with_changeset) { false }

        Module.new do
          define_singleton_method(:included) do |descendant|
            if with_changeset
              descendant.send(:include, ::Emque::Producing::MessageWithChangeset)
            else
              descendant.send(:include, ::Emque::Producing::Message)
            end
          end
        end
      end

      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Emque::Producing::Configuration.new
      end

      def hostname
        return @hostname unless @hostname.nil?
        @hostname = Socket.gethostname
        @hostname
      end

      def publisher
        return @publisher unless @publisher.nil?

        if (configuration.publishing_adapter == :rabbitmq)
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
