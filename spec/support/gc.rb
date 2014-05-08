require 'fiber'
require 'colored'

module Xe::Test
  module GC
    # Store a reference to the root fiber so we can ignore it.
    ROOT_FIBER = Fiber.current

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

      ::GC.start

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

