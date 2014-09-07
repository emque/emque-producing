module Emque
  module Producer
    class << self
      attr_accessor :poseidon_producer
      attr_accessor :publisher
      attr_writer :configuration

      def configure
        yield(configuration)
        self.poseidon_producer ||= Poseidon::Producer.new(configuration.seed_brokers,
          "producer_#{host_name}_#{Process.pid}")
      end

      def configuration
        @configuration ||= Emque::Producer::Configuration.new
      end

      def host_name
        Socket.gethostbyname(Socket.gethostname).first
      end

      def publisher
        @publisher ||= Emque::Producer::Publisher.new
      end
    end
  end
end
