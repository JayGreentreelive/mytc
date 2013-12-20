class GroupRelationship
  include Mongoid::Document
  include Nillable

  # Fields
  field :created_at, type: DateTime, default: -> { Time.zone.now }

  # Associations
  embedded_in :group
  belongs_to :entity  
  belongs_to :created_by, class_name: 'Entity'
  
  # Validations
  validates :entity_id, presence: true
  validates :created_at, presence: true
  validates :created_by_id, presence: true
end
