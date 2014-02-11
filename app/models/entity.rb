class Entity
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Flaggable
  include Nillable
  
  field :name, type: String
  
  validates :name, presence: true, length: { minimum: 1 }
  
  normalize_attribute :name, with: [:blank, :squish]
end
