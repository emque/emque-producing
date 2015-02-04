module Emque
  module Producing
    module MessageWithChangeset
      def self.included(base)
        base.send(:include, Emque::Producing::Message)
        base.send(:attribute, :partition_key, String, :default => nil, :required => false)
        base.send(:attribute, :change_set, Hash, :default => :build_change_set, :required => true)
        base.send(:private_attribute, :updated)
        base.send(:private_attribute, :original)
      end

      def build_change_set
        ChangesPayloadGenerator
          .new({:original => original, :updated => updated})
          .execute
      end

      def build_id
        if updated
          updated.fetch("id") { updated[:id] }
        elsif original
          original.fetch("id") { original[:id] }
        else
          raise Emque::Producing::Message::InvalidMessageError
        end
      end
    end

    class ChangesPayloadGenerator
      def initialize(opts = {})
        @original = opts.fetch(:original, {}) || {}
        @updated = opts.fetch(:updated, {}) || {}
      end

      def execute
        {:original => original, :updated => updated, :delta => delta}
      end

      private

      attr_reader :original, :updated

      def delta
        if original.empty?
          :_created
        elsif updated.empty?
          :_deleted
        else
          _delta = updated
            .reject { |attr, val| original[attr] == val }
            .map { |attr, val|
            [attr, {:original => original[attr], :updated => val}]
          }
          Hash[_delta]
        end
      end
    end
  end
end
