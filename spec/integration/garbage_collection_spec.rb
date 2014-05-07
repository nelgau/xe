require 'spec_helper'
require 'fiber'

Xe.configure do |c|
  c.logger = :stdout
end

describe "Xe - Garbage Collection" do

  def context_classes
    @context_classes ||= [
      Xe::Context,
      Xe::Context::Scheduler,
      Xe::Loom::Base,
      Xe::Policy::Base,
      Xe::Enumerator,
      Xe::Enumerator::Impl::Base
    ]
  end

  def expect_collected
    GC.start
    result = yield
    result = nil
    GC.start
    context_classes.each do |klass|
      expect(klass).to be_collected
    end
  rescue
    print_counts
    raise
  end

  def print_counts
    puts "Context Classes (counts):".yellow
    context_classes.each do |klass|
      objects = ObjectSpace.each_object(klass)
      count = objects.count
      if count > 0
        puts "  #{klass.name}: #{count}".yellow.bold
        objects.each do |obj|
          print_object(obj)
        end
      end
    end
  end

  def print_object(obj)
    puts "    #{obj.inspect}".yellow
  end

  it "holds no references (context)" do
    expect_collected do
      Xe.context { }
    end
  end

  # it "holds no references (count)" do
  #   expect_collected do
  #     Xe.context { Xe.enum([1, 2, 3]).count { |i| i } }.to_s
  #   end
  # end

  it "holds no references (map)" do
    expect_collected do
      Xe.map([1, 2, 3]) { |i| i }
    end
  end

  # it "holds no references (map over realizer)" do
  #   expect_collected do
  #     realizer = Xe.realizer { |ids| {1 => 2, 2 => 3, 3 => 4} }
  #     Xe.map([1, 2, 3]) { |i| realizer[i] }.map(&:to_s)
  #   end
  # end

end
