require "bunny"

module Emque
  module Producing
    module Publisher
      class RabbitMq < Emque::Producing::Publisher::Base
        def initialize
          @conn = Bunny.new Emque::Producing.configuration.rabbitmq_options[:url]
          @conn.start
        end

        def publish(topic, message_type, message, key = nil)
          ch = @conn.create_channel
          begin
            exchange = ch.fanout(topic, :durable => true, :auto_delete => false)

            # Assumes all messages are mandatory in order to let callers know if
            # the message was not sent. Uses publisher confirms to wait.
            ch.confirm_select
            sent = true
            exchange.on_return do |return_info, properties, content|
              sent = false
            end

            exchange.publish(
              message,
              :mandatory => true,
              :persistent => true,
              :type => message_type,
              :app_id => Emque::Producing.configuration.app_name,
              :content_type => "application/json")

            success = ch.wait_for_confirms
            unless success
              Emque::Producing.logger.warn("RabbitMQ Publisher: message was nacked")
              ch.nacked_set.each do |n|
                Emque::Producing.logger.warn("message id: #{n}")
              end
            end

            return sent
          ensure
            ch.close unless ch.nil? || ch.closed?
          end
        end
      end
    end
  end
end
