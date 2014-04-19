require 'spec_helper'

describe Xe::Proxy::BasicObject do
  include Xe::Test::Mock::Proxy

  subject { Xe::Proxy.new(&subject_proc) }

  let(:subject_proc)  { Proc.new { subject_value } }
  let(:subject_value) { new_value_mock(0) }

  def proxy_for_value(x)
    Xe::Proxy.new { x }
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

end
