require 'spec_helper'

describe "Xe - Garbage Collection" do

  def context_classes
    @context_classes ||= [
      Xe::Context,
      Xe::Context::Scheduler,
      Xe::Loom::Base,
      Xe::Loom::Fiber,
      Xe::Policy::Base,
      Xe::Enumerator,
      Xe::Enumerator::Impl::Base
    ]
  end

  def expect_collected
    begin
      context_classes.each do |klass|
        expect(klass).to be_collected
      end
    rescue => e
      print_counts
      raise e
    end
  end

  def print_counts
    puts "Context Classes (counts):"
    context_classes.each do |klass|
      objects = ObjectSpace.each_object(klass)
      count = objects.count
      if count > 0
        puts "  #{klass.name}: #{count}"
        objects.each do |obj|
          print_object(obj)
        end
      end
    end
  end

  def print_object(obj)
    p obj
  end

  before do
    GC.start
  end

  after do
    GC.start
    expect_collected
  end

  it "holds no references (count)" do
    Xe.context { Xe.enum([1, 2, 3]).count { |i| i } }
  end

  it "holds no references (map)" do
    Xe.map([1, 2, 3]) { |i| i }
  end

  it "holds no references (map over realizer)" do
    realizer = Xe.realizer { |ids| {1 => 2, 2 => 3, 3 => 4} }
    Xe.map([1, 2, 3]) { |i| realizer[i] }
  end

end
