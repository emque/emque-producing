module Emque
  module Messages
    class GenericMessage
      include Emque::Messages::Base

      attr_accessor :data

      def initialize(data)
        self.data = HashWithIndifferentAccess.new(data)
        data.deep_symbolize_keys!
      end

      def metadata
        data.try(:[], :metadata)
      end

      def type
        metadata.try(:[], :type)
      end

      def partition_key
        metadata.try(:[], :partition_key)
      end

      def uuid
        metadata.try(:[], :uuid)
      end

      def retry_count
        metadata.try(:[], :retry_count) || 0
      end

      def retry!(reason, backtrace,  topic)
        if retry_count < 3
          publisher = Producer::Config.publisher
          publisher.publish("retry", to_json(reason, backtrace, topic), partition_key)
        else
          publisher = Producer::Config.publisher
          logger.info "Worker moving message to failure queue... #{logging_info(reason, backtrace)}"
          publisher.publish("failure", to_json(reason, backtrace, topic), partition_key)
        end
      end

      def to_json(reason, backtrace, topic)
        data[:metadata] ||= {}
        metadata[:retry_count] = retry_count + 1
        metadata[:reason] = reason.to_s
        metadata[:retry_topic] = topic
        metadata[:backtrace] = backtrace

        data.to_json
      end

      private

      def logger
        Emque::Application.internal_logger
      end

      def logging_info(reason, backtrace)
        "uuid: #{uuid}, message_type: #{type}, reason: #{reason}, backtrace: #{backtrace}"
      end
    end
  end
end
