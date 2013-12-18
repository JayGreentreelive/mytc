class Entity
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Flaggable
  include Visible
  
  field :name, type: String
  
  validates :first_name, presence: true, length: { minimum: 1 }
  #field :avatar, type: String  
  
  
end
