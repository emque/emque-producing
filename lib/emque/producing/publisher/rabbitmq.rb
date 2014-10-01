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
          begin
            channel = @conn.create_channel
            x = channel.fanout(topic, :durable => true, :auto_delete => false)
            x.publish(message,
                      :persistent => true,
                      :type => message_type,
                      :app_id => Emque::Producing.configuration.app_name,
                      :content_type => "application/json")
            channel.close
          rescue => e
            handle_error(e)
          end
        end
      end
    end
  end
end
