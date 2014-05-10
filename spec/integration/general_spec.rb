require 'spec_helper'

describe "Xe - General" do

  it "creates a context" do
    Xe.context {}
  end

  it "forces realization without enumeration" do
    realizer = Xe.realizer(:foo) do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end

    result = Xe.context do
      realizer[1].to_s
    end

    expect(result).to eq('2')
  end

  it "executes a simple map enumeration" do
    result = Xe.map([1, 2, 3]) { |x| x }
    expect(result).to eq([1, 2, 3])
  end

  it "maps using a realizer" do
    realizer = Xe.realizer(:foo) do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end

    result = Xe.context do
      Xe.map([2, 3, 4]) { |x| realizer[x] }
    end
    expect(result).to eq([4, 6, 8])
  end

  it "blocks enumeration fibers on accessing a proxied value" do
    realizer = Xe.realizer(:bar) do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end

    result = Xe.context do
      Xe.map([2, 3, 4]) { |x| realizer[x].to_s }
    end
    expect(result).to eq(['4', '6', '8'])
  end

  it "blocks enumeration fibers on accessing a proxied value" do
    realizer = Xe.realizer(:bar) do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end

    source = [
      [2, 3, 4],
      [2, 5, 6]
    ]

    result = Xe.context do
      Xe.map(source, tag: :enum1) do |arr|
        arr2 = Xe.map(arr, tag: :enum2) { |x| realizer[x] }
        Xe.map(arr2, tag: :enum3) { |x| realizer[x].to_s }
      end
    end

    expect(result).to eq([['8', '12', '16'], ['8', '20', '24']])
  end

end
