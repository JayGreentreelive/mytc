class Post < Node
  
  field :title, type: String
  field :tagline, type: String
  field :body, type: String
  field :tags, type: Array, default: []
  
  belongs_to :owner, class_name: 'Entity'
  belongs_to :author, class_name: 'Entity'
  
end
