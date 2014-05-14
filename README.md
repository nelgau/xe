Xe: The Batching Lazy Evaluator
==

Xe allows you to reorder expensive operations and efficiently execute them in groups.

```ruby
class UserRealizer < Xe::Realizer::Id
  def perform(ids)
    User.where(:id => ids)
  end
end

> Xe.context { [
    UserRealizer[1],
    UserRealizer[2],
    UserRealizer[3]
  ] }

# User Load (0.2ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` IN (1, 2, 3)
# => [#<User id: 1, ... >, #<User id: 2, ... >, #<User id: 3, ... >]
```

For some perspective, see: http://en.wikipedia.org/wiki/One-electron_universe

### Realizers and Enumerators

Realizers collect related operations and implement an efficient method to compute them in batches.
The nature of grouping and batching is left entirely up to you.
Each group is named by a unique key and you must provide a procedure to load it.
You might decide that no meaningful grouping exists and that's OK.
Not every realizer needs to subdivide its members but some can benefit from the additional flexibility.
Most of the time, you'll interact with Xe by writing new realizers or extending existing ones.

If you request an object from a realizer, it will provide it immediately, at any time.
You can return the object, store it in a data structure or pass it as an argument to a method.
For all intents, this is the object you requested and behaves identically.

Conceptually, realizers act as the barrier between *referencing* and *holding* an object.
When you request an object, it merely schedules the realization at some future time.
When you request an object, Xe drags its feet for as long as possible.
It does this to accumulate large groups of objects to realize at once.
If you attempt to use the object as a value, Xe has another way to procrastinate:
it can suspend the flow of execution to explore other avenues.
When it decides that realizing the object is the best course of action,
control will resume where it left off and you will find yourself holding the object.

Enumerators take this further by *introducing* oportunities to reorder operations.



