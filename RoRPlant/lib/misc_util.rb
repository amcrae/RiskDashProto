class ToDoList
  attr_reader :todo, :done
  
  def initialize(todolist)
    @todo = [] # ensure copy
    @todo += todolist
    @done = []
  end

  def complete_item(item)
    @todo.slice!(@todo.index(item))
    @done.append(item)
  end

end
