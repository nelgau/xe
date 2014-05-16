require 'spec_helper'

describe Xe::Realizer::Cacheable do
  include Xe::Test::Mock::Realizer::Cacheable

  # The real subject is always included in a realizer.
  subject { realizer_class.new }

  let(:context) do
    double(Xe::Context).tap do |context|
      context.stub(:enabled?) { true }
      context.stub(:defer)
    end
  end

  let(:cache)         { new_cache_mock(cached_values) }
  let(:cached_values) { { '1' => 2 } }
  let(:cache_options) { { :prefix => prefix, :foo => :bar } }
  let(:prefix)        { nil }

  let(:realizer_class) do
    Class.new(Xe::Realizer::Base) do
      include Xe::Realizer::Cacheable
    end
  end

  let(:group)     { [1, 2, 3] }
  let(:group_key) { 'aaa' }
  let(:proxy_id)  { 3 }

  let(:results) { group.each_with_object({}) { |id, h| h[id] = id + 1 } }
  let(:cacheable_ids) { group }

  before do
    # We don't want to test the actual relationship between the realizer base
    # class and the context, only the interface.
    Xe::Context.stub(:current) { context }
    # Additionally, we don't want to resolve a proxy in our tests. Only
    # verify that Proxy.resolve is called and that the returned value is used.
    Xe::Proxy.stub(:resolve) { proxy_id }

    subject.stub(:perform) { results }
    subject.stub(:group_key) { group_key }
    subject.stub(:cache?) { |id, value| cacheable_ids.include?(id) }
  end

  describe '.use_cache' do

    def invoke_use_cache
      realizer_class.use_cache(cache, cache_options)
    end

    it "sets the class-level cache attribute" do
      invoke_use_cache
      expect(realizer_class.cache).to eq(cache)
    end

    it "sets the instance-level cache attribute" do
      invoke_use_cache
      expect(subject.cache).to eq(cache)
    end

    context "when the prefix option is given" do
      let(:prefix) { 'aaa' }

      it "sets the class-level cache_prefix attribute" do
        invoke_use_cache
        expect(realizer_class.cache_prefix).to eq(prefix)
      end

      it "sets the instance-level cache_prefix attribute" do
        invoke_use_cache
        expect(subject.cache_prefix).to eq(prefix)
      end

      it "doesn't include this key in the cache_options attribute" do
        invoke_use_cache
        expect(realizer_class.cache_options.keys).to_not include(:prefix)
      end
    end

    context "when option cache options are given" do
      let(:other_options) { { :foo => :bar } }

      before do
        cache_options.merge!(other_options)
      end

      it "sets the class-level cache_prefix attribute" do
        invoke_use_cache
        expect(realizer_class.cache_options).to include(other_options)
      end

      it "sets the instance-level cache_prefix attribute" do
        invoke_use_cache
        expect(subject.cache_options).to include(other_options)
      end
    end

  end

  describe '#[]' do

    let(:id)      { 1 }
    let(:options) { {} }

    def invoke_brackets
      subject[id, options]
    end

    context "when no cache is specified" do

      it "defers the value via the base realizer" do
        expect(context).to receive(:defer).with(subject, proxy_id, group_key)
        invoke_brackets
      end

      it "returns the proxy from Context#defer" do
        proxy = double(Xe::Proxy)
        context.stub(:defer) { proxy }
        expect(invoke_brackets).to eq(proxy)
      end

    end

    context "when a cache is specified" do
      before do
        realizer_class.use_cache(cache, cache_options)
      end

      it "defers the value via the base realizer" do
        cache_realizer = subject.cache_realizer
        expect(context).to receive(:defer).with(cache_realizer, proxy_id, nil)
        invoke_brackets
      end

      it "returns the proxy from Context#defer" do
        proxy = double(Xe::Proxy)
        context.stub(:defer) { proxy }
        expect(invoke_brackets).to eq(proxy)
      end

      context "when the uncached option is true" do
        let(:options) { { :uncached => true } }

        it "defers the value via the base realizer" do
          expect(context).to receive(:defer).with(subject, proxy_id, group_key)
          invoke_brackets
        end
      end
    end

  end

  describe '#cache?' do

    let(:id)    { 2 }
    let(:value) { 3 }

    it "is vacuously true" do
      returned = subject.cache?(id, value)
      expect(returned).to be_true
    end

  end

  describe '#cache_key' do

    let(:id) { 6 }

    it "is a string" do
      returned = subject.cache_key(id)
      expect(returned).to be_an_instance_of(String)
    end

    it "is the string representation of the given id" do
      returned = subject.cache_key(id)
      expect(returned).to eq(id.to_s)
    end

  end

  describe '#call' do

    def invoke_call
      subject.call(group, group_key)
    end

    context "when no cache is specified" do
      it "returns the results from the superclass implementation" do
        expect(invoke_call).to eq(results)
      end
    end

    context "when a cache is specified" do
      before do
        realizer_class.use_cache(cache, cache_options)
      end

      let(:multi_hash) do
        cacheable_ids.each_with_object({}) do |id, h|
          key = "#{prefix}#{subject.cache_key(id)}"
          h[key] = results[id]
        end
      end

      let(:multi_options) do
        subject.cache_options
      end

      it "returns the results from the superclass implementation" do
        expect(invoke_call).to eq(results)
      end

      context "when all values are cacheable" do
        let(:cacheable_ids) { group }

        it "sets the values in the cache" do
          expect(cache).to receive(:set_multi).with(multi_hash, multi_options)
          invoke_call
        end
      end

      context "when one value cannot be cached" do
        let(:cacheable_ids) { group[1..-1] }

        it "sets the values in the cache" do
          expect(cache).to receive(:set_multi).with(multi_hash, multi_options)
          invoke_call
        end
      end
    end

  end

  describe '#cache_realizer' do

    it "is an instance of Xe::Realizer::Proc" do
      expect(subject.cache_realizer).to be_an_instance_of(Xe::Realizer::Proc)
    end

    it "has the correct tag" do
      expect(subject.cache_realizer.tag).to eq(subject.cache_tag)
    end

    context "when called" do
      let(:cache_realizer_group) { [] }

      def invoke_call
        subject.cache_realizer.call(cache_realizer_group, nil)
      end

      context "when no cache is specified" do
        let(:cache_realizer_group) { [1, 2] }

        it "accesses uncached values on the original realizer" do
          expect(subject).to receive(:[]).with(anything, {uncached: true}).twice
          invoke_call
        end

        it "returns a map of the group to ids on the original realizer" do
          subject.stub(:[]) { |id| id + 10 }
          expected_result = cache_realizer_group.each_with_object({}) do |i, h|
            h[i] = i + 10
          end
          expect(invoke_call).to eq(expected_result)
        end
      end

      context "when a cache is specified" do
        before do
          realizer_class.use_cache(cache, cache_options)
        end

        context "when called for cached values" do
          let(:cache_realizer_group) { [1] }

          it "returns cached values" do
            expect(invoke_call).to eq({ 1 => 2 })
          end
        end

        context "when called for uncached values" do
          let(:uncached_id) { 2 }
          let(:cache_realizer_group) { [uncached_id] }

          it "accesses the uncached values on the original realizer" do
            expect(subject).to receive(:[]).with(uncached_id, {uncached: true})
            invoke_call
          end

          it "returns a map of the group to ids on the original realizer" do
            subject.stub(:[]) { |id| id + 10 }
            expected_result = cache_realizer_group.each_with_object({}) do |i, h|
              h[i] = i + 10
            end
            expect(invoke_call).to eq(expected_result)
          end
        end
      end
    end

  end

  describe '#cache' do
    before do
      realizer_class.use_cache(cache, cache_options)
    end

    it "is the specified cache" do
      expect(subject.cache).to eq(cache)
    end
  end

  describe '#cache_prefix' do
    let(:prefix) { 'bbb' }

    before do
      realizer_class.use_cache(cache, cache_options)
    end

    it "is the specified prefix" do
      expect(subject.cache_prefix).to eq(prefix)
    end
  end

  describe '#cache_options' do
    before do
      realizer_class.use_cache(cache, cache_options)
    end

    it "is the cache options (not prefix)" do
      expect(subject.cache_options).to eq({ :foo => :bar })
    end
  end

end
