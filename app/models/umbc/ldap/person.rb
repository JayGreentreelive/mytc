module Umbc
  class Ldap
    class Person < Entry
      CAMPUS_ID_REGEX = /\A[A-Z]{2}[0-9]{5}\Z/
      USERNAME_REGEX = /\A[a-z0-9\-]{,16}\Z/
      EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      PRIVACY_LIMIT = 2
      
      ## Finders
      def self.find_by_eppn(eppn)
        usr = eppn.split('@')[0]
        Umbc::Ldap.find_people(campus_id: usr).first
      end
      
      def self.find_by_username(usr)
        Umbc::Ldap.find_people(username: usr).first
      end

      def self.find_by_campus_id(cid)
        Umbc::Ldap.find_people(campus_id: cid).first
      end

      def self.find_by_empl_id(cid)
        Umbc::Ldap.find_people(empl_id cid).first
      end

      def initialize(entry, ldap)
        super
      end

      ## Attributes

      # IDs
      def dn
        single_value :dn
      end

      def eppn
        "#{campus_id}@umbc.edu".downcase
      end

      def username
        single_value(:umbcprimaryaccountuid).try(:downcase)
      end

      def campus_id
        single_value(:umbccampusid).try(:upcase)
      end

      def alternate_campus_ids
        multi_value :umbcalternatecampusid
      end

      def empl_id
        single_value :umbcpsoftemplid
      end

      def lims_id
        single_value :umbclims
      end

      def hp_id
        single_value :umbchpid
      end

      def campus_card_id
        single_value :umbconecardiso
      end

      def guid
        single_value :guid
      end

      # Role Checks
      def affiliations
        multi_value(:affiliation).select { |a| a.present? }.map(&:downcase).uniq.compact.sort
      end

      def student?
        self.undergraduate_student? || self.graduate_student?
      end

      def undergraduate_student?
        self.affiliations.include? 'undergraduate student'
      end
      
      def graduate_student?
        self.affiliations.include? 'graduate student'
      end
      
      def employee?
        self.staff? || self.faculty?
      end

      def staff?
        self.affiliations.include? 'staff'
      end
      
      def faculty?
        self.affiliations.include? 'staff'
      end
      
      def alumni?
        self.affiliations.include? 'alumni'
      end

      # Name
      # def full_name
      #   "#{first_name} #{last_name}"
      # end

      def name
        "#{nickname} #{last_name}"
      end
      
      def names
        multi_value :cn
      end

      def nickname
        single_value :edupersonnickname, first_name
      end

      def first_name
        single_value :givenname, 'Unknown'
      end

      def last_name
        single_value :sn, 'Person'
      end

      # Email
      def display_email
        de = single_value(:mail).try(:downcase)
        if de.present? && de.match(EMAIL_REGEX)
          de
        else
          (self.username ? "#{username}@umbc.edu" : "#{campus_id}@umbc.edu").downcase
        end
      end

      def contact_email
        "#{campus_id}@umbc.edu".downcase
      end

      def emails
        ems = []
        ems << "#{self.campus_id}@umbc.edu".downcase
        ems << "#{self.username}@umbc.edu".downcase if self.username.present?
        ems << self.contact_email
        ems << self.maildrop.split(',') if self.maildrop
        ems << self.email_aliases
        ems.flatten.uniq.compact.sort.map { |em| em.strip }.select { |em| em.match(EMAIL_REGEX) }
      end

      def email_aliases
        multi_value(:mailacceptinggeneralid).select { |a| a.present? }.map { |e| "#{e}@umbc.edu".downcase }
      end

      def maildrop
        single_value(:maildrop).try(:downcase)
      end

      # Work Attributes
      def title
        single_value :title, hr_title
      end
      
      def hr_title
        single_value :umbctitle
      end

      def departments
        multi_value :umbcdisplaydepartment, [hr_department]
      end
      
      # def department
      #   self.display_department
      # end

      def display_department
        single_value(:umbcprimarydepartment, single_value(:umbcdisplaydepartment, hr_department))
      end
      
      def hr_department
        single_value :umbcdepartment
      end

      def hr_department_code
        single_value :departmentnumber
      end

      def office_building
        single_value :umbcofficebuilding
      end

      def office_building_code
        single_value :umbcbldgcode
      end

      def office_room
        single_value :roomnumber
      end

      def office_phone
        format_phone single_value(:umbcphonenumber)
      end

      def office_address
        address = []
        #address << '1000 Hilltop Circle'
        address << office_building + (office_room ? ", Room #{office_room}" : '')
        #address << 'Baltimore, MD 21250'
      end
      
      def hire_date
        Date.strptime(single_value(:umbchiredate, '01/01/1969'), '%m/%d/%Y')
      end
      
      def tenure
        now = Time.zone.now
        now.year - hire_date.year - (hire_date.to_time.change(year: now.year) > now ? 1 : 0)
      end

      # Home Attributes
      def home_address
        single_value(:postaladdress).try { |a| a.split('$') }
      end
      
      def home_phone
        single_value(:homephone).try { |a| a.split('$') }
      end

      def billing_address
        single_value(:billingaddress).try { |a| a.split('$') }
      end

      # Student Attributes
      def majors
        multi_value(:umbcmajor).select { |a| a.present? }.map &:upcase
      end

      def minors
        multi_value(:umbcminor).select { |a| a.present? }.map &:upcase
      end

      def standing
        self.student? ? single_value(:umbcstudentstanding).try(:downcase) : nil
      end

      def degrees
        degs = []
        multi_value(:umbcdegree).each do |deg|
          deg = deg.split('|')
          degs << { degree: deg[0], program: deg[1], date: Date.strptime(deg[2], '%m/%d/%Y') }
        end
        degs.sort_by { |d| [d[:date], d[:program], d[:degree]] }
      end

      def applicant_status
        apps = []
        multi_value(:umbcapplicantstatus).each do |app|
          app = app.split(':')
          apps << { affiliation: app[0], semester: app[1] }
        end
        apps.sort_by { |a| [a[:semester], a[:affiliation]] }
      end

      # Services
      def locked?
        self.account && self.account.locked?
      end

      def services
        services = []

        if single_value(:umbcgappsemail, '').downcase == 'true'
          services << :google_mail
        end

        if single_value(:umbcgappsprovisioned, '').downcase == 'true'
          services << :google_calendar
          services << :google_drive
        end

        if self.account
          if self.account.active?  && self.account.ok?
            services << :mail
            services << :blackboard
          end
        end

        services
      end

      # Additional Attributes
      def birthday
        Date.strptime(single_value(:dateofbirth, '01/01/1969'), '%m/%d/%Y')
      end

      def age
        now = Time.zone.now
        now.year - birthday.year - (birthday.to_time.change(year: now.year) > now ? 1 : 0)
      end


      def privacy_level
        single_value(:umbcbuckley).to_i
      end

      def private?
        privacy_level >= PRIVACY_LIMIT
      end

      def created_at
        begin
          DateTime.parse(single_value(:createtimestamp))
        rescue ArgumentError
          nil
        end
      end

      def updated_at
        begin
          DateTime.parse(single_value(:modifytimestamp))
        rescue ArgumentError
          nil
        end
      end

      def account
        @account ||= @ldap.find_accounts(username: (username || '')).first
      end

      private

      def format_phone(number)
        number ? number.gsub(/[^0-9]/, '').strip : number
      end

    end
  end
end