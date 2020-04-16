require "bunny"
require "thread"

module Emque
  module Producing
    module Publisher
      class RabbitMq < Emque::Producing::Publisher::Base
        attr_accessor :connection
        attr_accessor :connection
        attr_accessor :channel_pool
        attr_accessor :confirms_channel_pool

        Emque::Producing.configure do |c|
          c.ignored_exceptions = c.ignored_exceptions + [Bunny::Exception, Timeout::Error]
        end

        def initialize(url:)
          self.connection = Bunny.new(url).tap { |conn|
            conn.start
          }
          self.channel_pool = Queue.new.tap { |queue|
            queue << connection.create_channel
          }
          self.confirms_channel_pool = Queue.new.tap { |queue|
            queue << connection.create_channel
          }
        end

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
              confirms_channel_pool << ch unless ch.nil?
            else
              channel_pool << ch unless ch.nil?
            end
          end
        end

        def get_channel(raise_on_failure)
          begin
            if raise_on_failure
              ch = confirms_channel_pool.pop(true)
            else
              ch = channel_pool.pop(true)
            end
          rescue ThreadError
            ch = connection.create_channel
          end
        end
      end
    end
  end
end
