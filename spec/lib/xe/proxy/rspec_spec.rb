require 'spec_helper'

describe Xe::Proxy do
  include Xe::Test::Mock::Proxy

  subject { Xe::Proxy.new(&subject_proc) }

  let(:subject_proc)  { Proc.new { subject_value } }
  let(:subject_value) { new_value_mock(0) }

  describe 'expectation' do

    it "permits matching by equality (eq)" do
      expect(subject).to eq(subject)
    end

    it "permits matching by equality (eql)" do
      expect(subject).to eql(subject)
    end

  end

  describe 'mocking' do

    it "permits stubbing" do
      subject.stub(:baz) { 100 }
      expect(subject.baz).to eq(100)
    end

    it "permits positive invocation expectations" do
      expect(subject).to receive(:bloop).with(1, 2, 3)
      subject.bloop(1, 2, 3)
    end

    it "permits negative invocation expectations" do
      expect(subject).to_not receive(:gloop)
    end

  end

end
