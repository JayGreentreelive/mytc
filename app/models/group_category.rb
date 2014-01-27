
# g.events => GroupEventCategory
# g.events.items start: '2014-01-14', end: '2014-01-21' -- deep by default
# g.events.calendars[0].items => [Event]

# g.library => GroupLibraryCategory
# g.library.items -- shallow by default
# g.library.folders[0].folders[3].items 


class GroupCategory
  include Mongoid::Document
  include RandomId
  include Nillable
  include Treeable
  include Sluggable
  
  DEFAULT_NAME = 'New Category'
  
  POSTING_ANYONE = :anyone
  POSTING_MEMBERS  = :members
  POSTING_ADMINS = :admins
  POSTING_INHERIT = :inherit
  
  field :name, type: String, default: -> { self.class::DEFAULT_NAME }
  field :posting, type: Symbol, default: POSTING_MEMBERS
  
  validates :posting, inclusion: { in: [POSTING_ANYONE, POSTING_MEMBERS, POSTING_ADMINS, POSTING_INHERIT] }
  
  normalize_attribute :name, with: [:blank, :squish]
  
  embedded_in :group
  
  def remove
    raise "IMPLEMENT THIS... SOMEDAY"
  end
  
  def posting
    if read_attribute(:posting) == POSTING_INHERIT
      if self.root?
        POSTING_ADMINS
      else
        self.root.posting
      end
    else
      super
    end
  end
end
