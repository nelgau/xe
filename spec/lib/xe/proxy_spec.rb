require 'spec_helper'

describe Xe::Proxy do
  include Xe::Test::Mock::Proxy

  subject { Xe::Proxy.new(&resolve_proc) }

  let(:resolve_proc)  { Proc.new { subject_value } }
  let(:subject_value) { new_value_mock(1) }
  let(:non_proxy)     { new_value_mock(2) }

  def proxy_for_value(x)
    Xe::Proxy.new { x }
  end

  describe '.proxy?' do

    let(:object) { nil }

    context "when the object is a proxy" do
      let(:object) { subject }

      it "is true" do
        expect(Xe::Proxy.proxy?(object)).to be_true
      end
    end

    context "when the object is not a proxy" do
      let(:object) { non_proxy }

      it "is false" do
        expect(Xe::Proxy.proxy?(object)).to be_false
      end
    end

  end

  describe ".resolve" do

    context "when the object is a proxy" do
      let(:object) { subject }

      it "is a non-proxy object" do
        result = Xe::Proxy.resolve(object)
        expect(Xe::Proxy.proxy?(result)).to be_false
      end

      it "is the proxied value" do
        result = Xe::Proxy.resolve(object)
        expect(result).to eq(subject_value)
      end
    end

    context "when the object is a proxy of a proxy" do
      let(:proxy2) { proxy_for_value(subject) }
      let(:object) { proxy2 }

      it "is a non-proxy object" do
        result = Xe::Proxy.resolve(object)
        expect(Xe::Proxy.proxy?(result)).to be_false
      end

      it "is the proxied value" do
        result = Xe::Proxy.resolve(object)
        expect(result).to eq(subject_value)
      end
    end

    context "when the object is not a proxy" do
      let(:object) { non_proxy }

      it "is a non-proxy object" do
        result = Xe::Proxy.resolve(object)
        expect(Xe::Proxy.proxy?(result)).to be_false
      end

      it "is the object" do
        result = Xe::Proxy.resolve(object)
        expect(result).to eq(object)
      end
    end

  end

  describe '#__xe_proxy?' do

    context "when the object is a proxy" do
      let(:object) { subject }

      it "is true" do
        expect(object.__xe_proxy?).to be_true
      end
    end

    context "when the object is not a proxy" do
      let(:object) { non_proxy }

      it "is false" do
        expect(object.__xe_proxy?).to be_false
      end
    end

  end

  describe '#initalize' do

    it "sets the __subject attribute to nil" do
      expect(subject.__subject).to be_nil
    end

    it "sets the __resolve_proc attribute to the given block" do
      expect(subject.__resolve_proc).to eq(resolve_proc)
    end

    context "when no block is given" do
      let(:proxy) { Xe::Proxy.new }

      it "raises ArgumentError" do
        expect { proxy }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#method_missing' do

    it "calls the target method on the resolved subject" do
      expect(subject_value).to receive(:foo)
      subject.foo
    end

    it "passes arguments to the resolved object" do
      expect(subject_value).to receive(:foo) do |*args|
        expect(args).to eq([1, 2, 3])
      end
      subject.foo(1, 2, 3)
    end

    it "passes a block to the resolved object" do
      proc = Proc.new { "bar" }
      expect(subject_value).to receive(:foo) do |&blk|
        expect(blk).to eq(proc)
      end
      subject.foo(&proc)
    end

    context "when the proxy is not resolved" do
      it "resolves the proxy" do
        subject.foo
        expect(subject.__resolved?).to be_true
      end
    end

  end

  describe '#__resolve' do

    let(:to_value) { false }

    def invoke_resolve
      subject.__resolve(to_value)
    end

    context "when the proxy is resolved to a value" do
      let(:value) { 2 }

      before do
        subject.__set_subject(value)
      end

      it "returns the value" do
        expect(invoke_resolve).to eq(value)
      end

      it "doesn't call __resolve_proc" do
        expect(resolve_proc).to_not receive(:call)
        invoke_resolve
      end

      it "terminates early" do
        expect(subject).to_not receive(:__resolve_subject)
        expect(subject).to_not receive(:__memoize_subject)
        invoke_resolve
      end
    end

    context "when the immediate subject is a value" do
      let(:subject_value) { new_value_mock(3) }

      it "resolves the proxy" do
        invoke_resolve
        expect(subject.__resolved?).to be_true
      end

      it "resolves to the value" do
        invoke_resolve
        expect(subject.__subject).to eq(subject_value)
      end

      it "returns the resolved value" do
        result = invoke_resolve
        expect(result).to eq(subject_value)
      end
    end

    context "when not resolving to a value" do
      let(:to_value) { false }

      context "when the immediate subject is a proxy" do
        let(:subject_value) { proxy }

        let(:proxy) { proxy_for_value(value) }
        let(:value) { new_value_mock(4) }

        it "resolves the proxy" do
          invoke_resolve
          expect(subject.__resolved?).to be_true
        end

        it "resolves to the immediate subject (equal by proxy_id)" do
          invoke_resolve
          expect(subject.__subject.__proxy_id).to eq(proxy.__proxy_id)
        end

        it "returns the resolved subject (equal by proxy_id)" do
          result = invoke_resolve
          expect(result.__proxy_id).to eq(proxy.__proxy_id)
        end
      end

      context "when the immediate subject is a chain of proxies" do
        let(:subject_value) { proxy1 }

        let(:proxy1) { proxy_for_value(value1) }
        let(:value1) { proxy2 }

        let(:proxy2) { proxy_for_value(value2) }
        let(:value2) { new_value_mock(5) }

        context "when no intermediate proxy is resolved" do
          it "resolves the proxy" do
            invoke_resolve
            expect(subject.__resolved?).to be_true
          end

          it "resolves to the immediate subject (equal by proxy_id)" do
            invoke_resolve
            expect(subject.__subject.__proxy_id).to eq(proxy1.__proxy_id)
          end

          it "returns the resolved subject (equal by proxy_id)" do
            result = invoke_resolve
            expect(result.__proxy_id).to eq(proxy1.__proxy_id)
          end
        end

        context "when an intermediate proxy is resolved" do
          before do
            proxy1.__resolve
          end

          it "resolves the proxy" do
            invoke_resolve
            expect(subject.__resolved?).to be_true
          end

          it "resolves to the memoized subject (equal by proxy_id)" do
            invoke_resolve
            expect(subject.__subject.__proxy_id).to eq(proxy2.__proxy_id)
          end

          it "returns the memoized subject (equal by proxy_id)" do
            result = invoke_resolve
            expect(result.__proxy_id).to eq(proxy2.__proxy_id)
          end
        end

      end

    end

    context "when resolving to a value" do
      let(:to_value) { true }

      context "when the immediate subject is a proxy" do
        let(:subject_value) { proxy }

        let(:proxy) { proxy_for_value(value) }
        let(:value) { new_value_mock(6) }

        it "resolves the proxy" do
          invoke_resolve
          expect(subject.__resolved?).to be_true
        end

        it "resolves to a value" do
          invoke_resolve
          expect(Xe::Proxy.proxy?(subject.__subject)).to be_false
        end

        it "resolves to the correct value" do
          invoke_resolve
          expect(subject.__subject).to eq(value)
        end

        it "returns the resolved value" do
          result = invoke_resolve
          expect(result).to eq(value)
        end
      end

      context "when the immediate subject is a chain of proxies" do
        let(:subject_value) { proxy1 }

        let(:proxy1) { proxy_for_value(value1) }
        let(:value1) { proxy2 }

        let(:proxy2) { proxy_for_value(value2) }
        let(:value2) { new_value_mock(7) }

        context "when no intermediate proxy is resolved" do
          it "resolves the proxy" do
            invoke_resolve
            expect(subject.__resolved?).to be_true
          end

          it "resolves to a value" do
            invoke_resolve
            expect(Xe::Proxy.proxy?(subject.__subject)).to be_false
          end

          it "resolves to the correct value" do
            invoke_resolve
            expect(subject.__subject).to eq(value2)
          end

          it "returns the resolved value" do
            result = invoke_resolve
            expect(result).to eq(value2)
          end
        end

        context "when an intermediate proxy is resolved" do
          before do
            proxy1.__resolve
          end

          it "resolves the proxy" do
            invoke_resolve
            expect(subject.__resolved?).to be_true
          end

          it "resolves to a value" do
            invoke_resolve
            expect(Xe::Proxy.proxy?(subject.__subject)).to be_false
          end

          it "resolves to the correct value" do
            invoke_resolve
            expect(subject.__subject).to eq(value2)
          end

          it "returns the resolved value" do
            result = invoke_resolve
            expect(result).to eq(value2)
          end
        end

      end

    end

  end

  describe '#__resolve_value' do

    context "when the proxy is resolved to a value" do
      let(:value) { 2 }

      before do
        subject.__set_subject(value)
      end

      it "returns the value" do
        expect(subject.__resolve_value).to eq(value)
      end

      it "doesn't call __resolve_proc" do
        expect(resolve_proc).to_not receive(:call)
        subject.__resolve_value
      end

      it "terminates early" do
        expect(subject).to_not receive(:__resolve)
        subject.__resolve_value
      end
    end

    context "when the immediate subject is a chain of proxies" do
      let(:subject_value) { proxy1 }

      let(:proxy1) { proxy_for_value(value1) }
      let(:value1) { proxy2 }

      let(:proxy2) { proxy_for_value(value2) }
      let(:value2) { new_value_mock(8) }

      context "when no intermediate proxy is resolved" do
        it "resolves the proxy" do
          subject.__resolve_value
          expect(subject.__resolved?).to be_true
        end

        it "resolves to a value" do
          subject.__resolve_value
          expect(Xe::Proxy.proxy?(subject.__subject)).to be_false
        end

        it "resolves to the correct value" do
          subject.__resolve_value
          expect(subject.__subject).to eq(value2)
        end

        it "returns the resolved value" do
          result = subject.__resolve_value
          expect(result).to eq(value2)
        end
      end
    end

  end

  describe '#__resolved?' do

    context "when the proxy has no subject" do
      it "is false" do
        expect(subject.__resolved?).to be_false
      end
    end

    context "when the proxy has a subject" do
      let(:object) { new_value_mock(0) }

      before do
        subject.__set_subject(object)
      end

      it "is true" do
        expect(subject.__resolved?).to be_true
      end
    end

  end

  describe '#__value?' do

    context "when the proxy has no subject" do
      it "is false" do
        expect(subject.__value?).to be_false
      end
    end

    context "when the proxy has a proxy for a subject" do
      let(:object) { proxy_for_value(0) }

      before do
        subject.__set_subject(object)
      end

      it "is false" do
        expect(subject.__value?).to be_false
      end
    end

    context "when the proxy has a value for a subject" do
      let(:object) { new_value_mock(0) }

      before do
        subject.__set_subject(object)
      end

      it "is true" do
        expect(subject.__value?).to be_true
      end
    end

  end

  describe '#__valid?' do

    context "before invalidation" do
      it "is true" do
        expect(subject.__valid?).to be_true
      end
    end

    context "after invalidation" do
      before do
        subject.__invalidate!
      end

      it "is false" do
        expect(subject.__valid?).to be_false
      end
    end

    context "after setting the subject" do
      let(:object) { new_value_mock(0) }

      before do
        subject.__set_subject(object)
      end

      it "is false" do
        expect(subject.__valid?).to be_false
      end
    end

  end

  describe '#__set_subject' do

    let(:object) { new_value_mock(0) }

    it "sets the __subject attribute" do
      subject.__set_subject(object)
      expect(subject.__subject).to eq(object)
    end

    it "marks the proxy as resolved" do
      subject.__set_subject(object)
      expect(subject.__resolved?).to be_true
    end

    it "sets the resolve_proc attribute to nil" do
      subject.__set_subject(object)
      expect(subject.__resolve_proc).to be_nil
    end

    context "when the argument is a value" do
      let(:object) { new_value_mock(0) }

      it "returns the subject (that compares equal)" do
        result = subject.__set_subject(object)
        expect(result).to eq(object)
      end

      it "marks the proxy as having a value" do
        subject.__set_subject(object)
        expect(subject.__value?).to be_true
      end
    end

    context "when the argument is a proxy" do
      let(:object) { proxy_for_value(1) }

      it "returns the subject (equal by __proxy_id)" do
        result = subject.__set_subject(object)
        expect(result.__proxy_id).to eq(object.__proxy_id)
      end

      it "marks the proxy as not having a value" do
        subject.__set_subject(object)
        expect(subject.__value?).to be_false
      end
    end

  end

  describe '#__invalidate!' do

    it "sets the resolve_proc attribute to nil" do
      subject.__invalidate!
      expect(subject.__resolve_proc).to be_nil
    end

  end

  describe '#__resolve_subject' do

    context "when the proxy has no subject" do
      it "calls __resolve_proc" do
        expect(resolve_proc).to receive(:call).and_call_original
        subject.__resolve_subject
      end

      it "sets the __subject attribute with the result of __resolve_proc" do
        subject.__resolve_subject
        expect(subject.__subject).to eq(subject_value)
      end

      it "returns the subject" do
        result = subject.__resolve_subject
        expect(result).to eq(subject_value)
      end
    end

    context "when the proxy has a subject" do
      let(:existing_value) { new_value_mock(2) }

      before do
        subject.__set_subject(existing_value)
      end

      it "doesn't call the __resolve_proc" do
        expect(resolve_proc).to_not receive(:call)
        subject.__resolve_subject
      end

      it "doesn't alter the __subject attribute" do
        subject.__resolve_subject
        expect(subject.__subject).to eq(existing_value)
      end

      it "returns the subject" do
        result = subject.__resolve_subject
        expect(result).to eq(existing_value)
      end
    end

    context "when the proxy is invalid" do
      before do
        subject.__invalidate!
      end

      it "raises Xe::InvalidProxyError" do
        expect {
          subject.__resolve_subject
        }.to raise_error(Xe::InvalidProxyError)
      end
    end

  end

  describe '#__memoize_subject' do
    let(:to_value) { false }
    let(:existing_subject) { new_value_mock(9) }

    before do
      subject.__set_subject(existing_subject)
    end

    def invoke_memoize_subject
      subject.__memoize_subject(subject, to_value)
    end

    context "when the subject is a value" do
      let(:existing_subject) { 2 }

      it "returns the value" do
        expect(invoke_memoize_subject).to eq(existing_subject)
      end
    end

    context "when the subject is a proxy (the intermediate)" do
      let(:existing_subject) { proxy1 }

      let(:proxy1) { proxy_for_value(value1) }
      let(:value1) { proxy2 }

      let(:proxy2) { proxy_for_value(value2) }
      let(:value2) { new_value_mock(10) }

      context "when not resolving to a value" do
        let(:to_value) { false }

        context "when the subject is not resolved" do
          it "doesn't invoke memoization on the intermediate" do
            invoke_memoize_subject
            # Indirect test: Ensure that the subject is memoized as proxy1.
            expect(subject.__subject.__proxy_id).to eq(proxy1.__proxy_id)
          end

          it "returns the subject (equal by __proxy_id)" do
            result = invoke_memoize_subject
            expect(result.__proxy_id).to eq(proxy1.__proxy_id)
          end
        end

        context "when the subject is resolved" do
          before do
            existing_subject.__resolve_subject
          end

          it "invokes memoization on the intermediate" do
            invoke_memoize_subject
            # Indirect test: Ensure that the subject is memoized as proxy2.
            expect(subject.__subject.__proxy_id).to eq(proxy2.__proxy_id)
          end

          it "sets the subject to the result of the recursive memoization" do
            result = invoke_memoize_subject
            expect(result.__proxy_id).to eq(proxy2.__proxy_id)
          end

          it "returns the deeper subject (equal by __proxy_id)" do
            result = invoke_memoize_subject
            expect(result.__proxy_id).to eq(proxy2.__proxy_id)
          end
        end
      end

      context "when resolving to a value" do
        let(:to_value) { true }

        context "when the subject is not resolved" do
          it "returns a value" do
            result = invoke_memoize_subject
            expect(Xe::Proxy.proxy?(result)).to be_false
          end

          it "returns the deepest value" do
            result = invoke_memoize_subject
            expect(result).to eq(value2)
          end
        end

        context "when the subject is resolved" do
          before do
            existing_subject.__resolve_subject
          end

          it "returns a value" do
            result = invoke_memoize_subject
            expect(Xe::Proxy.proxy?(result)).to be_false
          end

          it "returns the deepest value" do
            result = invoke_memoize_subject
            expect(result).to eq(value2)
          end
        end
      end
    end

  end

end
