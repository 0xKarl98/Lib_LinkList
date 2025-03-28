# Lib_LinkList

A memory-efficient doubly-linked list implementation in Noir, using a HashMap for node storage. This implementation supports constant-time operations at both ends of the list, making it suitable for queue, stack, and deque use cases in Noir applications.

## Features

- **Constant-time operations**: `push_front`, `push_back`, `pop_front`, and `pop_back` all operate in O(1) time
- **Memory efficiency**: Uses HashMap for node storage with key recycling
- **Type flexibility**: Supports generic types through Noir's type system
- **Configurable capacity**: Maximum size can be specified at compile time

## Installation

Add the library to your Noir project by specifying it as a dependency in your `Nargo.toml` file:

```toml
[dependencies]
libLinkedList = { git = "https://github.com/0xKarl98/Lib_LinkList" }
```

## Usage
Here's a basic example of how to use the LinkedList:
use libLinkedList::linked_list::{LinkedList, Node};
```
fn main() {
    // Create a new LinkedList with a maximum capacity of 10 elements
    let mut list = LinkedList::<Field, 10>::new();
    
    // Add elements to the list
    list.push_back(1);
    list.push_back(2);
    list.push_front(0);
    
    // Remove elements from the list
    let first = list.pop_front(); // returns Option::some(0)
    let last = list.pop_back();   // returns Option::some(2)
    
    // Clear the list
    list.clear();
}
```

## Limitations
- The maximum size of the list must be specified at compile time
- Currently does not support iteration over elements

## Future Enhancements
- [ ] Implement node splice, detach, and split operations
- [ ] Add iterator and cursor functionality if needed
