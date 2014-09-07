module Emque
  module Producer
    class << self
      attr_accessor :poseidon_producer
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
        self.class.poseidon_producer
      end
    end

    def publish(topic, message, key = nil)
      begin
        msg = Poseidon::MessageToSend.new(topic, message, key)
        publisher.send_messages([msg])
      rescue => e
        handle_error(e)
      end
    end

    def handle_error(e)
      Emque::Producer.configuration.error_handlers.each do |handler|
        begin
          handler.call(e, nil)
        rescue => ex
          logger.error "Producer error hander raised an error"
          logger.error ex
          logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
        end
      end
    end
  end
end
