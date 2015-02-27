[ ![Codeship Status for
teamsnap/emque-producing](https://www.codeship.io/projects/2ca7fd90-1785-0132-5f9d-7ab39a5c8237/status)](https://www.codeship.io/projects/34115)

# Emque Producing

Define and send messages with Ruby to a variety of [message brokers](http://en.wikipedia.org/wiki/Message_broker).
The only currently supported message broker is [RabbitMQ](https://www.rabbitmq.com)

This is a library that pairs nicely with [Emque
Consuming](https://www.github.com/teamsnap/emque-consuming), a framework for
consuming and routing messages to your code.

## Installation

Add these lines to your application's Gemfile, depending on your message broker:

    # for RabbitMQ, bunny is used
    gem "emque-producing"
    gem "bunny", "~> 1.4.1"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emque-producing

## Usage

    # configure (likely in a Rails initializer)
    require 'emque-producing'
    Emque::Producing.configure do |c|
      c.app_name = "app"
      c.publishing_adapter = :rabbitmq
      c.rabbitmq_options = { :url => "amqp://guest:guest@localhost:5672" }
      c.error_handlers << Proc.new {|ex,context|
       # notify/log
      }
    end

    # create a message class
    class MyMessage
      include Emque::Producing::Message
      topic "topic1"
      message_type "mymessage.new"

      attribute :first_property, Integer, :required => true
      attribute :another_property, String, :required => true
    end

    # produce message
    message = MyMessage.new({:first_property => 1, :another_property => "another"})
    message.publish

For a more thorough guide to creating new messages and/or message producing
applications, [please read the wiki
entry](https://github.com/teamsnap/emque-producing/wiki/Creating-New-Producing-Applications)

## Requirements

* Ruby 1.9.3 or higher
* RabbitMQ 3.x
* Bunny 1.4.x

## Tests

To run tests...

```
rspec
```

If you would like to test the gem as part of your client, you can update the
configuration option `publish_messages` to false like so:
```ruby
    Emque::Producing.configure do |c|
      c.publish_messages = false
    ...other options
    end 
```
This will prevent Emque from actually attempting to make the connection to your
adapter which may be convenient in the case of CI environments.

## Contributing

1. Fork it ( http://github.com/teamsnap/emquemessages/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Roadmap

Kafka would make for a good adapter to be added to emque-producing. Anyone
wishing to submit a PR can use the RabbitMQ adapter as a model.
