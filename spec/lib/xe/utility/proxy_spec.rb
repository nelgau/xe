require 'spec_helper'

describe Xe::Proxy do

  subject { Xe::Proxy.new(&subject_proc) }

  let(:proxied_value) { 2 }
  let(:subject_proc)  { Proc.new { proxied_value } }

  describe '.proxy?' do

    let(:object) { nil }

    context "when the object is a proxy" do
      let(:object) { subject }

      it "is true" do
        expect(Xe::Proxy.proxy?(object)).to be_true
      end
    end

    context "when the object is not a proxy" do
      let(:object) { Object.new }

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
        expect(result).to eq(proxied_value)
      end
    end

    context "when the object is a proxy of a proxy" do
      let(:proxy)  { Xe::Proxy.new { subject } }
      let(:object) { proxy }

      it "is a non-proxy object" do
        result = Xe::Proxy.resolve(object)
        expect(Xe::Proxy.proxy?(result)).to be_false
      end

      it "is the proxied value" do
        result = Xe::Proxy.resolve(object)
        expect(result).to eq(proxied_value)
      end
    end

    context "when the object is not a proxy" do
      let(:object) { Object.new }

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

  describe '#initalize' do

  end

  describe '#__subject_proc' do

  end

  describe '#__subject' do

  end

  describe '#==' do

  end

  describe '#method_missing' do

  end

  describe '#__set_subject' do

  end

  describe '#__resolve' do

  end

  describe '#__xe_proxy?' do

  end

  describe '#__subject?' do

  end


end
