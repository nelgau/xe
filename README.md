Xe: The Batching Lazy Evaluator
==

Xe allows you to reorder expensive operations and efficiently execute them in groups.

```
> plus_one = Xe.realizer { |ids| ids.map { |i| i + 1 } }
> Xe.map([1, 2, 3]) { |i| plus_one[i] }
# => [2, 3, 4]
```

http://en.wikipedia.org/wiki/One-electron_universe

### Realizers and Enumerators

Realizers collect related operations and implement an efficient method to compute them in batches.
Most of the time, you'll interact with Xe by writing new realizers or extending existing ones.
The nature of grouping and batching is left entirely up to you.
Each group is named by a unique key and you must provide a procedure to load it.
You might decide that no meaningful grouping exists and that's OK.
Not every realizer needs to subdivide its members but some can benefit from the additional flexibility.

If you request an object from a realizer, it will immediately provide it, at any time.
You may return the object, store it in a data structure or pass it as an argument to a method.
For all intents, this is the object you requested and it behaves identically.

But in reality, realizers act as a barrier between 'referencing' and 'holding' an object.
Requesting an object from a realizer merely schedules it to be loaded at some future time.
When you request an object, Xe drags its feet.
It does this to accumulate large groups of objects to realize at once.
If you attempt to use the object as a value, Xe has another way to procrastinate:
it can suspend the flow of execution to explore other avenues.
When it decides that realizing the object is the best course of action,
control will resume where it left off and you will find yourself holding the object.

Enumerators introduce oportunities to reorder operations.



