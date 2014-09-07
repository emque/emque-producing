module Emque
  module Producer
    class Publisher
      def publish(topic, message, key = nil)
        begin
          msg = Poseidon::MessageToSend.new(topic, message, key)
          Emque::Producer.poseidon_producer.send_messages([msg])
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
end
