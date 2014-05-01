require 'spec_helper'
require 'thread'

describe Xe::Context::Current do

  subject { Xe::Context }

  before do
    Xe::Context.clear_current
  end

  describe '.all_contexts' do

    it "is a hash" do
      expect(subject.all_contexts).to be_an_instance_of(Hash)
    end

    it "contains a wrapping context" do
      Xe::Context.wrap do |context|
        expect(subject.all_contexts.values).to include(context)
      end
    end

    it "contains the current context" do
      Xe::Context.wrap do |context|
        expect(subject.all_contexts.values).to include(subject.current)
      end
    end

    it "doesn't contain contexts which aren't current" do
      captured_context = nil
      Xe::Context.wrap { |context| captured_context = context }
      expect(subject.all_contexts.values).to_not include(captured_context)
    end

  end

  describe '.current' do

    it "is the current context" do
      Xe::Context.wrap do |context|
        expect(subject.current).to eq(context)
      end
    end

  end

  describe '.current=' do
    let(:context) { double(Xe::Context) }

    it "assigns the current context" do
      subject.current = context
      expect(subject.current).to eq(context)
    end

    it "assigns a value to the key of the current thread" do
      subject.current = context
      key = subject.current_thread_key
      expect(subject.all_contexts[key]).to eq(context)
    end
  end

  describe '.clear_current' do

    context "when no context is assigned" do
      it "is a no-op" do
        subject.clear_current
      end
    end

    context "when a context is assigned" do
      let(:context) { double(Xe::Context) }

      before do
        subject.current = context
      end

      it "clears the current context" do
        subject.clear_current
        expect(subject.current).to be_nil
      end

      it "deletes the key for the current thread" do
        key = subject.current_thread_key
        expect(subject.all_contexts[key]).to eq(context)
      end
    end

  end

  describe '.current_thread_key' do

    it "is the object_id of the current thread" do
      expect(subject.current_thread_key).to eq(Thread.current.object_id)
    end

  end

end
