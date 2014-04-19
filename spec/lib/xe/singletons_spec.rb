require 'spec_helper'

describe Xe::Singletons do

  # It is an extension of the real subject.
  subject { Xe }

  describe '#config' do

    it "is an instance of Xe::Configuration" do
      expect(subject.config).to be_an_instance_of(Xe::Configuration)
    end

  end

end
