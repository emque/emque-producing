module Emque
  module Producing
    class << self
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

      def publishers
        @publishers ||= get_publishers
      end

      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Emque::Producing::Configuration.new
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def get_publishers
        publishers = {}

        case configuration.publishing_adapter
          when Symbol
            if configuration.publishing_adapter == :rabbitmq
              require "emque/producing/publisher/rabbitmq"
              publishers[:rabbitmq] = Emque::Producing::Publisher::RabbitMq.new
            elsif configuration.publishing_adapter == :google_cloud_pubsub
              require "emque/producing/publisher/google_cloud_pubsub"
              publishers[:google_cloud_pubsub] = Emque::Producing::Publisher::GoogleCloudPubsub.new
            else
              raise "No publisher configured"
            end
          when Array
            if configuration.publishing_adapter.empty?
              raise "No publisher configured"
            end
            if configuration.publishing_adapter.include?(:rabbitmq)
              require "emque/producing/publisher/rabbitmq"
              publishers[:rabbitmq] = Emque::Producing::Publisher::RabbitMq.new
            end
            if configuration.publishing_adapter.include?(:google_cloud_pubsub)
              require "emque/producing/publisher/google_cloud_pubsub"
              publishers[:google_cloud_pubsub] = Emque::Producing::Publisher::GoogleCloudPubsub.new
            end
          else
            raise "No publisher configured"
        end

        publishers
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
