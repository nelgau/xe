require 'spec_helper'

describe Xe::Proxy::Identification do

  subject { Xe::Proxy::Identification }

  describe '#__proxy_id' do

    let(:includee_klass) do
      Class.new do
        include Xe::Proxy::Identification
      end
    end

    let(:includee_instance) do
      includee_klass.new
    end

    it "is a Fixnum" do
      expect(includee_instance.__proxy_id).to be_an_instance_of(Fixnum)
    end

    it "is non-negative" do
      expect(includee_instance.__proxy_id).to be >= 0
    end

    it "is equal accross invocations" do
      id1 = includee_instance.__proxy_id
      id2 = includee_instance.__proxy_id
      expect(id1).to eq(id2)
    end

    context "when called on a distinct instance" do
      let(:includee_instance2) do
        includee_klass.new
      end

      it "is a distinst identifier" do
        id1 = includee_instance.__proxy_id
        id2 = includee_instance2.__proxy_id
        expect(id1).to_not eq(id2)
      end
    end

  end

  describe '.__next_id' do

    it "is a Fixnum" do
      expect(subject.__next_id).to be_an_instance_of(Fixnum)
    end

    it "is non-negative" do
      expect(subject.__next_id).to be >= 0
    end

    it "is a monotonically-increasing sequence" do
      results = (0..5).map { subject.__next_id }
      min, max = results.min, results.max
      expect(results).to match_array((min..max).to_a)
    end

  end

end
