A memory-efficient doubly-linked list implementation in Noir, using a HashMap for node storage. This implementation supports constant-time operations at both ends of the list, making it suitable for queue, stack, and deque use cases in Noir applications.

Features
- Constant-time operations: push_front, push_back, pop_front, and pop_back all operate in O(1) time
- Memory efficiency: Uses HashMap for node storage with key recycling
- Type flexibility: Supports generic types through Noir's type system
- Configurable capacity: Maximum size can be specified at compile time

Todos
- [ ]Key recycling mechanism 
- [ ]Nodes splice , detach ,split 
- [ ]Iterator , cursor if needed 