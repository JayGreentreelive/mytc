class Entity
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Flaggable
  include Visible
  include Nillable
  
  field :name, type: String

  # Callbacks
  
  validates :name, presence: true, length: { minimum: 1 }
  #field :avatar, type: String
  
  normalize_attribute :name, with: [:blank, :squish]
  
  private

  
end
