class Favorite
  include Mongoid::Document
  
  field :name, type: String
  field :url, type: String
  field :used_at, type: DateTime
  field :uses, type: Integer, default: 0
  #field :position, type: Integer
  
  embedded_in :person
end
