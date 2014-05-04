require 'spec_helper'
require 'logger'

describe Xe::Proxy::Debugging do
  include Xe::Test::Mock::Proxy

  subject { Xe::Proxy::Debugging }

  let(:subclass)      { Class.new(Xe::Proxy) }
  let(:proxy)         { subclass.new(&subject_proc) }
  let(:subject_proc)  { Proc.new { subject_value } }
  let(:subject_value) { new_value_mock(1) }
  let(:logger)        { Logger.new(nil) }

  before do
    # Most of the implementation assumes the aliased methods already exist so
    # it makes little sense to test the module on its own.
    subclass.send(:include, Xe::Proxy::Debugging)
    subject.logger = logger
  end

  after do
    subject.logger = subject.default_logger
  end

  describe '.included' do

    it "patches base so emit is called when invoking a proxy method" do
      captured_methods = []
      subject.stub(:emit) { |_, method, _| captured_methods << method }
      proxy.__resolve_subject
      expect(captured_methods).to include(:__resolve_subject)
    end

    it "patches base to invoke the original method" do
      proxy.__resolve_subject
      # Indirect test: verify that the proxy is resolved.
      expect(proxy.__resolved?).to be_true
      expect(proxy.__subject).to eq(subject_value)
    end

  end

  describe '.emit' do

    let(:receiver) { new_value_mock(0) }
    let(:method)   { :__resolve_subject }
    let(:args)     { [] }
    let(:proc)     { Proc.new {} }

    context "when called with a value" do
      let(:receiver) { new_value_mock(0) }

      it "writes to the logger" do
        expect(logger).to receive(:info)
        subject.emit(receiver, method, args, &proc)
      end
    end

    context "when called with a proxy" do
      let(:receiver) { proxy }

      context "when called with an unresolved proxy" do
        it "writes to the logger" do
          expect(logger).to receive(:info)
          subject.emit(receiver, method, args, &proc)
        end
      end

      context "when called with a proxy that has resolved to a value" do
        let(:subject_value) { new_value_mock(1) }

        before do
          proxy.__resolve_subject
        end

        it "writes to the logger" do
          expect(logger).to receive(:info)
          subject.emit(receiver, method, args, &proc)
        end
      end

      context "when called with a proxy that has resolved to a proxy" do
        let(:subject_value) { proxy2 }
        let(:proxy2) { subclass.new { value2 } }
        let(:value2) { new_value_mock(2) }

        before do
          proxy.__resolve_subject
        end

        it "writes to the logger" do
          expect(logger).to receive(:info)
          subject.emit(receiver, method, args, &proc)
        end
      end

      context "(recursion)" do
        it "doesn't invoke __resolved? on the proxy" do
          expect(proxy).to_not receive(:__resolved?)
          subject.emit(proxy, :foo, [])
        end

        it "doesn't invoke __value? on the proxy" do
          expect(proxy).to_not receive(:__value?)
          subject.emit(proxy, :foo, [])
        end

        it "doesn't invoke __proxy_id on the proxy" do
          expect(proxy).to_not receive(:__proxy_id)
          subject.emit(proxy, :foo, [])
        end
      end
    end
  end

end
