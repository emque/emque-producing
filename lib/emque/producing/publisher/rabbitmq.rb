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
          .tap { |conn| conn.start }

        CONFIRM_CHANNEL_POOL = Queue.new.tap {
          |queue| queue << CONN.create_channel
        }
        CHANNEL_POOL = Queue.new.tap { |queue| queue << CONN.create_channel }

        def publish(topic, message_type, message, raise_on_failure)
          ch = get_channel(raise_on_failure)

          ch.open if ch.closed?
          begin
            exchange = ch.fanout(topic, :durable => true, :auto_delete => false)

            ch.confirm_select if raise_on_failure
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
              :content_type => "application/json"
            )

            if raise_on_failure
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
            if raise_on_failure
              CONFIRM_CHANNEL_POOL << ch unless ch.nil?
            else
              CHANNEL_POOL << ch unless ch.nil?
            end
          end
        end

        def get_channel(raise_on_failure)
          begin
            if raise_on_failure
              ch = CONFIRM_CHANNEL_POOL.pop(true)
            else
              ch = CHANNEL_POOL.pop(true)
            end
          rescue ThreadError
            ch = CONN.create_channel
          end
        end
      end
    end
  end
end
