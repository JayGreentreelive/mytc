module Sluggable
  extend ActiveSupport::Concern

  included do
    field :slugs, type: Array, default: []
    field :display_slug, type: String
    
    index({ slugs: 1, _type: 1 }, { unique: true, sparse: true })

    validate :validate_slugs
    before_create :ensure_id_in_slugs
  end

  # Class Methods
  module ClassMethods
    def get(sl)
      self.find_by_slug(sl)
    end

    def find_by_slug(sl)
      sl = Utils::Slugger.slugify(sl)
      self.in(slugs: sl).first
    end
  end

  # Instance Methods
  def slug
    self.display_slug || self.slugs.first
  end

  def slug=(sl)
    self.display_slug = self.add_slug(sl)
  end

  def add_slug(sl)
    sl = Utils::Slugger.slugify(sl)
    self.slugs_will_change!
    self.slugs << sl unless self.has_slug?(sl)
    sl
  end
  
  def has_slug?(sl)
    sl = Utils::Slugger.slugify(sl)
    self.slugs.include?(sl)
  end

  private

  def ensure_id_in_slugs
    self.add_slug(self.id)
  end

  def validate_slugs
    self.slugs.each do |sl|
      unless Utils::Slugger.valid?(sl)
        errors.add :slugs, "contains an invalid slug: #{sl}"
      end
    end

    if self.display_slug && !self.has_slug?(self.display_slug)
      errors.add :display_slug, "is not in the list of slugs"
    end
  end

end