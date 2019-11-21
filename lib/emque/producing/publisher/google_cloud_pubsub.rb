require "google/cloud/pubsub"

module Emque
  module Producing
    module Publisher
      class GoogleCloudPubsub < Emque::Producing::Publisher::Base
        def publish(topic_name, message_type, message, raise_on_failure)
          Emque::Producing.logger.info("GoogleCloudPubsub#publish")

          pubsub = Google::Cloud::PubSub.new(
            :project_id => Emque::Producing.configuration.google_cloud_pubsub_options[:project_id],
            :credentials => Emque::Producing.configuration.google_cloud_pubsub_options[:credentials]
          )

          topic = pubsub.topic(topic_name)
          if topic.nil?
            Emque::Producing.logger.info("GoogleCloudPubsub Publisher: Creating topic #{topic_name}")
            topic = pubsub.create_topic(topic_name)
          end

          Emque::Producing.logger.info("GoogleCloudPubsub Publisher: Publishing Message")
          # msg = topic.publish(message)
          sent = true
          topic.publish_async(message) do |result|
            if result.succeeded?
              Emque::Producing.logger.info("GoogleCloudPubsub Publisher: Message succeeded")
              Emque::Producing.logger.info(result.data)
              sent = true
            else
              Emque::Producing.logger.warn("GoogleCloudPubsub Publisher: Message failed")
              Emque::Producing.logger.warn(result.data)
              Emque::Producing.logger.warn(result.error)
              sent = false
            end
          end

          topic.async_publisher.stop.wait!

          sent
        end
      end
    end
  end
end
