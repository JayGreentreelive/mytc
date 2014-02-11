class Node
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Flaggable
  include Treeable
  
  field :access, type: Symbol, default: :public
  
  embeds_many :postings
  
end
