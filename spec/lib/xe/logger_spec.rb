require 'spec_helper'

describe Xe::Logger do

  subject { Xe::Logger }

  describe '.from_option' do

    context "when option is ':stdout'" do
      let(:option) { :stdout }

      it "returns an instance of Xe::Logger::Text" do
        result = subject.from_option(option)
        expect(result).to be_an_instance_of(Xe::Logger::Text)
      end
    end

    context "when option is a logger instance" do
      let(:logger) { Xe::Logger::Base.new }
      let(:option) { logger }

      it "returns the logger instance" do
        result = subject.from_option(option)
        expect(result).to eq(logger)
      end
    end

  end

  shared_examples_for "a logger" do

    let(:deferrable) { Xe::Deferrable.new }
    let(:target)     { Xe::Target.new(deferrable, 0) }
    let(:event)      { Xe::Event.from_target(target) }

    describe '#call' do

      it "invokes a method by type" do
        subject.should_receive(:event_realize).with(event)
        subject.call(:event_realize, event)
      end

      it "handles 'event_realize'" do
        subject.call(:event_realize, event)
      end

      it "handles 'value_cached'" do
        subject.call(:value_cached, target)
      end

      it "handles 'value_deferred'" do
        subject.call(:value_deferred, target)
      end

      it "handles 'value_dispatched'" do
        subject.call(:value_dispatched, target)
      end

      it "handles 'value_realized'" do
        subject.call(:value_realized, target)
      end

      it "handles 'value_forced'" do
        subject.call(:value_forced, target)
      end

      it "handles 'fiber_new'" do
        subject.call(:fiber_new)
      end

      it "handles 'fiber_wait'" do
        subject.call(:fiber_wait, target)
      end

      it "handles 'fiber_release'" do
        subject.call(:fiber_release, target, 1)
      end

      it "handles 'proxy_new'" do
        subject.call(:proxy_new, target)
      end

      it "handles 'proxy_resolve'" do
        subject.call(:proxy_resolve, target, 2)
      end

      it "handles 'finalize_start'" do
        subject.call(:finalize_start)
      end

      it "handles 'finalize_step'" do
        subject.call(:finalize_step, event)
      end

      it "handles 'finalize_deadlock'" do
        subject.call(:finalize_deadlock)
      end

    end

  end

  describe Xe::Logger::Base do
    subject { Xe::Logger::Base.new }
    it_behaves_like "a logger"
  end

  describe Xe::Logger::Text do
    subject { Xe::Logger::Text.new(:logger => logger) }
    let(:logger) { Logger.new(nil) }
    it_behaves_like "a logger"
  end

  describe Xe::Logger::Event do
    subject { Xe::Logger::Event.new }
    it_behaves_like "a logger"
  end

end
