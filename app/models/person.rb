class Person < Entity
  
  REGEX_EPPN = /@/
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
  
  # Indexes
  index({ eppn: 1 }, { sparse: true, unique: true })
  index({ emails: 1 }, { sparse: true })
  
  # Relations
  embeds_many :favorites
  
  # Callbacks
  before_save :set_sorted_name
  
  # Validations
  validates :eppn, presence: true, format: { with: REGEX_EPPN }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :display_email, presence: true
  validates :contact_email, presence: true
  
  # Class Methods
  
  def self.validate_all
    self.each do |p|
      if !p.valid?
        puts "#{p.eppn} is not valid! Username: #{p.umbc_username}"
      end
    end
  end
  
  def self.lookup(em)
    domain = em.split('@')[1]
    full_em = domain.present? ? em : em.concat("@#{APP_CONFIG[:default_domain]}").downcase
    
    matches = self.where(emails: full_em)
    
    if matches.blank? && DOMAIN_PEOPLE[domain || APP_CONFIG[:default_domain]]
      matches = DOMAIN_PEOPLE[domain || APP_CONFIG[:default_domain]].lookup(em)
    end
    
    matches.to_a
  end
  
  def self.find_or_setup(eppn, data = nil)
    eppn = eppn.try(:downcase)
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
    self.sorted_name = ActiveSupport::Inflector.parameterize("#{ActiveSupport::Inflector.transliterate(self.last_name).downcase}#{ActiveSupport::Inflector.transliterate(self.first_name).downcase}#{self.id}", '').gsub(/[^a-z]/i, '')
  end
end
