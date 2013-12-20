class Group < Entity
  include Mongoid::Timestamps
  
  # Fields
  field :tagline, type: String
  field :description, type: String
  field :analytics_id, type: String  
  
  # Relations
  embeds_many :group_relationships

  # Indexes
  index({ "group_relationships.entity_id" => 1 }, { sparse: true })  
  
  # Callbacks
  
  # Normalizations
  normalize_attribute :tagline, with: [:blank, :squish]
  normalize_attribute :description, with: [:blank, :whitespace]
  normalize_attribute :analytics_id, with: [:blank, :squish]
  
  # Validations
  validates :tagline, allow_nil: true, presence: true
  validates :description, allow_nil: true, presence: true
  validates :analytics_id, allow_nil: true, presence: true
  validates_associated :group_relationships
  
  #####
  # Class Methods
  
  
  # private
#   
#   def normalize_attributes
#     super
#     self.tagline = nil if tagline.blank?
#     self.description = nil if description.blank?
#     self.description = nil if description.blank?
#   end
  
end
