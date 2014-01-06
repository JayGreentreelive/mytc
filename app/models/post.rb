class Post < Node
  
    include Treeable
  
  field :title, type: String
  field :body, type: String
  
  def self.treetest
    freeman = self.create title: 'Freeman'
    
    jack = self.create title: 'Jack', parent: freeman    
    john = self.create title: 'John', parent: jack    
    jesse = self.create title: 'Jesse', parent: jack
  end
  
  
end
