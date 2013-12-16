
# Umbc::Ldap::Person.find_by_campus_id
# Umbc::Ldap::Person.find_by_username
# Umbc::Ldap::Person.find_by_email
#
# Collier: guid=10ed33d2-9323-11da-bdc9-8020c1d084,ou=People,o=umbc.edu

module Umbc
  class Ldap

    BASE_ALL = 'o=umbc.edu'
    BASE_PEOPLE = 'ou=People,o=umbc.edu'
    BASE_ACCOUNTS = 'ou=Accounts,o=umbc.edu'
    BASE_MYUMBC_GROUP = 'ou=myUMBC,ou=Applications,o=umbc.edu'


    def self.batch(&block)
      ldap = Net::LDAP.new
      ldap.host = UMBC_CONFIG[:ldap][:host]
      ldap.port = UMBC_CONFIG[:ldap][:port]
      ldap.auth UMBC_CONFIG[:ldap][:username], UMBC_CONFIG[:ldap][:password]
      ldap.encryption :simple_tls

      # Connecting, do stuff, disconnect
      Rails.logger.debug "Opening LDAP Connection..."
      ldap.open do |ldap|
        yield self.new(ldap)
      end
    end

    # Search methods
    def self.search(base: BASE_ALL, filter: '', attributes: ['*'], limit: 0)
      self.batch do |l|
        l.search(base: base, filter: filter, attributes: attributes, limit: limit )
      end
    end

    def search(base: BASE_ALL, filter: '', attributes: ['*'], limit: 0)
      Rails.logger.debug "LDAP: SEARCH FOR -- #{filter.to_s}"
      @conn.search(base: base, filter: filter, attributes: attributes, return_result: true, size: limit)
    end

    # Find methods
    def self.find_people(options = {})
      self.batch do |l|
        l.find_people(options)
      end
    end

    def self.find_by_dn(dn)
      self.batch do |l|
        l.find_by_dn(dn)
      end
    end

    def find_by_dn(dn)
      e = search(base: dn, filter: '(objectClass=*)').first
      if e && e['objectclass'].include?('umbcPerson')
        Person.new(e, self)
      elsif ee && e['objectclass'].include?('umbcAccount')
        Account.new(e, self)
      end
    end

    def self.find_accounts(options = {})
      self.batch do |l|
        l.find_accounts(options)
      end
    end

    def find_accounts(options = {})
      account_attrs = ['*']
      account_filter = Net::LDAP::Filter.eq('uid', options[:username])

      search(base: BASE_ACCOUNTS, filter: account_filter, attributes: account_attrs, limit: 1).map { |a| Account.new(a, self) }
    end

    def find_people(options = {})
      # Note: Assume you've got a @ldap handle that is ready to go
      person_attrs = ["*","creatorsName","createTimestamp", "modifiersName", "modifyTimestamp"]
      person_filter = Net::LDAP::Filter.eq('objectclass', 'umbcPerson')
      perform_search = false

      # Now constuct an ldap filter
      options.select{ |s| [:guid, :campus_id, :alt_campus_id, :any_campus_id, :username, :last_name, :empl_id, :email, :all_ids, :major, :minor, :major_or_minor, :affiliation, :standing].include? s }.each do |k,v|
        perform_search = true
        v = [v].flatten

        case k
        when :guid
          v = v.map { |c| Net::LDAP::Filter.eq('guid', c) }
        when :campus_id
          # Exact campus id match
          v = v.map { |c| Net::LDAP::Filter.eq('umbccampusid', c) }
        when :alt_campus_id
          # Includes alternate campus ids
          v = v.map { |c| Net::LDAP::Filter.eq('umbcalternatecampusid', c) }
        when :any_campus_id
          # Includes alternate campus ids
          v = v.map { |c| Net::LDAP::Filter.intersect(Net::LDAP::Filter.eq('umbccampusid', c), Net::LDAP::Filter.eq('umbcalternatecampusid', c)) }
        when :username
          v = v.map { |c| Net::LDAP::Filter.eq('umbcprimaryaccountuid', c) }
        when :first_name
          v = v.map { |c| Net::LDAP::Filter.eq('givenname', c) }
        when :last_name
          v = v.map { |c| Net::LDAP::Filter.eq('sn', c) }
        when :empl_id
          v = v.map { |c| Net::LDAP::Filter.eq('umbcpsoftemplid', c) }
        when :email
          v = v.map do |c|
            email_filters = []
            email_filters << Net::LDAP::Filter.eq('mailacceptinggeneralid', c.split('@')[0])
            email_filters << Net::LDAP::Filter.eq('mail', c)
            email_filters << Net::LDAP::Filter.eq('maildrop', c)
            email_filters.reduce { |memo, n| Net::LDAP::Filter.intersect(memo, n) }
          end
        when :all_ids
          v = v.map do |c|
            smart_filters = []
            smart_filters << Net::LDAP::Filter.eq('umbcpsoftemplid', c.split('@')[0])
            smart_filters << Net::LDAP::Filter.eq('umbcprimaryaccountuid', c.split('@')[0])
            smart_filters << Net::LDAP::Filter.eq('umbccampusid', c.split('@')[0])
            smart_filters << Net::LDAP::Filter.eq('umbcalternatecampusid', c.split('@')[0])
            smart_filters << Net::LDAP::Filter.eq('mailacceptinggeneralid', c.split('@')[0])
            smart_filters << Net::LDAP::Filter.eq('mail', c)
            smart_filters << Net::LDAP::Filter.eq('maildrop', c)
            smart_filters.reduce { |memo, n| Net::LDAP::Filter.intersect(memo, n) }
          end
        when :major
          v = v.map { |c| Net::LDAP::Filter.eq('umbcmajor', c) }
        when :minor
          v = v.map { |c| Net::LDAP::Filter.eq('umbcminor', c) }
        when :major_or_minor
          v = v.map { |c| Net::LDAP::Filter.intersect(Net::LDAP::Filter.eq('umbcminor', c), Net::LDAP::Filter.eq('umbcmajor', c)) }
        when :standing
          v = v.map { |c| Net::LDAP::Filter.eq('umbcstudentstanding', c) }
        when :affiliation
          v = v.map { |c| Net::LDAP::Filter.eq('affiliation', c) }
        end

        person_filter &= v.reduce { |memo, n| Net::LDAP::Filter.intersect(memo, n) }
      end

      if perform_search
        self.search(base: BASE_PEOPLE, filter: person_filter, attributes: person_attrs, limit: (options[:limit] || 0)).map { |p| Person.new(p, self) }
      else
        raise ArgumentError.new('Invalid search criteria specified')
      end
    end

    private

    def initialize(conn)
      @conn = conn
    end

    class Entry
      def initialize(entry, ldap)
        @entry = entry
        @ldap = ldap
      end

      def entry
        @entry
      end

      def object_class
        multi_value :objectclass
      end

      private

      def single_value(attr, default_value = nil)
        @entry[attr].present? ? @entry[attr].first.strip : default_value
      end

      def multi_value(attr, default_value = [])
        ret_val = @entry[attr].present? ? @entry[attr] : default_value
        ret_val.sort
      end

    end
  end
end
