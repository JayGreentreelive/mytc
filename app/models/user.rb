class User
  
  def guest?
    @current.id == Guest::ID
  end
  
  def initialize(id = nil)
    if id
      @current = Person.find(id)
    else
      @current = Guest.find(Guest::ID)
    end
  end
  
  def current
    @current
  end
  
  def method_missing(method, *args, &block)
    @current.send(method, *args, &block)
  end
end