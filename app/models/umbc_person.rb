class UmbcPerson < Person
  
  DOMAIN_PEOPLE['umbc.edu'] = self
  
  CAMPUS_ID_REGEX = /\A[A-Z]{2}[0-9]{5}\Z/
  USERNAME_REGEX = /\A[a-z0-9\-]{,16}\Z/
  
  field :umbc_campus_id, type: String
  field :umbc_alt_campus_ids, type: Array, default: []
  field :umbc_username, type: String
  field :umbc_empl_id, type: String
  field :umbc_lims_id, type: String
  field :umbc_majors, type: Array, default: []
  field :umbc_minors, type: Array, default: []
  field :umbc_standing, type: String
  field :umbc_affiliations, type: Array, default: []
  field :umbc_title, type: String
  field :umbc_department, type: String
  field :umbc_alt_names, type: Array, default: []
  field :umbc_privacy_level, type: Integer, default: 0
  field :umbc_services, type: Array, default: []
  
  # Validations
  validates :umbc_campus_id, presence: true, format: { with: CAMPUS_ID_REGEX }
  validates :umbc_alt_campus_ids, array: { presence: true, format: { with: CAMPUS_ID_REGEX } }
  validates :umbc_username, allow_nil: true, format: { with: USERNAME_REGEX }
  validates :umbc_majors, array: { presence: true }
  validates :umbc_minors, array: { presence: true }
  validates :umbc_standing, allow_nil: true, inclusion: { in: %w(freshman sophomore junior senior grad cned) }
  validates :umbc_privacy_level, numericality: { only_integer: true }
  validates :umbc_services, array: { presence: true, format: { with: Utils::Slugger::SLUG_REGEX } }
  
  def self.lookup(em)
    Umbc::Ldap.find_people(all_ids: em).map { |p| self.find_or_setup(p.eppn, p) }.compact
  end
    
  def self.find_or_setup(eppn, data = nil)
    eppn = eppn.downcase
    person = self.where(eppn: eppn).first
    
    # IF there is already a person, simply return them
    if !person
      # Check LDAP for anyone that may have used this EPPN before
      ldap_person = Umbc::Ldap::Person.find_by_any_eppn(eppn)
      
      if ldap_person && ldap_person.merged?
        person = self.in(umbc_campus_id: ldap_person.all_campus_ids).first
        
        if person
          person.sync!(ldap_person)
        else
          person = self.find_or_initialize_by(eppn: ldap_person.eppn)
          person.sync!(ldap_person) if person.new_record?
        end

      elsif ldap_person
        person = self.new(eppn: ldap_person.eppn)
        person.sync!(ldap_person)
      else
        raise "Login by Invalid UMBC Person"
      end
    end
    
    person
  end
  
  def sync(login_data = nil)
    if login_data.blank?
      login_data = Umbc::Ldap::Person.find_by_eppn(self.eppn)
    end
    
    if login_data.is_a?(Umbc::Ldap::Person)
      update_with_ldap_data(login_data)
      self.last_sync_at = Time.zone.now
      true
    else
      super(login_data)
    end
  end
    
  private
  
  def update_with_ldap_data(ldap_person)
    self.eppn = ldap_person.eppn
    self.name = ldap_person.name
    self.first_name = ldap_person.nickname
    self.last_name = ldap_person.last_name
    self.emails = ldap_person.emails.select { |em| em.match(EMAIL_REGEX) }
    self.display_email = ldap_person.display_email
    self.contact_email = ldap_person.contact_email
    self.birthday = ldap_person.birthday
    self.umbc_campus_id = ldap_person.campus_id
    self.umbc_alt_campus_ids = ldap_person.alternate_campus_ids.select { |ci| ci.match(CAMPUS_ID_REGEX) }
    self.umbc_username = ldap_person.username
    self.umbc_empl_id = ldap_person.empl_id
    self.umbc_lims_id = ldap_person.lims_id
    self.umbc_majors = ldap_person.majors
    self.umbc_minors = ldap_person.minors
    self.umbc_standing = ldap_person.standing
    self.umbc_affiliations = ldap_person.affiliations.map { |a| Utils::Slugger.slugify(a) }
    self.umbc_title = ldap_person.title
    self.umbc_department = ldap_person.display_department
    self.umbc_alt_names = ldap_person.names
    self.umbc_privacy_level = ldap_person.privacy_level
    self.umbc_services = ldap_person.services.map { |s| Utils::Slugger.slugify(s) }
  end
    
  # Privacy
  
  #before_validation do
  #  if self.umbc_private?
  #    self.set_private_visible
  #  else
  #    self.set_public_visible
  #  end
  #end
  
  #def umbc_private?
  #  self.umbc_privacy_level.present? && (self.umbc_privacy_level >= Umbc::Ldap::Person::PRIVACY_LIMIT)
  #end
  
  #person.add_flag("umbc-privacy-#{ldap_user.privacy_level}")
  #if ldap_user.private?
    # TODO Use flags or just pure visibility?
    # person.add_flag(:private)
    #else
  #  person.make_public
  #end
  
  
  
end
