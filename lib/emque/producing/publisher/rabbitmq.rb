require "bunny"
require "thread"

module Emque
  module Producing
    module Publisher
      class RabbitMq < Emque::Producing::Publisher::Base
        CONN = Bunny
          .new(Emque::Producing.configuration.rabbitmq_options[:url])
          .tap { |conn|
            conn.start
          }

        CHANNEL_POOL = Queue
          .new
          .tap { |queue|
            20.times { |i| queue << CONN.create_channel }
          }

        def publish(topic, message_type, message, raise_message_failure, key = nil)
          ch = CHANNEL_POOL.pop
          ch.open if ch.closed?
          begin
            exchange = ch.fanout(topic, :durable => true, :auto_delete => false)
            sent = true

            if raise_message_failure
              ch.confirm_select unless ch.using_publisher_confirmations?
              exchange.on_return do |return_info, properties, content|
                Emque::Producing.logger.warn("App [#{properties[:app_id]}] message was returned from exchange [#{return_info[:exchange]}]")
                sent = false
              end
            end

            exchange.publish(
              message,
              :mandatory => raise_message_failure,
              :persistent => true,
              :type => message_type,
              :app_id => Emque::Producing.configuration.app_name,
              :content_type => "application/json")

            if raise_message_failure
              success = ch.wait_for_confirms
              unless success
                Emque::Producing.logger.warn("RabbitMQ Publisher: message was nacked")
                ch.nacked_set.each do |n|
                  Emque::Producing.logger.warn("message id: #{n}")
                end
              end
            end

            return sent
          ensure
            CHANNEL_POOL << ch unless ch.nil?
          end
        end
      end
    end
  end
end
