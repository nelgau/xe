require 'fiber'
require 'colored'

module Xe::Test
  module GC
    # Since `GC.start` isn't guaranteed to do a full collection of the entire
    # heap, we run the garbage collector's lazy sweep until we're reasonably
    # sure that no references are still held. If you find that some garbage
    # collection test is failing without any explanation, you should try to
    # crank this up to further exercise the object graph.
    GC_RUNS = 5

    module ClassMethods

      def define_test(options={})
        has_output = options.fetch(:has_output, true)
        it "holds no references" do
          # Invoke the test procedure and immediately discard the result.
          result = invoke
          expect(result).to eq(output) if has_output
          result = nil
        end
      end

    end

    def self.included(base)
      base.extend(ClassMethods)

      base.class_exec do
        after do
          # After each test's block is out of scope, we should expect all
          # instances of context-related classes to be collected.
          expect_gc
        end
      end
    end

    # Store a reference to the root fiber so we can ignore it.
    ROOT_FIBER = ::Fiber.current

    # These are the classes associated with a context and after each operation,
    # none should persist in the heap, even if references to values are held.
    CONTEXT_CLASSES = [
      Xe::Context,
      Xe::Context::Scheduler,
      Xe::Loom::Base,
      Xe::Policy::Base,
      Xe::Enumerator,
      Xe::Enumerator::Impl::Base,
      ::Fiber
    ]

    # These instances are not expected to be garbage collected.
    IGNORED_INSTANCES = [
      ROOT_FIBER
    ]

    def expect_gc(classes=nil)
      classes ||= CONTEXT_CLASSES
      classes   = [classes] unless classes.is_a?(Array)
      instances = {}

      # Release the global interpreter lock once.
      sleep 0.0001

      # Let the garbage collector go hog wild with lazy sweeping.
      GC_RUNS.times do
        ::GC.start
      end

      classes.each do |klass|
        objects = ObjectSpace.each_object(klass).to_a
        objects.reject! { |o| IGNORED_INSTANCES.include?(o) }
        instances[klass] = objects
      end

      instances.each do |klass, objects|
        unless objects.count == 0
          raise "Instances of #{klass.name} are still in the heap!"
        end
      end
    rescue
      Xe::Test::GC.print_instances(instances)
      raise
    end

    def self.print_instances(instances)
      puts "\nInstances in heap:".yellow
      instances.each do |klass, objects|
        count = objects.count
        if count > 0
          puts "  #{klass.name}: #{count}".yellow.bold
          objects.each do |obj|
            puts "    #{obj.inspect}".yellow
          end
        end
      end
      puts ""
    end
  end
end

