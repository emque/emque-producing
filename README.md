[![Build Status](https://travis-ci.org/emque/emque-producing.png)](https://travis-ci.org/emque/emque-producing)

# Emque Producing

Define and send messages with Ruby to a variety of [message brokers](http://en.wikipedia.org/wiki/Message_broker).
The only currently supported message broker is [RabbitMQ](https://www.rabbitmq.com)

This is a library that pairs nicely with [Emque Consuming](https://www.github.com/emque/emque-consuming), a framework for
consuming and routing messages to your code.

## Installation

Add these lines to your application's Gemfile, depending on your message broker:

    # for RabbitMQ, bunny is used
    gem "emque-producing"
    gem "bunny", "~> 1.7"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emque-producing

## Usage

    # configure (likely in a Rails initializer)
    require 'emque-producing'
    Emque::Producing.configure do |c|
      c.app_name = "app"
      c.publiser :rabbitmq, url: "amqp://guest:guest@localhost:5672"
      c.publiser :google_cloud_pubsub, project_id: "project", credentials: "credentials"
      c.error_handlers << Proc.new {|ex,context|
       # notify/log
      }
    end

    # create a message class
    class MyMessage
      include Emque::Producing::Message
      topic "topic1"
      message_type "mymessage.new"

      values do
        attribute :first_property, Integer, :required => true
        attribute :another_property, String, :required => true
      end
    end

    # produce message
    message = MyMessage.new({:first_property => 1, :another_property => "another"})
    message.publish

    # create a message class including changesets
    class MyChangesetMessage
      include Emque::Producing.message(:with_changeset => true)
      topic "topic1"
      message_type "mymessage.new"

      # Need to override an attribute name in the changeset? Simply define
      # the old name and new name here. This can be useful for ensuring
      # messages are consistent across varying producers.
      translate_changeset_attrs :old_attr_name => :new_attr_name
    end

    produced_message = TestMessageWithChangeset.new(
      :updated => {:old_attr_name => "Event"},
      :original => {:old_attr_name => "Game"}
    )
    json = produced_message.to_json
    consumed_message = Oj.load(json)
    expect(consumed_message["change_set"]).to eql(
      {
        "original"=>{"new_attr_name"=>"Game"},
        "updated"=>{"new_attr_name"=>"Event"},
        "delta"=>{
          "new_attr_name"=>{
            "original"=>"Game", "updated"=>"Event"
          }
        }
      }
    )

For a more thorough guide to creating new messages and/or message producing
applications, [please read the wiki entry](https://github.com/emque/emque-producing/wiki/Creating-New-Producing-Applications)

## Requirements

* Ruby 1.9.3 or higher
* RabbitMQ 3.x
* Bunny 1.4.x

## Tests

To run tests...

```
bundle exec rspec
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

FIRST: Read our style guides at https://github.com/teamsnap/guides/tree/master/ruby

1. Fork it ( http://github.com/emque/emque-producing/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Roadmap

Kafka would make for a good adapter to be added to emque-producing. Anyone
wishing to submit a PR can use the RabbitMQ adapter as a model.
