class Group < Entity
  include Mongoid::Timestamps
  
  GROUP_KINDS = ['department', 'studentorg', 'workgroup', 'institutional', 'community']
  
  # Fields
  field :kind, type: String
  field :tagline, type: String
  field :description, type: String
  field :analytics_id, type: String  
  
  # Relations

  # Indexes
  
  # Callbacks
  after_initialize :setup_new_group
  
  # Normalizations
  normalize_attribute :tagline, with: [:blank, :squish]
  normalize_attribute :description, with: [:blank, :whitespace]
  normalize_attribute :analytics_id, with: [:blank, :squish]
  
  # Validations
  validates :kind, inclusion: { in: GROUP_KINDS }
  validates :tagline, allow_nil: true, presence: true
  validates :description, allow_nil: true, presence: true
  validates :analytics_id, allow_nil: true, presence: true
  
  #####
  # Class Methods
  
  #####
  # Instance Methods
  
  # g.memberships.add
  # g.memberships.entities
  # g.memberships.find_by_entity(e)
  # g.followerships.add
  # g.followerships.entities
  # g.watcher_ids(level = :important)
  
  # Group categories
  embeds_many :group_categories
  
  def posts
    self.group_categories.type(GroupPostCategory).find('posts')
  end
  #
  # g.posts => GroupPostCategory
  # g.posts.categories => [GroupPostCategory]
  # g.posts.categories.find_by_id(id) => GroupPostCategory
  # g.posts.categories.add(name: 'News', format: 'blog') => GroupPostCategory
  # g.posts.categories.add(name: 'Discussions', format: 'forum')
  # g.posts.categories.add(name: 'Media', format: 'gallery')
  # g.posts.categories.remove(category: cat, orphans: :parent|:delete|new_cat) => GroupPostCategory
  # g.posts.items(page: 1, page_size: 10, deep: true) => [Post] -- deep by default
  # g.posts.items.add(item: Node, by: System, at: Time.zone.now) -> Node.add_posting(group, category, by, at)
  # g.posts.items.remove(item: Node)
  # GroupPostCategories move child nodes to their parent by default
  # All Posts == g.posts.items(deep: true)
  # Uncategorized Posts == g.posts.items(deep: false)
  
  # g.posts.categories => [GroupPostCategory]
  # g.posts.categories[1].items => [Post]
  
  # g.events => GroupEventCategory
  # g.events.items start: '2014-01-14', end: '2014-01-21' -- deep by default
  # g.events.calendars[0].items => [Event]
  
  # g.library => GroupLibraryCategory
  # g.library.items -- shallow by default
  # g.library.folders[0].folders[3].items 
  
  
  
  
  
  

  private
  
  def setup_new_group
    if self.new_record?
      # create default categories
      # posts = self.group_categories.build({id: 'posts', name: 'Posts'}, GroupPostCategory)
      # events = self.group_categories.build({id: 'events', name: 'Events'}, GroupEventCategory)
      # library = self.group_categories.build({id: 'library', name: 'Library'}, GroupLibraryCategory)
    end
  end
end
