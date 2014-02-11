class Group < Entity
  include Mongoid::Timestamps
  
  #POSTS_CATEGORY_ID = 'posts'
  #EVENTS_CATEGORY_ID = 'events'
  #LIBRARY_CATEGORY_ID = 'library'
  
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
  
  ACCESS_PRIVATE = :private
  ACCESS_PUBLIC = :public
  
  SHOW_MEMBERS_ANYONE = :anyone
  SHOW_MEMBERS_MEMBERS = :members
  SHOW_MEMBERS_ADMINS = :admins
  
  # Fields
  field :status, type: Symbol, default: STATUS_PENDING
  field :kind, type: Symbol, default: KIND_COMMUNITY
  field :access, type: Symbol, default: ACCESS_PRIVATE
  field :tagline, type: String
  field :description, type: String
  field :analytics_id, type: String
  field :show_members, type: Symbol, default: SHOW_MEMBERS_ANYONE
  
  field :avatar_url, type: String
  field :header_url, type: String
  
  field :sorted_name, type: String
  
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
  validates :access, inclusion: { in: [ACCESS_PUBLIC, ACCESS_PRIVATE] }
  validates :tagline, allow_nil: true, presence: true
  validates :description, allow_nil: true, presence: true
  validates :analytics_id, allow_nil: true, presence: true
  validates :show_members, inclusion: { in: [SHOW_MEMBERS_ANYONE, SHOW_MEMBERS_MEMBERS, SHOW_MEMBERS_ADMINS] }
  validate :_validate_show_members
  
  validates :slugs, array: { exclusion: { in: %w(new search directory) } }  
  
  # Callbacks
  after_initialize :_setup_new_group
  before_save :_set_sorted_name
  
  #####
  # Class Methods
  
  #####
  # Instance Methods
  def to_param
    self.slug
  end
  
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
  
  def memberships
    GroupMembershipCollection.new(self)
  end

  def followerships
    GroupFollowershipCollection.new(self)
  end
  
  def invitations
    GroupInvitationCollection.new(self)
  end
  
  def watcherships
    GroupWatchershipCollection.new(self)
  end

  
  #############
  # CATEGORIES / EVENTS / LIBRARY
  #
  field :category_order, type: Array, default: []
  #validate :_validate_post_category_order
  #before_validation :_ensure_post_category_order
  embeds_many :group_containers, cascade_callbacks: true
  validate :_validate_containers
  validates_associated :group_containers
  
  def posts
    @_post_list ||= PostList.new.group(self)
  end
  
  def categories
    GroupCategoryCollection.new(self)
  end
  
  #def events
  #  GroupEventCollection.new(self)
  #end
  
  #def calendars
  #  GroupCalendarCollection.new(self)
  #end
  
  #def library
  #  self.group_containers.type(GroupFolder).find(LIBRARY_CONTAINER_ID)
  #end

  private
  
  def _validate_show_members
    # if group.public?
  end
  
  def _set_sorted_name
    self.sorted_name = ActiveSupport::Inflector.parameterize("#{ActiveSupport::Inflector.transliterate(self.name).downcase}", '').gsub(/[^a-z0-9]/i, '').concat("-#{self.id}")
  end
  
  def _setup_new_group
    if self.new_record?
      # create default categories
      default_category = self.categories.add('Posts')
      #events = self.group_categories.build({id: EVENTS_CATEGORY_ID, name: 'Events'}, GroupEventCategory)
      #library = self.group_categories.build({id: LIBRARY_CONTAINER_ID, name: 'Library'}, GroupLibraryCategory)
    end
  end
  
  def _validate_containers
    if self.categories.length < 1
      errors.add_to_base("Must have at least one category #{self.slugs}")
    end
    #if self.calendars.length < 1
    #  errors.add(:categories, 'Must have at least one category')
    #end
    #if !self.library
    #  errors.add(:library, 'Must have a root library folder')
    #end
  end
end
