use dep::std::{self, collections::map::HashMap};
use std::hash::{poseidon2::Poseidon2Hasher, BuildHasherDefault};

pub struct Node<T>{
    value : T,//value to store in the node 
    prev: Option<Field>, //index of previous node 
    next :Option<Field> //index of next node 
}

impl<T> Node<T> {
    pub fn new(value: T) -> Self {
        Node {
            value,
            prev: Option::none(),
            next: Option::none()
        }
    }
}

/// A doubly-linked list implementation using HashMap for node storage.
/// Supports operations at both ends in constant time.
pub struct LinkedList<T, let L:u32>{
    nodes:HashMap<Field, Node<T>, L, BuildHasherDefault<Poseidon2Hasher>>, 
    head: Option<Field>,
    tail: Option<Field>,
    size: u32,
    next_key: Field,
    free_keys: [Field;L],
    free_keys_count: u32 
}


impl<T,let L:u32> LinkedList<T,L>{
    
    pub fn new_map() -> HashMap<Field, Node<T>, L, BuildHasherDefault<Poseidon2Hasher>> {
        let mut map: HashMap<Field, Node<T>,L, BuildHasherDefault<Poseidon2Hasher>> = HashMap::default();
        map
    }

    pub fn new() -> Self {
        LinkedList {
            nodes: Self::new_map(),
            head: Option::none(),
            tail: Option::none(),
            size: 0,
            next_key: 0,
            free_keys: [0; L],
            free_keys_count: 0,
        }
    }
    
    // Add a value to the front of the list 
    fn push_front(&mut self, value: T){
        let key = self.allocate_node(value);
        self.push_front_node(key);
    }

    /// Add a value to the back of the list
    fn push_back(&mut self, value: T) {
        let key = self.allocate_node(value);
        self.push_back_node(key);
    }

    fn pop_front(&mut self) -> Option<T>{
        let front_key = self.pop_front_node();
        assert(front_key.is_some(), "Expected front_key to be Some, but it was None");

        let key = front_key.unwrap();
        self.deallocate_node(key)
    }

    fn pop_back(&mut self) -> Option<T> {
        let back_key = self.pop_back_node();
        assert(back_key.is_some(), "Expected back_key to be Some, but it was None");
        let key = back_key.unwrap();
        self.deallocate_node(key)
    }
    
    fn allocate_node(&mut self, value: T) -> Field {
        assert(self.size < L, "LinkedList is full");
        
        let node = Node::new(value);
        //Set key to default value in order to prevent no expression error 
        let mut key = 0; 
        
        if self.free_keys_count > 0 {
            self.free_keys_count -= 1;
            key = self.free_keys[self.free_keys_count];
        } else {
            // Otherwise use the next fresh key
            key = self.next_key;
            self.next_key += 1;
        }

        self.nodes.insert(key, node);
        key
    }

    //This function deals with update pointers between nodes 
    fn unlink_node(&mut self, key: Field) {
        assert(self.nodes.contains_key(key), "Node does not exist");
        
        //Get the node to unlink 
        let node = self.nodes.get(key).unwrap();
        let prev_key = node.prev;
        let next_key = node.next;

        //If this node has prev node , we set the prev_node's next to be 
        //this current node's next , and then update the connection info 
        //otherwise , this node is head node ,
        //we should set this node's next to be the head node 
        if prev_key.is_some() {
            let prev = prev_key.unwrap();
            let mut prev_node = self.nodes.get(prev).unwrap();
            prev_node.next = next_key;
            self.nodes.insert(prev, prev_node);
        } else {
            //In this case , we don't need to update the nodes hashmap,
            //as we didn't update the internal status of any node 
            self.head = next_key;
        }

        //If this node has any next node , we set prev_key of this current node 
        //to be the prev of next node , and update connection info of next node 
        //Otherwise , this current node is the tail node of list 
        //We should set the prev node to be the tail node 
        if next_key.is_some() {
            let next = next_key.unwrap();
            let mut next_node = self.nodes.get(next).unwrap();
            next_node.prev = prev_key;
            self.nodes.insert(next, next_node);
        } else {
            // This node is the tail node
            self.tail = prev_key;
        }

        //After update node connections , we need to decrement the list size by 1
        self.size -= 1;

    }

    //This function is mainly for remove the key from nodes hashmap 
    //And return the value stored in the removed node for us 
    fn deallocate_node(&mut self, key: Field) -> Option<T> {     
        assert(self.nodes.contains_key(key), "Node does not exist");
       
        //Unlink the node from the list 
        self.unlink_node(key);

        // Get node's value before removing it
        let value = {
            let node = self.nodes.get(key).unwrap();
            node.value
        };

        // Remove node from nodes hashmap 
        self.nodes.remove(key);

        // Add the key to our free keys list for recycling
        self.free_keys[self.free_keys_count] = key;
        self.free_keys_count += 1;

        Option::some(value)
    }

    //Adds the given node to the front of the list 
    fn push_front_node(&mut self, key: Field){
        
        //ensure the corresponding node does exist
        assert(self.nodes.contains_key(key), "Node does not exist");

        //update new node status 
        {
            let mut node = self.nodes.get(key).unwrap();
            node.next = self.head;
            node.prev = Option::none();
            self.nodes.insert(key,node);
        }
        //if this list is empty
        //we set this node to be both the head and tail of this list 
        if self.head.is_none() {
            self.head = Option::some(key);
            self.tail = Option::some(key);
        } else {
            let old_head_key = self.head.unwrap();
            //update old head key's prev pointer 
            {
                let mut old_head_node =self.nodes.get(old_head_key).unwrap();
                old_head_node.prev = Option::some(key);
                self.nodes.insert(old_head_key,old_head_node);
            }
            //update head pointer to new node key 
            self.head = Option::some(key);
        }

        //both case will increase the list size 
        self.size += 1 ;
    }

    /// Adds the given node to the back of the list
    fn push_back_node(&mut self, key: Field) {
        // Ensure the corresponding node does exist
        assert(self.nodes.contains_key(key), "Node does not exist");

        //Update new node status 
        {
            let mut node = self.nodes.get(key).unwrap();
            node.prev = self.tail;
            node.next = Option::none();
            self.nodes.insert(key, node);
        }
        
        // If this list is empty
        // We set this node to be both the head and tail of this list
        if self.tail.is_none() {
            self.head = Option::some(key);
            self.tail = Option::some(key);
        } else {
        // If this list is not empty
        // We update the pointer next of the original tail node
            let tail_key = self.tail.unwrap();
            let mut tail_node = self.nodes.get(tail_key).unwrap();
            tail_node.next = Option::some(key);
            self.tail = Option::some(key);
            self.nodes.insert(tail_key, tail_node);
        }

        // Both cases will increase the list size
        self.size += 1;
        
    }

     
    //Remove the node at the front of the list and return the key of removed node 
    fn pop_front_node(&mut self) -> Option<Field> {
       //if the list is empty , return None 
       let result = if self.head.is_none(){
            Option::none() 
       }else {
           let head_key = self.head.unwrap();
           Option::some(head_key)
       };
        result
    }

    fn pop_back_node(&mut self) -> Option<Field> {
        // if the list is empty , return None 
        let result = if self.tail.is_none(){
            Option::none()
        } else{
            // Get the tail key that will be returned
            let tail_key = self.tail.unwrap();
            // Return the key of the removed node
            Option::some(tail_key)
        
        };
        result    
    } 


}


#[test]
fn test_linked_list() {
    let mut list: LinkedList<u32, 10> = LinkedList::new();
    assert(list.size == 0, "New list should have size 0");
    assert(list.head.is_none(), "New list should have no head");
    assert(list.tail.is_none(), "New list should have no tail");

    // Test push_front on empty list
    list.push_front(10);
    assert(list.size == 1, "List size should be 1 after push_front");
    assert(list.head.is_some(), "List should have a head after push_front");
    assert(list.tail.is_some(), "List should have a tail after push_front");
    assert(list.head == list.tail, "Head and tail should be the same for single element list");
    
    // Test push_front on non-empty list
    list.push_front(20);
    assert(list.size == 2, "List size should be 2 after second push_front");
    assert(list.head != list.tail, "Head and tail should differ for multi-element list");
    
    // Test push_back
    list.push_back(30);
    assert(list.size == 3, "List size should be 3 after push_back");

    // Test pop_front
    let value = list.pop_front().unwrap();
    assert(value == 20, "pop_front should return 20");
    assert(list.size == 2, "List size should be 2 after pop_front");

    // Pop_front again 
    let value = list.pop_front().unwrap();
    assert(value == 10, "pop_front should return 10");
    assert(list.size == 1, "List size should be 1 after second pop_front");

    // Test push_back
    list.push_back(40);
    assert(list.size == 2, "List size should be 2 after push_back");

    let value = list.pop_back().unwrap();
    assert(value == 40, "pop_back should return 40");
    assert(list.size == 1, "List size should be 1 after pop_back");

    // Test key recycling
    let key_count_before = list.free_keys_count;
    list.pop_back(); // Remove last element
    assert(list.size == 0, "List should be empty after last pop");
    assert(list.free_keys_count > key_count_before, "Free keys count should increase after pop");
    
    // Test reusing freed keys
    list.push_front(50);
    list.push_front(60);
    assert(list.size == 2, "List size should be 2 after pushing to a cleared list");

    // Push 6 more elements to reach capacity of 8
    for i in 0..5 {
        list.push_back(100 + i);
    }
    assert(list.size == 7, "List should have 7 elements");

    // Verify structure by popping everything
    let mut values = [0; 10];
    for i in 0..7 {
        values[i] = list.pop_front().unwrap();
    }
    assert(list.size == 0, "List should be empty after popping all elements");

    list.push_front(1);
    list.push_back(2);
    list.push_front(3);
    list.push_back(4);
    assert(list.size == 4, "List should have 4 elements after mixed operations");
    
    let front = list.pop_front().unwrap();
    let back = list.pop_back().unwrap();
    assert(front == 3, "Front value should be 3");
    assert(back == 4, "Back value should be 4");
    assert(list.size == 2, "List should have 2 elements after mixed pops");

    // Final clear and verify
    list.pop_front();
    list.pop_front();
    assert(list.size == 0, "List should be empty at end");
    assert(list.head.is_none(), "Empty list should have no head");
    assert(list.tail.is_none(), "Empty list should have no tail");
}


#[test]
fn test_key_recycling() {
    let mut list: LinkedList<u32, 10> = LinkedList::new();
    assert(list.next_key == 0, "next_key should start at 0");
    
    // Add and remove some elements to generate freed keys
    list.push_back(10);
    list.push_back(20);
    list.push_back(30);

    assert(list.next_key == 3, "next_key should be 3 after adding 3 elements");
    
    list.pop_front(); // Remove 10
    list.pop_front(); // Remove 20
    
    // Verify state
    assert(list.size == 1, "List should have 1 element left");
    assert(list.free_keys_count == 2, "Should have 2 freed keys");
    assert(list.next_key == 3, "next_key should still be 3");

    // Add new elements, which should reuse freed keys
    list.push_back(40);
    list.push_back(50);
    assert(list.size == 3, "List should have 3 elements");
    assert(list.free_keys_count == 0, "All freed keys should be used");
    assert(list.next_key == 3, "next_key should still be 3");
    
    // Add two more elements - should use next_key values 3 and 4
    list.push_back(60);
    list.push_back(70);
    
    // Verify next_key has advanced again
    assert(list.size == 5, "List should have 5 elements");
    assert(list.next_key == 5, "next_key should be 5 after using keys 3 and 4");
    
    for i in 0..5 {
        list.pop_front();
    }
    
    // Verify state
    assert(list.size == 0, "List should be empty");
    assert(list.free_keys_count == 5, "All 5 keys should be recycled");
    assert(list.next_key == 5, "next_key should remain at 5");

    for i in 0..5 {
        list.push_back(100 + i);
    }
    
    // Verify state
    assert(list.size == 5, "List should have 5 elements");
    assert(list.free_keys_count == 0, "All recycled keys should be used");
    assert(list.next_key == 5, "next_key should still be 5");
    
}