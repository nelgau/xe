require 'spec_helper'

describe Xe::Loom do

  it "defines a constant for the default loom" do
    expect(Xe::Loom::Default < Xe::Loom::Base).to be_true
  end

end
