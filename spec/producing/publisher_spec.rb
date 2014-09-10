require "spec_helper"

describe Emque::Producing::Publisher do
  describe "#publish" do
    context "when error handler raises an exception" do
      it "handles the exception" do
        expect_any_instance_of(Poseidon::Producer). to receive(:send_messages).and_raise
        Emque::Producing.configure do |c|
          c.error_handlers << Proc.new {|ex,context|
            raise "something"
          }
        end
        Emque::Producing.logger = nil
        publisher = Emque::Producing::Publisher.new
        publisher.publish("mytopic", "mymessage")
      end
    end
  end
end
