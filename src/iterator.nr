use crate::linked_list::LinkedList;
use crate::node::Node;

struct ListIterator<T,let N:32>{
    list: &LinkedList<T,N>, //the referrenced list that we want to iterate 
    current: Option<Field>,
}


impl<T, let N:u32> ListIterator<T,N>{
    //Constructor function ,begin at head by default 
    fn new(list: &LinkedList<T,N>) -> Self{
        ListIterator{
            list,
            current: list.head, 
        }
    }

    //function to get next element 
    fn next(&mut self) -> Option<&T> {
        if self.current.is_some() {
            let current_key = self.current.unwrap();
            
            // Assert that the node exists in the HashMap
            // even though we already have function is_some() to check the existence 
            assert!(self.list.nodes.contains_key(current_key), "Node does not exist");

            let node = self.list.nodes.get(current_key).unwrap();
            self.current = node.next;
            Some(&node.value)
        } else {
            None
        }
    }
}