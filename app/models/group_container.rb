class GroupContainer
  include Mongoid::Document
  include RandomId
  include Nillable
  include Sluggable
  
  POSTING_ANYONE = :anyone
  POSTING_MEMBERS  = :members
  POSTING_ADMINS = :admins
  
  field :name, type: String
  field :posting, type: Symbol
  
  validates :name, presence: true
  validates :posting, inclusion: { in: [POSTING_ANYONE, POSTING_MEMBERS, POSTING_ADMINS] }
  
  normalize_attribute :name, with: [:blank, :squish]
  
  embedded_in :group
end