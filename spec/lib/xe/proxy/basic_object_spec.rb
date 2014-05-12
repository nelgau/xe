require 'spec_helper'

describe Xe::Proxy::BasicObject do
  include Xe::Test::Mock::Proxy

  subject { Xe::Proxy.new(&subject_proc) }

  let(:subject_proc)  { Proc.new { subject_value } }
  let(:subject_value) { new_value_mock(0) }

  def proxy_for_value(x)
    Xe::Proxy.new { x }
  end

  describe '#!' do

    let(:subject_value) { false }

    context "when the proxy's subject is false" do
      let(:subject_value) { false }

      it "is true" do
        expect(!subject).to be_true
      end
    end

    context "when the proxy's subject is true" do
      let(:subject_value) { true }

      it "is false" do
        expect(!subject).to be_false
      end
    end

    context "when the proxy's subject is an object" do
      let(:subject_value) { new_value_mock(0) }

      it "is false" do
        expect(!subject).to be_false
      end
    end

    context "when the proxy's subject is nil" do
      let(:subject_value) { nil }

      it "is true" do
        expect(!subject).to be_true
      end
    end

  end

  describe '#==' do

    context "when comparing against an object" do
      let(:other) { new_value_mock(0) }

      context "when the subject is equal (==) to the other" do
        let(:other) { new_value_mock(0) }

        it "is true" do
          expect(subject == other).to be_true
        end
      end

      context "when the subject isn't equal (==) to the other" do
        let(:other) { new_value_mock(1) }

        it "is false" do
          expect(subject == other).to be_false
        end
      end
    end

    context "when comparing to the proxy" do
      let(:other) { new_value_mock(0) }

      context "when the subject is equal (==) to the other" do
        let(:other) { new_value_mock(0) }

        it "is true" do
          expect(other == subject).to be_true
        end
      end

      context "when the subject isn't equal (==) to the other" do
        let(:other) { new_value_mock(1) }

        it "is false" do
          expect(other == subject).to be_false
        end
      end
    end

    context "when comparing against a proxy" do
      let(:value) { new_value_mock(0) }
      let(:other) { proxy_for_value(value) }

      context "when the subject is equal (==) to the other's subject" do
        let(:value) { new_value_mock(0) }

        it "is true" do
          expect(subject == other).to be_true
        end
      end

      context "when the subject isn't equal (==) to the other's subject" do
        let(:value) { new_value_mock(1) }

        it "is false" do
          expect(subject == other).to be_false
        end
      end
    end

  end

  describe '#!=' do

    context "when comparing against an object" do
      let(:other) { new_value_mock(0) }

      context "when the subject is equal (==) to the other" do
        let(:other) { new_value_mock(0) }

        it "is false" do
          expect(subject != other).to be_false
        end
      end

      context "when the subject isn't equal (==) to the other" do
        let(:other) { new_value_mock(1) }

        it "is true" do
          expect(subject != other).to be_true
        end
      end
    end

    context "when comparing to the proxy" do
      let(:other) { new_value_mock(0) }

      context "when the subject is equal (==) to the other" do
        let(:other) { new_value_mock(0) }

        it "is false" do
          expect(other != subject).to be_false
        end
      end

      context "when the subject isn't equal (==) to the other" do
        let(:other) { new_value_mock(1) }

        it "is true" do
          expect(other != subject).to be_true
        end
      end
    end

    context "when comparing against a proxy" do
      let(:value) { new_value_mock(0) }
      let(:other) { proxy_for_value(value) }

      context "when the subject is equal (==) to the other's subject" do
        let(:value) { new_value_mock(0) }

        it "is false" do
          expect(subject != other).to be_false
        end
      end

      context "when the subject isn't equal (==) to the other's subject" do
        let(:value) { new_value_mock(1) }

        it "is true" do
          expect(subject != other).to be_true
        end
      end
    end

  end

  describe '#eql?' do

    context "when comparing against an object" do
      let(:other) { new_value_mock(0) }

      context "when the subject is equal (==) to the other" do
        let(:other) { new_value_mock(0) }

        it "is true" do
          expect(subject.eql?(other)).to be_true
        end
      end

      context "when the subject isn't equal (==) to the other" do
        let(:other) { new_value_mock(1) }

        it "is false" do
          expect(subject.eql?(other)).to be_false
        end
      end
    end

    context "when comparing to the proxy" do
      let(:other) { new_value_mock(0) }

      context "when the subject is equal (==) to the other" do
        let(:other) { new_value_mock(0) }

        it "is true" do
          expect(other.eql?(subject)).to be_true
        end
      end

      context "when the subject isn't equal (==) to the other" do
        let(:other) { new_value_mock(1) }

        it "is false" do
          expect(other.eql?(subject)).to be_false
        end
      end
    end

    context "when comparing against a proxy" do
      let(:value) { new_value_mock(0) }
      let(:other) { proxy_for_value(value) }

      context "when the subject is equal (==) to the other's subject" do
        let(:value) { new_value_mock(0) }

        it "is true" do
          expect(subject.eql?(other)).to be_true
        end
      end

      context "when the subject isn't equal (==) to the other's subject" do
        let(:value) { new_value_mock(1) }

        it "is false" do
          expect(subject.eql?(other)).to be_false
        end
      end
    end

  end

  describe '#instance_eval' do

    let(:internal)      { 200 }
    let(:subject_value) { new_value_mock(internal) }

    it "delegates to the resolved subject (source string form)" do
      result = subject.instance_eval("@internal")
      expect(result).to eq(internal)
    end

    it "delegates to the resolved subject (block form)" do
      result = subject.instance_eval { @internal }
      expect(result).to eq(internal)
    end

  end

  describe '#instance_exec' do

    let(:internal)      { 201 }
    let(:subject_value) { new_value_mock(internal) }

    it "delegates to the resolved subject" do
      result = subject.instance_exec { @internal }
      expect(result).to eq(internal)
    end

  end

end
