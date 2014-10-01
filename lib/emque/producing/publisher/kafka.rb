require "poseidon"

module Emque
  module Producing
    module Publisher
      class Kafka < Emque::Producing::Publisher::Base
        def initialize
          @producer = Poseidon::Producer.new(
            Emque::Producing.configuration.kafka_options[:seed_brokers],
            "producer_#{host_name}_#{Process.pid}",
            Emque::Producing.configuration.kafka_options[:producer_options])
        end

        def publish(topic, message_type, message, key = nil)
          begin
            msg = Poseidon::MessageToSend.new(topic, message, key)
            @producer.send_messages([msg])
          rescue => e
            handle_error(e)
          end
        end
      end
    end
  end
end
