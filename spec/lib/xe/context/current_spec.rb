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

    it "contains the current context" do
      Xe::Context.wrap do
        expect(subject.all_contexts.values).to include(subject.current)
      end
    end

    it "doesn't contain contexts which aren't current" do
      captured_context = nil
      Xe::Context.wrap { captured_context = Xe::Context.current }
      expect(subject.all_contexts.values).to_not include(captured_context)
    end

  end

  describe '.current' do

    context "when wrapped" do
      it "is a context" do
        Xe::Context.wrap do
          expect(subject.current).to be_an_instance_of(Xe::Context)
        end
      end
    end

    context "when not wrapped" do
      it "is nil" do
        expect(subject.current).to be_nil
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
      key = Thread.current.object_id
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
        key = Thread.current.object_id
        expect(subject.all_contexts[key]).to eq(context)
      end
    end

  end

end
