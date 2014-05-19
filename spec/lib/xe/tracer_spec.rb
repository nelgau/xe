require 'spec_helper'

describe Xe::Tracer do

  subject { Xe::Tracer }

  let(:deferrable) { Xe::Deferrable.new }
  let(:target)     { Xe::Target.new(deferrable, 0) }
  let(:event)      { Xe::Event.from_target(target) }

  describe '.from_options' do

    let(:options) { { tracer: tracer } }
    let(:tracer)  { nil }

    context "when option is ':stdout'" do
      let(:tracer) { :stdout }

      it "returns an instance of Xe::Tracer::Text" do
        result = subject.from_options(options)
        expect(result).to be_an_instance_of(Xe::Tracer::Text)
      end
    end

    context "when option is a logger instance" do
      let(:tracer) { Xe::Tracer::Base.new }

      it "returns the logger instance" do
        result = subject.from_options(options)
        expect(result).to eq(tracer)
      end
    end

  end

  describe '.default_logger' do

    it "is an instance of Logger" do
      expect(subject.default_logger).to be_an_instance_of(Logger)
    end

  end

  describe '#call' do

    subject { Xe::Tracer::Base.new }

    it "invokes the method named by type" do
      expect(subject).to receive(:event_realize).with(event)
      subject.call(:event_realize, event)
    end

  end

  shared_examples_for "a tracer" do

    describe '#call' do

      it "invokes a method by type" do
        expect(subject).to receive(:event_realize).with(event)
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

      it "handles 'fiber_free'" do
        subject.call(:fiber_free, event)
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

      it "handles 'finalize_by_proxy'" do
        subject.call(:finalize_by_proxy)
      end

    end

  end

  describe Xe::Tracer::Base do
    subject { Xe::Tracer::Base.new }
    it_behaves_like "a tracer"
  end

  describe Xe::Tracer::Text do
    subject { Xe::Tracer::Text.new(logger: logger) }
    let(:logger) { ::Logger.new(nil) }
    it_behaves_like "a tracer"
  end

  describe Xe::Tracer::Event do
    subject { Xe::Tracer::Event.new }
    it_behaves_like "a tracer"
  end

end
