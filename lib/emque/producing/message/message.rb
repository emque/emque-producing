require "securerandom"
require "socket"

module Emque
  module Producing
    module Message
      InvalidMessageError = Class.new(StandardError)
      MessagesNotSentError = Class.new(StandardError)

      module ClassMethods
        def topic(name)
          @topic = name
        end

        def read_topic
          @topic
        end

        def message_type(name)
          @message_type = name
        end

        def middleware
          @middleware || []
        end

        def read_message_type
          @message_type
        end

        def raise_on_failure(name)
          @raise_on_failure = name
        end

        def read_raise_on_failure
          if @raise_on_failure.nil?
            true
          else
            @raise_on_failure
          end
        end

        def ignored_exceptions(*ignored_exceptions)
          @ignored_exceptions = ignored_exceptions
        end

        def read_ignored_exceptions
          (Array(@ignored_exceptions) + Emque::Producing.configuration.ignored_exceptions).uniq
        end

        def private_attribute(name, coercion=nil, opts={})
          @private_attrs ||= []
          @private_attrs << name
          attribute(name, coercion, opts)
        end

        def private_attrs
          Array(@private_attrs)
        end

        def use(callable)
          unless callable.respond_to?(:call) and callable.arity == 1
            raise(
              ConfigurationError,
              "#{self.class.name}#use must receive a callable object with an " +
              "arity of one."
            )
          end

          @middleware ||= []
          @middleware << callable
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, Virtus.value_object)
      end

      def add_metadata
        {
          :metadata =>
          {
            :host => hostname,
            :app => app_name,
            :topic => topic,
            :created_at => formatted_time,
            :uuid => uuid,
            :type => message_type,
          }
        }.merge(public_attributes)
      end

      def topic
        self.class.read_topic
      end

      def message_type
        self.class.read_message_type
      end

      def raise_on_failure?
        self.class.read_raise_on_failure
      end

      def ignored_exceptions
        self.class.read_ignored_exceptions
      end

      def valid?
        if invalid_attributes.empty? && topic && message_type
          true
        else
          false
        end
      end

      def invalid_attributes
        invalid_attrs = self.class.attribute_set.inject([]) do |attrs, attr|
          attrs << attr.name if attr.required? && self.attributes.fetch(attr.name).nil?
          attrs
        end
        Array(invalid_attrs) - self.class.private_attrs
      end

      def to_json
        data = self.add_metadata
        Oj.dump(data, :mode => :compat)
      end

      def publish(publishers=[:rabbitmq])
        log "publishing...", true
        if valid?
          log "valid...", true
          if Emque::Producing.configuration.publish_messages
            message = process_middleware(to_json)
            publishers.each do |publisher|
              sent = Emque::Producing
                .publishers
                .fetch(publisher)
                .publish(topic, message_type, message, raise_on_failure?)
              log "publisher: #{publisher} sent: #{sent}"
              raise MessagesNotSentError.new unless sent
            end
          end
        else
          log "failed...", true
          raise InvalidMessageError.new(invalid_message)
        end
      rescue *ignored_exceptions => error
        if raise_on_failure?
          raise
        else
          log "failed ignoring exception... #{error}", true
        end
      end

      private

      def invalid_message
        if !topic
          "A topic is required"
        elsif !message_type
          "A message type is required"
        else
          "Required attributes #{invalid_attributes} are missing."
        end
      end

      def hostname
        Emque::Producing.hostname
      end

      def formatted_time
        DateTime.now.new_offset(0).to_time.utc.iso8601
      end

      def uuid
        SecureRandom.uuid
      end

      def app_name
        Emque::Producing.configuration.app_name || raise("Messages must have an app name configured.")
      end

      def logger
        Emque::Producing.logger
      end

      def log(message, include_message = false)
        if Emque::Producing.configuration.log_publish_message
          message = "#{message} #{to_json}" if include_message
          logger.info("MESSAGE LOG: #{message}")
        end
      end

      def middleware
        self.class.middleware + Emque::Producing.configuration.middleware
      end

      def middleware?
        middleware.count > 0
      end

      def process_middleware(str)
        if middleware?
          middleware.inject(str) { |compiled, callable|
            callable.call(compiled)
          }
        else
          str
        end
      end

      def public_attributes
        public = self.class.attribute_set.select do |attr|
          attr && !self.class.private_attrs.include?(attr.name)
        end.map(&:name)
        slice_attributes(*public)
      end

      def slice_attributes(*keys)
        keys.map!(&:to_sym)
        attributes.select { |key, value| keys.include?(key) }
      end
    end
  end
end
