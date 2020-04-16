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
        @configuration.publishers
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

      def logger
        Emque::Producing::Logging.logger
      end

      def logger=(log)
        Emque::Producing::Logging.logger = log
      end
    end
  end
end
