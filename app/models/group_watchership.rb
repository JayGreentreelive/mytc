class GroupWatchership < GroupRelationship

  NOTIFICATIONS_ALL = :all
  NOTIFICATIONS_IMPORTANT = :important
  NOTIFICATIONS_NONE = :none
  NOTIFICATIONS_DEFAULT = NOTIFICATIONS_IMPORTANT
  
  field :notifications, type: Symbol, default: NOTIFICATIONS_DEFAULT
  
  validates :notifications, inclusion: { in: [NOTIFICATIONS_ALL, NOTIFICATIONS_IMPORTANT, NOTIFICATIONS_NONE] }
  
end
