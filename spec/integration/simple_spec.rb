require 'spec_helper'

describe "Xe - Simple Usage" do

  it "creates a context" do
    Xe.context {}
  end

  it "executes a simple map enumeration" do
    result = Xe.map([1, 2, 3]) { |x| x }
    expect(result).to eql([1, 2, 3])
  end

  it "maps using a realizer" do
    realizer = Xe.realizer(:foo) do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end

    result = Xe.context(:logger => :stdout) do
      Xe.map([2, 3, 4]) { |x| realizer[x] }
    end
    expect(result).to eql([4, 6, 8])
  end

  it "blocks enumeration fibers on accessing a proxied value" do
    realizer = Xe.realizer(:bar) do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end

    result = Xe.context(:logger => :stdout) do
      Xe.map([2, 3, 4]) { |x| realizer[x].to_s }
    end
    expect(result).to eql(['4', '6', '8'])
  end

end
