require "spec_helper"
require "virtus"
require "emque/producing/message/message_with_changeset"

class FakeModel
  include Virtus.value_object

  values do
    attribute :foo, Integer
    attribute :bar, Integer
    attribute :baz, Integer
  end
end

describe Emque::Producing::ChangesPayloadGenerator do
  context "creating object" do
    it "returns a correctly formatted payload" do
      object = FakeModel.new(:foo => 1, :bar => 2, :baz => 3)
      generator = Emque::Producing::ChangesPayloadGenerator.new(:updated => object.attributes)
      payload = generator.execute

      expect(payload).to eq(
        {
          :original => {},
          :updated => {:foo => 1, :bar => 2, :baz => 3},
          :delta => :_created
        }
      )
    end
  end

  context "updating object" do
    it "returns a correctly formatted payload" do
      original = FakeModel.new(:foo => 1, :bar => 2, :baz => 3)
      updated = FakeModel.new(:foo => 4, :bar => 2, :baz => 3)
      generator = Emque::Producing::ChangesPayloadGenerator.new(
        :original => original.attributes, :updated => updated.attributes
      )
      payload = generator.execute

      expect(payload).to eq(
        {
          :original => {:foo => 1, :bar => 2, :baz => 3},
          :updated => {:foo => 4, :bar => 2, :baz => 3},
          :delta => {:foo => {:original => 1, :updated => 4}}
        }
      )
    end
  end

  context "deleting object" do
    it "returns a correctly formatted payload" do
      object = FakeModel.new(:foo => 1, :bar => 2, :baz => 3)
      generator = Emque::Producing::ChangesPayloadGenerator.new(:original => object.attributes)
      payload = generator.execute

      expect(payload).to eq(
        {
          :original => {:foo => 1, :bar => 2, :baz => 3},
          :updated => {},
          :delta => :_deleted
        }
      )
    end
  end
end
