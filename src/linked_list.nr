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
        
        let key = self.next_key;
        self.next_key += 1;
        
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

        Option::some(value)
    }

    //Adds the given node to the front of the list 
    //Case 1: if the list is empty , this node will be both the head and the tail
    //Case 2: if not , we update both status of new node and original head_node 
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
    /// Case 1: if the list is empty, this node will be both the head and tail
    /// Case 2: if not, we update both the status of new node and original tail_node
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
    
    //Remove the node at the front of the list 
    //Return the key of removed node 
    fn pop_front_node(&mut self) -> Option<Field> {
       //if the list is empty , return None 
       let result = if self.head.is_none(){
            Option::none() 
       }else {
           let head_key = self.head.unwrap();
           self.unlink_node(head_key);
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
            // Unlink the tail node
            self.unlink_node(tail_key);
            // Return the key of the removed node
            Option::some(tail_key)
        
        };
        result    
    } 

    
    
}


#[test]
pub fn test_linked_list() {
    let mut list: LinkedList<u32, 10> = LinkedList::new();

    // Test push_front
    list.push_front(1);
    assert(list.size == 1, "Size should be 1 after one push_front operations");
    list.push_front(2);
    // assert(list.size == 2, "Size should be 2 after one push_front operations");
    
    assert(list.head.is_some(), "Head should not be None");
    assert(list.tail.is_some(), "Tail should not be None");

    // Test push_back
    list.push_back(3);
    assert(list.size == 3, "Size should be 3 after push_back operation");

    // Test pop_front
    let front = list.pop_front();
    assert( front.unwrap() == 2, "pop_front should return 2");
    assert(list.size == 2, "Size should be 2 after pop_front operation");

    // Test pop_back
    let back = list.pop_back();
    assert(back.is_some() , "pop_back should return 3");
    assert(back.unwrap() == 3);
    assert(list.size == 1, "Size should be 1 after pop_back operation");

    // Test pop_front on single-element list
    let front = list.pop_front();
    assert(front.is_some() , "pop_front should return something");
    assert(front.unwrap() == 1,"pop_front should return 1");
    assert(list.size == 0, "Size should be 0 after popping all elements");

    println("All tests passed!");
}