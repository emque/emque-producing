ROOT_DIRECTORY = File.absolute_path(File.dirname(__FILE__) + "/../")

require "test_cluster"
require "spec_helper"

unless File.directory?(File.join(ROOT_DIRECTORY, "kafka_2.8.0-0.8.1"))
  puts "\033[0;32m"
  puts "*" * 83
  puts "Downloading kafka"
  puts "*" * 83
  puts "\033[0;0m"

  system(
    "cd #{ROOT_DIRECTORY} && curl https://archive.apache.org/dist/kafka/0.8.1/kafka_2.8.0-0.8.1.tgz | tar xz"
  )
end

ENV["KAFKA_PATH"] = File.join(ROOT_DIRECTORY, "kafka_2.8.0-0.8.1")
ENV["SCALA_VERSION"] = "2.8.0"

RSpec.configure do |config|
  config.before(:suite) do
    JavaRunner.remove_tmp
    JavaRunner.set_kafka_path!
    $tc = TestCluster.new
    $tc.start
    sleep 5
  end

  config.after(:suite) do
    $tc.stop
  end
end
