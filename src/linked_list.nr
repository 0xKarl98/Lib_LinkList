use dep::std::{self, collections::map::HashMap};
use std::hash::poseidon2::Poseidon2Hasher;

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
struct LinkedList<T,let N:u32>{
    nodes:HashMap<Field, Node<T>, N, Poseidon2Hasher>, //HashMap<Field, Node<T>, N, BuildHasherDefault<Poseidon2Hasher>>,
    head: Option<Field>,
    tail: Option<Field>,
    size: u32,
    next_key: Field,
    free_keys: Vec<Field> 
}


impl<T,let N:u32> LinkedList<T,N>{
    

    pub fn new() -> Self {
        LinkedList {
            nodes: HashMap::<Field, Node<T>, N, Poseidon2Hasher>::with_hasher(Poseidon2Hasher::new()),
            head: Option::none(),
            tail: Option::none(),
            size: 0,
            next_key: 0,
            free_keys: Vec::new(),
            
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
        if front_key.is_none(){
            return None ;
        }

        let key = front_key.unwrap();
        self.deallocate_node(key);
    }

    fn pop_back(&mut self) -> Option<T> {
        let back_key = self.pop_back_node();
        if back_key.is_none(){
            return None;
        }

        let key = back_key.unwrap();
        self.deallocate_node(key);
    }
    
    //Stores the given value into Node and connect key to this node 
    fn allocate_node(&mut self, value: T) -> Field {
        assert(self.size < N, "LinkedList is full");
        
        let node = Node::new(value);
        let key;
      
        if !self.free_keys.is_empty() {
            key = self.free_keys.pop().unwrap();
        } else {
            key = self.next_key;
            self.next_key += 1;
        }

        self.nodes.insert(key, node);
        key
    }

    fn deallocate_node(&mut self, key: Field) -> Option<T> {
       if !self.nodes.contains(key){
            return None;
       }       
       // clear node connections
       {
         let mut node = self.nodes.get(key).unwrap();
         node.next = None ;
         node.prev = None ;
         self.nodes.insert(key,node);
       }

       // get nodes hashmap value 
       let value = self.nodes.get(key).unwrap().value ;

       //Remove node from nodes hashmap and recycle key 
       self.nodes.remove(key);
       self.free_keys.push(key);

       //TODO : do we really need to return value here ?
       Some(value);
    }

    //Adds the given node to the front of the list 
    //Case 1: if the list is empty , this node will be both the head and the tail
    //Case 2: if not , we update both status of new node and original head_node 
    fn push_front_node(&mut self, key: Field){
        
        //ensure the corresponding node does exist
        assert(self.nodes.contains(key), "Node does not exist");

        //update new node status 
        {
            let mut node = self.nodes.get(key).unwrap();
            node.next = self.head;
            node.prev = None;
            self.nodes.insert(key,node);
        }
        //if this list is empty
        //we set this node to be both the head and tail of this list 
        if self.head.is_none() {
            self.head = Some(key);
            self.tail = Some(key);
        } else {
        //if this list is not empty , 
        //we update the pointer prev to the original head node
            let head_key = self.head.unwrap();
            let mut head_node = self.nodes.get(head_key).unwrap();
            head_node.prev = Some(key);
            self.head = Some(key);
            self.nodes.insert(head_key,head_node);
        }

        //both case will increase the list size 
        self.size += 1 ;
        
    
    }

    /// Adds the given node to the back of the list
    /// Case 1: if the list is empty, this node will be both the head and tail
    /// Case 2: if not, we update both the status of new node and original tail_node
    fn push_back_node(&mut self, value: T) {
        // Ensure the corresponding node does exist
        assert(self.nodes.contains(key), "Node does not exist");

        //Update new node status 
        {
            let mut node = self.nodes.get(key).unwrap();
            node.prev = self.tail;
            node.next = None;
            self.nodes.insert(key, node);
        }
        

        // If this list is empty
        // We set this node to be both the head and tail of this list
        if self.tail.is_none() {
            self.head = Some(key);
            self.tail = Some(key);
        } else {
        // If this list is not empty
        // We update the pointer next of the original tail node
            let tail_key = self.tail.unwrap();
            let mut tail_node = self.nodes.get(tail_key).unwrap();
            tail_node.next = Some(key);
            self.tail = Some(key);
            self.nodes.insert(tail_key, tail_node);
        }

        // Both cases will increase the list size
        self.size += 1;
        
    }
    
    //Remove the node at the front of the list 
    // Case 1: if the list is empty , will return None  
    // Case 2: 
    fn pop_front_node(&mut self) -> Option<Field> {
       //if the list is empty , return None 
       if self.head.is_none(){
         return None; 
       }
     
        let (head_key,next_key) = {
            let head_key  =  self.head.unwrap();
            let head_node =  self.nodes.get(head_key).unwrap();
            (head_key,head_node.next)
        }
        
        //If this head_node is the only one in this list 
        //We can continue with it , as the type of head_node is wrapped in Option 
        //Means it will be None in this case 
        self.head = next_key;
       
       //if the list becomes empty after removal 
       //else we update new head_node information 
       if self.head.is_none(){
          self.tail = None;
       } else {
          let new_head_key = self.head.unwrap();
          let mut new_head_node = self.nodes.get(new_head_key).unwrap();
          new_head_node.prev = None;
          self.nodes.insert(new_head_key,new_head_node);
       }

       //after update all those , we decrease the size of list by 1
       self.size -= 1 ;
       //Return the removed node key 
       Some(head_key);
       
    }

    fn pop_back_node(&mut self) -> Option<T> {
        // if the list is empty , return None 
        if self.tail.is_none(){
            return None ;
        }

        // if the tail of list is existed
        // get the tail key and previous node key 
        let (tail_key,prev_key) = {
            let tail_key = self.tail.unwrap();
            let tail_node = self.nodes.get(tail_key).unwrap();
            (tail_key,tail_node.prev)
        };
        
        // after pop out the original tail , the prev_key should be the tail
        self.tail = prev_key ;
        
        // if the list becomes empty after removal , return None 
        // otherwise we update the info of new tail node 
        let new_tail_key  = self.tail.unwrap();
        let mut new_tail_node = self.nodes.get(new_tail_key).unwrap();
        new_tail_node.next = None;
        self.nodes.insert(new_tail_keym,new_tail_node);   
    } 

    // Decrease the list size by 1 
    self.size -= 1 ;
    // Return the removed node key
    Some(tail_key);   
    
}