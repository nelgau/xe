require 'spec_helper'

describe "Xe - Simple Usage" do

  class MyClass
    attr_reader :id
    attr_reader :foo
    attr_reader :bar

    def initialize
      @id  = Random.rand(100)
      @foo = Random.rand(10)
      @bar = Random.rand(10)
    end
  end

  class VerifiedRealizer < Xe::Realizer
    def self.realize(ids)
      ids.map { |id| "verified #{id}" }
    end
  end

  class MySerializer < ActiveModel::Serializer
    attribute :verified
    attribute :bar

    def verified
      VerifiedRealizer.defer(object.id)
    end

    def bar
      "blerg"
    end
  end

  it "works" do
    a = (0...10).map { MyClass.new }

    result = Xe.context do |c|
      c.enumerator(a).map do |o|
        puts "A"
        MySerializer.new(o).as_json
      end
    end

    p result
  end

end
