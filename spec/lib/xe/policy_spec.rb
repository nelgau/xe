require 'spec_helper'

describe Xe::Policy do

  it "defines a constant for the default policy" do
    expect(Xe::Policy::Default < Xe::Policy::Base).to be_true
  end

end
