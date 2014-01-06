class Posting
  include Mongoid::Document
  embedded_in :node
  
  belongs_to :target, class_name: 'Entity'
  belongs_to :by, class_name: 'Entity'
  
  field :category_id, type: String
  field :at, type: DateTime, default: -> { Time.zone.now }
  
  validates :target, presence: true
  validates :by, presence: true
  
end
