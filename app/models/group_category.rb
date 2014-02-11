class GroupCategory < GroupContainer
  FORMAT_LIST = :list
  FORMAT_BLOG = :blog
  FORMAT_FORUM = :forum
  FORMAT_GALLERY = :gallery
  
  field :format, type: Symbol, default: FORMAT_LIST
  
  validates :format, inclusion: { in: [FORMAT_LIST, FORMAT_BLOG, FORMAT_FORUM, FORMAT_GALLERY] }
  
  def posts
    self.group.posts.category(self)
  end
end
