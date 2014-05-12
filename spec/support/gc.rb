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

    # In Ruby 1.9.3-p448, the interpreter will hold a reference to the last
    # fiber that yielded control. This is always at most one fiber. In these
    # specs, we jiggle the handle by default by resuming a new fiber. If you'd
    # like to track what's retained by that fiber, disable this option. At
    # most, this should be an empty context.
    RESUME_FIBER = true

    # These are the classes associated with a context and after each operation,
    # none should persist in the heap, even if references to proxies are held.
    CONTEXT_CLASSES = [
      Xe::Context,
      Xe::Context::Scheduler,
      Xe::Policy::Base,
      Xe::Loom::Base,
      Xe::Loom::Fiber,
      Xe::Enumerator,
      Xe::Enumerator::Strategy::Base,
      Xe::Event,
      Xe::Target
    ]

    # Store a reference to the root fiber so we can ignore it.
    ROOT_FIBER = ::Fiber.current

    # These instances are not expected to be garbage collected.
    IGNORED_INSTANCES = [
      ROOT_FIBER
    ]

    # This exception is thrown and caught by the specs. It would be unwise to
    # rescue from a very general exception like StandardError as this would
    # hide obvious flaws in the code.
    class Error < Xe::Test::Error; end

    module ClassMethods
      # Add a test for garbage collection that calls the `invoke` method. By
      # default, it expects an accessor in the current scope called `output`
      # against which the return value of `invoke` will be compared. You can
      # disable this behavior by passing :has_output => false.
      def define_test!(options={})

        class_exec do
          def gc_spec_wrapper(options)
            has_output = options.fetch(:has_output, true)

            # Invoke the test procedure and store the result (maybe a proxy).
            @result = invoke

            # If the test specified an output, test it now.
            expect(@result).to eq(output) if has_output
          end
        end

        name = options[:name] || "holds no references"
        it name do
          gc_spec_wrapper(options)
        end
      end

      # Add a test for garbage collection that calls the `invoke` method and
      # expects an Xe::Test::GC::Error exception to be thrown within the test.
      # As a convenience, you can use the `

      def define_test_with_exception!

        class_exec do
          def gc_spec_wrapper
            invoke; nil
          end
        end

        it "to raise and hold no references" do
          _expect_gc!
          did_raise = false
          begin
            gc_spec_wrapper
          rescue Xe::Test::GC::Error
            did_raise = true
          end
          expect(did_raise).to be_true
        end
      end

    end

    module InstanceMethods
      # Raises an exception expected by `define_test_with_exception!`
      def raise_exception
        raise Xe::Test::GC::Error
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, PrivateMethods)

      # Because the test itself may retain referenes to objects within it --
      # it executes within an instance_exec'd block, after all -- we want to
      # check for a prestine heap AFTER the test has finished running and any
      # references to the objects in its scope have been dropped.
      base.class_exec do
        after do
          # After each test's block is out of scope, we should expect all
          # instances of context-related classes to be collected.
          Xe::Test::GC.verify_gc if _expect_gc?
        end
      end
    end

    module PrivateMethods
      # Enable garbage collection verification once the test completes.
      def _expect_gc!
        @expect_gc = true
      end

      # Is garbage collection verification enabled?
      def _expect_gc?
        !!@expect_gc
      end
    end

    # Verify that all references to the classes used by contexts, realizers,
    # and enumerators (that are not meant to persist) have been appropriately
    # reaped by the garbage collector.
    def self.verify_gc(classes=nil)
      # Workarounds for references stored within the interpreter itself.
      release_interpreter_lock
      clear_last_fiber if RESUME_FIBER

      # Let the garbage collector go hog wild with lazy sweeping.
      GC_RUNS.times do
        ::GC.start
      end

      # Find any remaining instances of interesting classes and raise an
      # exception if any remain after collection.
      instances = find_instances(classes)
      instances.each do |klass, objects|
        raise "Instances of #{klass.name} in the heap!" if !objects.empty?
      end
    rescue => e
      # Print the status of the heap before returning.
      print_instances(instances)
      raise e
    end

    # Release the global interpreter lock once by sleeping the current
    # thread. As long as the lock is held, MRI may hold references to the
    # current scope that will never be collected until we completely run
    # out of heap.
    def self.release_interpreter_lock
      sleep 0.001
    end

    # The last fiber that yielded control back to the current fiber has a
    # special status. It isn't immediately garbage collected under certain
    # circumstances (related to raising exceptions). Clear this out in a new
    # isolated scope by resuming a new fiber that doesn't raise.
    def self.clear_last_fiber
      fiber = ::Fiber.new {}
      fiber.resume
    end

    # Retrieve a hash mapping context classes to arrays of instances. Some
    # objects, like the root fiber, are ignored.
    def self.find_instances(classes=nil)
      classes ||= CONTEXT_CLASSES
      classes   = [classes] unless classes.is_a?(Array)

      classes.each_with_object({}) do |klass, instances|
        objects = ObjectSpace.each_object(klass).to_a
        objects.reject! { |o| IGNORED_INSTANCES.include?(o) }
        instances[klass] = objects
      end
    end

    # Beautifully renders the garbage left in the heap by class and count,
    # including the inspection string of each instance.
    def self.print_instances(instances)
      puts "\nInstances in heap:".yellow
      instances.each do |klass, objects|
        count = objects.count
        if count > 0
          puts "  #{klass.name}: #{count}".yellow.bold
          objects.each do |obj|
            puts "    #{obj.inspect} (id=#{obj.__id__})".yellow
          end
        end
      end
      puts ""
    end
  end
end
