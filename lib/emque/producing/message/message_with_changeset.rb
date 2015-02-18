module Emque
  module Producing
    module MessageWithChangeset
      module ClassMethods
        def translate_changeset_attrs(attrs = {})
          @attrs_to_translate ||= {}
          @attrs_to_translate.merge!(attrs)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, Emque::Producing::Message)
        base.send(:attribute, :partition_key, String, :default => nil, :required => false)
        base.send(:attribute, :change_set, Hash, :default => :build_change_set, :required => true)
        base.send(:private_attribute, :updated)
        base.send(:private_attribute, :original)
      end

      def translated_attrs
        self.class.instance_variable_get(:@attrs_to_translate)
      end

      def build_change_set
        ChangesPayloadGenerator.new(
          {
            :original => original,
            :updated => updated,
            :translated_attrs => translated_attrs
          }
        ).execute
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
      def initialize(changeset_data = {})
        @original = changeset_data[:original] || {}
        @updated = changeset_data[:updated] || {}
        @translated_attrs = changeset_data[:translated_attrs] || {}
      end

      def execute
        translate_attrs if translated_attrs.any?
        {:original => original, :updated => updated, :delta => delta}
      end

      private

      attr_reader :original, :updated, :translated_attrs

      def translate_attrs
        @original = translate(original)
        @updated = translate(updated)
      end

      def deep_copy(attr_set)
        Oj.load(Oj.dump(attr_set))
      end

      def translate(attr_set)
        deep_copy(attr_set).tap do |cloned_attrs|
          stringified_attrs.each_pair do |old_name, new_name|
            if cloned_attrs.key?(old_name)
              cloned_attrs[new_name] = cloned_attrs.delete(old_name)
            end
          end
        end
      end

      def stringified_attrs
        {}.tap do |new_hash|
          translated_attrs.each_pair { |k,v| new_hash[k.to_s] = v.to_s }
        end
      end

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
