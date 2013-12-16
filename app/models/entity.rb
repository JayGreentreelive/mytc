class Entity
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Flaggable
  # TODO include Visible
  
  field :name, type: String
  field :avatar, type: String  
  field :visibility, type: Array, default: []
  
end
