require 'spec_helper'

describe 'Xe - Cacheable' do
  include Xe::Test::Mock::Realizer::Cacheable

  subject { realizer }

  let(:cache)         { new_cache_mock(cached_values) }
  let(:cache_options) { {} }
  let(:cached_values) { {} }

  let(:realizer_class) do
    Class.new(Xe::Realizer::Base) do
      include Xe::Realizer::Cacheable

      def perform(group, key)
        group.each_with_object({}) do |x, rs|
          rs[x] = x + 1
        end
      end
    end
  end

  let(:realizer) { realizer_class.new }

  before do
    realizer_class.use_cache(cache, cache_options)
  end

  context "when accessing a value outside of a context" do
    it "returns the expected result" do
      expect(realizer[1]).to eq(2)
    end
  end

  context "when accessing an uncached value" do
    it "returns the expected result" do
      result = Xe.context { realizer[1] }
      expect(result).to eq(2)
    end

    it "realizes values on both the base realizer and its cache realizer" do
      expect(subject).to receive(:perform).with([1], nil).and_call_original
      expect(subject.cache_realizer).to receive(:perform).with([1], nil).and_call_original
      Xe.context { realizer[1] }
    end
  end

  context "after realizing an uncached value" do
    before do
      Xe.context { realizer[1] }
    end

    it "is in the cache" do
      expect(cache.cached_values).to include({'1' => 2})
    end

    it "does not invoke the base realizer" do
      expect(subject).to_not receive(:perform)
      expect(subject.cache_realizer).to receive(:perform).with([1], nil).and_call_original
      Xe.context { realizer[1] }
    end
  end

  context "when accessing a mixture of cached and uncached values" do
    let(:cached_values) { {'2' => 50} }

    it "returns the expected result" do
      result = Xe.context { [realizer[1], realizer[2]] }
      expect(result).to eq([2, 50])
    end
  end

end
