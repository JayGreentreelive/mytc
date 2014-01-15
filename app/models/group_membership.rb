class GroupMembership < GroupWatchership
  
  field :title, type: String
  field :email, type: String
  field :admin, type: Boolean
  field :officer, type: Boolean
  field :locked, type: Boolean

  normalize_attribute :title, with: [:blank, :squish]
  normalize_attribute :email, with: [:blank, :squish]
  normalize_attribute :admin, with: :true_or_nil
  normalize_attribute :officer, with: :true_or_nil
  normalize_attribute :locked, with: :true_or_nil

  validates :title, allow_nil: true, length: { minimum: 1 }
  validates :email, allow_nil: true, format: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates :admin, allow_nil: true, inclusion: { in: [true] }
  validates :officer, allow_nil: true, inclusion: { in: [true] }
  validates :locked, allow_nil: true, inclusion: { in: [true] }
  
end
