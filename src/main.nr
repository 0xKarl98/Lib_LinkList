mod linked_list;
//use dep::std;

use linked_list::LinkedList;

fn main(dummy_input: Field) -> pub Field {

    let mut list: LinkedList<Field, 10> = LinkedList::new();
    list.push_front(100);
    
    dummy_input
}

