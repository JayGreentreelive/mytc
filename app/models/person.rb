class Person < Entity
  # Constants
  EPPN_REGEX = /@/
  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  DOMAIN_PEOPLE = {}
  LEGACY_ID_PREFIX = 'my3-user-'
  
  # Fields
  field :eppn, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :sorted_name, type: String
  field :emails, type: Array, default: []
  field :display_email, type: String
  field :contact_email, type: String
  field :birthday, type: Date
  field :last_login_at, type: DateTime
  field :last_sync_at, type: DateTime
  
  # Relations
  embeds_many :favorites
  
  # Indexes
  #index({ eppn: 1 }, { sparse: true, unique: true })
  #index({ emails: 1 }, { sparse: true })
  
  # Callbacks
  before_save :set_sorted_name
  
  # Validations
  validates :eppn, presence: true, format: { with: EPPN_REGEX }
  validates :first_name, presence: true, length: { minimum: 1 }
  validates :last_name, presence: true, length: { minimum: 1 }
  # don't validate sorted_name because its system set
  validates :emails, array: { presence: true, format: { with: EMAIL_REGEX } }
  validates :display_email, presence: true, format: { with: EMAIL_REGEX }
  validates :contact_email, presence: true, format: { with: EMAIL_REGEX }
  
  #####
  # Class Methods
    
  # Lookup user by email/identifier
  def self.lookup(em)
    em = em.try(:strip)
    domain = em.strip.split('@')[1]
    full_em = domain.present? ? em : em.concat("@#{APP_CONFIG[:default_domain]}").downcase
    
    matches = self.where(emails: full_em).to_a
    
    if matches.blank? && DOMAIN_PEOPLE[domain || APP_CONFIG[:default_domain]]
      matches = DOMAIN_PEOPLE[domain || APP_CONFIG[:default_domain]].lookup(em)
    end
    
    matches
  end
  
  # Find or setup based on eppn
  def self.find_or_setup(eppn, data = nil)
    eppn = eppn.try(:downcase).try(:strip)
    domain = eppn.split('@')[1]
    
    raise ArgumentError.new('Invalid EPPN given') if domain.blank?
    
    if DOMAIN_PEOPLE[domain]
      per = DOMAIN_PEOPLE[domain].find_or_setup(eppn, data)
    else
      per = self.find_or_initialize_by(eppn: eppn)
      per.sync(data)
    end
    per.save!
    per
  end
    
  # Instance Methods
  
  def sync(login_data = nil)
    # update firstname, lastname, emails from shib data
    if login_data.respond_to?(:keys)
      self.update_attributes(login_data)
    end
    true
  end
  
  def sync!(login_data = nil)
    self.sync(login_data)
    self.save!
  end  
  
  def add_favorite(name, url)
    unless self.favorites.where(name: name, url: url).exists?
      self.favorites.build name: name, url: url
    end
  end
  
  def age
    if self.birthday
      now = Time.zone.now
      now.year - self.birthday.year - (birthday.to_time.change(year: now.year) > now ? 1 : 0)
    else
      0
    end
  end
  

  # IDEA: Not useful yet
  #def use_favorite(id)
  #  fav = self.favorites.where(id: id).first
  #  if fav
  #    fav.set(last_used_at: Time.now).inc(uses: 1)
  #  end
  #end
  
  # Private Methods
  private
  
  def set_sorted_name
    self.sorted_name = ActiveSupport::Inflector.parameterize("#{ActiveSupport::Inflector.transliterate(self.last_name).downcase}#{ActiveSupport::Inflector.transliterate(self.first_name).downcase}", '').gsub(/[^a-z]/i, '').concat("-#{self.id}")
  end
end
