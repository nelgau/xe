require 'spec_helper'

describe Xe::Configuration do

  describe '#enabled' do

    it "defaults to true" do
      expect(subject.enabled).to be_true
    end

  end

  describe '#max_fibers' do

    it "is not nil" do
      expect(subject.max_fibers).to_not be_nil
    end

  end

  describe '#logger' do

    it "defaults to nil" do
      expect(subject.logger).to be_nil
    end

  end

  describe '#context_options' do

    it "is a hash" do
      expect(subject.context_options).to be_an_instance_of(Hash)
    end

    it "contains :enabled" do
      expect(subject.context_options.has_key?(:enabled)).to_not be_nil
    end

    it "contains :max_fibers" do
      expect(subject.context_options.has_key?(:max_fibers)).to_not be_nil
    end

    it "contains :logger" do
      expect(subject.context_options.has_key?(:logger)).to_not be_nil
    end

  end

end
