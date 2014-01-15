class Group < Entity
  include Mongoid::Timestamps
  
  POSTS_CATEGORY_ID = 'posts'
  EVENTS_CATEGORY_ID = 'events'
  LIBRARY_CATEGORY_ID = 'library'
  
  STATUS_PENDING = :pending
  STATUS_DENIED = :denied
  STATUS_ACTIVE = :active
  STATUS_RETIRED = :retired
  
  KIND_COMMUNITY = :community
  KIND_DEPARTMENT = :department
  KIND_STUDENTORG = :studentorg
  KIND_WORKGROUP = :workgroup
  KIND_INSTITUTIONAL = :institutional
  KIND_INTEREST = :interest
  KIND_LEGACY = :legacy
  
  SHOW_MEMBERS_ANYONE = :anyone
  SHOW_MEMBERS_MEMBERS = :members
  SHOW_MEMBERS_ADMINS = :admins
  
  # Fields
  field :status, type: Symbol, default: STATUS_PENDING
  field :kind, type: Symbol, default: KIND_COMMUNITY
  field :tagline, type: String
  field :description, type: String
  field :analytics_id, type: String
  field :show_members, type: Symbol, default: SHOW_MEMBERS_ANYONE
  
  # Relations
  belongs_to :created_by, class_name: 'Entity'

  # Indexes
    
  # Normalizations
  normalize_attribute :tagline, with: [:blank, :squish]
  normalize_attribute :description, with: [:blank, :whitespace]
  normalize_attribute :analytics_id, with: [:blank, :squish]
  normalize_attribute :moderation_note, with: [:blank, :squish]
  
  # Validations
  validates :status, inclusion: { in: [STATUS_PENDING, STATUS_DENIED, STATUS_ACTIVE, STATUS_RETIRED] }
  validates :kind, inclusion: { in: [KIND_COMMUNITY, KIND_DEPARTMENT, KIND_STUDENTORG, KIND_WORKGROUP, KIND_INSTITUTIONAL, KIND_INTEREST, KIND_LEGACY] }
  validates :tagline, allow_nil: true, presence: true
  validates :description, allow_nil: true, presence: true
  validates :analytics_id, allow_nil: true, presence: true
  validates :show_members, inclusion: { in: [SHOW_MEMBERS_ANYONE, SHOW_MEMBERS_MEMBERS, SHOW_MEMBERS_ADMINS] }
  validate :_validate_show_members
  
  # Callbacks
  after_initialize :_setup_new_group
  
  #####
  # Class Methods
  
  #####
  # Instance Methods
  
  
  #############
  # MEMBERS / FOLLOWERS / INVITEES / WATCHERS
  #
  # g.memberships.entity_ids
  # g.memberships.entities
  # g.memberships.entity(ent)
  # g.memberships.has_entity?(ent)
  # g.memberships(admin: true).entities
  # g.memberships(locked: true).entities
  # g.memberships.add(entity, options)
  # g.memberships.remove(id)
  #
  # g.followerships.where_level(:important).entities
  
  embeds_many :group_relationships
  
  def memberships(options = {})
    GroupMembershipCollection.new(self, options)
  end

  def followerships(options = {})
    GroupFollowershipCollection.new(self, options)
  end
  
  def invitations(options = {})
    GroupInvitationCollection.new(self, options)
  end
  
  def watcherships(options = {})
    GroupWatchershipCollection.new(self, options)
  end
  
  
  
  #############
  # CATEGORIES / EVENTS / LIBRARY
  #
  embeds_many :group_categories
  
  def posts
    self.group_categories.type(GroupPostCategory).find(POSTS_CATEGORY_ID)
  end
  
  def events
    self.group_categories.type(GroupEventCategory).find(EVENTS_CATEGORY_ID)
  end
  
  def library
    self.group_categories.type(GroupLibraryCategory).find(LIBRARY_CATEGORY_ID)
  end
  

  private
  
  def _validate_show_members
    # if group.public?
  end
  
  def _setup_new_group
    if self.new_record?
      # create default categories
      posts = self.group_categories.build({id: POSTS_CATEGORY_ID, name: 'Posts'}, GroupPostCategory)
      events = self.group_categories.build({id: EVENTS_CATEGORY_ID, name: 'Events'}, GroupEventCategory)
      library = self.group_categories.build({id: LIBRARY_CATEGORY_ID, name: 'Library'}, GroupLibraryCategory)
    end
  end
end
