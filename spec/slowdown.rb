require "bunny"
require "emque-producing"
require "benchmark"

class FooMessage
  include Emque::Producing::Message
  topic "foo"
  message_type "foo.bar"
  raise_on_failure false
  attribute :foo, String, :required => true
end

Emque::Producing.configure do |c|
  c.app_name = "publisher_confirms_tester"
  c.publishing_adapter = :rabbitmq
  c.rabbitmq_options[:url] = "amqp://guest:guest@localhost:5672"
end

# http://www.rabbitmq.com/confirms.html
class PublisherConfirmsTester

  #delete queues bound to foo exchange before running
  def no_subscribed_queue
    times = []
    loop do
      total_time = Benchmark.realtime do
        message = FooMessage.new(:foo => "bar")
        message.publish
      end
      times << total_time
      puts "publish: #{total_time} avg: #{average(times)}"
    end
  end

  def with_subscribed_queue
    conn = Bunny.new
    conn.start
    ch   = conn.create_channel
    x = ch.fanout("foo", :durable => true, :auto_delete => false)
    puts "Exchange Created..."

    #ch.queue("", :auto_delete => true).bind(x)
    #ch.queue("", :auto_delete => false).bind(x)
    ch.queue("foo.test", :auto_delete => false, :durable => true).bind(x)
    puts "Queue bound..."
    conn.close

    times = []
    10000.times do
      total_time = Benchmark.realtime do
        message = FooMessage.new(:foo => "bar")
        message.publish
      end
      times << total_time
      puts "publish: #{total_time} avg: #{average(times)}"
    end
  end

  private

  def median(array)
    sorted = array.sort
    len = sorted.size
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def average(array)
    array.inject(0){|sum,x| sum + x } / array.size
  end
end

#PublisherConfirmsTester.new.no_subscribed_queue
PublisherConfirmsTester.new.with_subscribed_queue
