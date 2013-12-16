class UmbcPerson < Person
  
  DOMAIN_PEOPLE['umbc.edu'] = self
  
  REGEX_CAMPUS_ID = /\A[A-Z]{2}[0-9]{5}\Z/
  REGEX_USERNAME = /\A[a-z0-9\-]{,16}\Z/
  
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
  field :umbc_alt_names, type: Array, default: []
  field :umbc_privacy_level, type: Integer, default: 0
  
  # Validations
  validates :umbc_campus_id, presence: true, format: { with: REGEX_CAMPUS_ID }
  validates :umbc_username, presence: false, format: { with: REGEX_USERNAME }
  
  def self.lookup(em)
    Umbc::Ldap.find_people(all_ids: em).map { |p| self.find_or_setup(p.eppn, p) }.compact
  end
    
  def self.find_or_setup(eppn, data = nil)
    person = self.find_or_initialize_by(eppn: eppn)
    person.sync!(data) if person.new_record?
    person
  end
  
  def sync(login_data = nil)
    if !login_data.is_a?(Umbc::Ldap::Person)
      login_data = Umbc::Ldap::Person.find_by_eppn(self.eppn)
    end
    
    if login_data.present?
      update_with_ldap_data(login_data)
    end
    
    self.last_sync_at = Time.zone.now
    true
  end
  
  private
  
  def update_with_ldap_data(ldap_person)
    self.name = ldap_person.name
    self.first_name = ldap_person.nickname
    self.last_name = ldap_person.last_name
    self.emails = ldap_person.emails
    self.display_email = ldap_person.display_email
    self.contact_email = ldap_person.contact_email
    self.birthday = ldap_person.birthday
    self.umbc_campus_id = ldap_person.campus_id
    self.umbc_alt_campus_ids = ldap_person.alternate_campus_ids
    self.umbc_username = ldap_person.username
    self.umbc_empl_id = ldap_person.empl_id
    self.umbc_lims_id = ldap_person.lims_id
    self.umbc_majors = ldap_person.majors
    self.umbc_minors = ldap_person.minors
    self.umbc_standing = ldap_person.standing
    self.umbc_affiliations = ldap_person.affiliations
    self.umbc_title = ldap_person.title
    self.umbc_alt_names = ldap_person.names
    self.umbc_privacy_level = ldap_person.privacy_level
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
