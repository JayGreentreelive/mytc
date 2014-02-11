class PersonFavorite
  include Mongoid::Document
  include Nillable
  
  field :name, type: String
  field :url, type: String
  field :used_at, type: DateTime
  field :uses, type: Integer, default: 0
  
  normalize_attribute :name, with: [:blank, :squish]
  normalize_attribute :url, with: [:blank, :squish]
  
  embedded_in :person
end
