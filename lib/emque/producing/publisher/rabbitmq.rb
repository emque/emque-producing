require "bunny"
require "thread"

module Emque
  module Producing
    module Publisher
      class RabbitMq < Emque::Producing::Publisher::Base
        Emque::Producing.configure do |c|
          c.ignored_exceptions = c.ignored_exceptions + [Bunny::Exception, Timeout::Error]
        end

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

        def publish(topic, message_type, message, key = nil)
          ch = CHANNEL_POOL.pop
          ch.open if ch.closed?
          begin
            exchange = ch.fanout(topic, :durable => true, :auto_delete => false)

            # Assumes all messages are mandatory in order to let callers know if
            # the message was not sent. Uses publisher confirms to wait.
            ch.confirm_select
            sent = true

            exchange.on_return do |return_info, properties, content|
              Emque::Producing.logger.warn("App [#{properties[:app_id]}] message was returned from exchange [#{return_info[:exchange]}]")
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
            CHANNEL_POOL << ch unless ch.nil?
          end
        end
      end
    end
  end
end
