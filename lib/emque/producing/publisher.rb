module Emque
  module Producing
    class Publisher
      def publish(topic, message, key = nil)
        begin
          msg = Poseidon::MessageToSend.new(topic, message, key)
          Emque::Producing.poseidon_producer.send_messages([msg])
        rescue => e
          handle_error(e)
        end
      end

      def handle_error(e)
        Emque::Producing.configuration.error_handlers.each do |handler|
          begin
            handler.call(e, nil)
          rescue => ex
            Emque::Producing.logger.error "Producer error hander raised an error"
            Emque::Producing.logger.error ex
            Emque::Producing.logger.error Array(ex.backtrace).join("\n")
          end
        end
      end
    end
  end
end
