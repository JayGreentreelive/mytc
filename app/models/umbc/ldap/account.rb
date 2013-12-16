module Umbc
  class Ldap
    class Account < Entry

      ## Attributes
      def type
        single_value :umbcaccounttype
      end

      def owner_dn
        single_value :owner
      end

      def owner
        @owner ||= @ldap.find_by_dn(owner_dn)
      end

      def status
        multi_value :umbcaccountstatus
      end

      def active?
        !deactivated? && !locked?
      end

      def ok?
        status.include? 'global:OK'
      end

      def deactivated?
        deactivated_at.present?
      end

      def deactivated_at
        if single_value(:umbcdeactivatetimestamp)
          DateTime.parse single_value(:umbcdeactivatetimestamp)
        else
          nil
        end
      end

      def locked?
        single_value(:umbclocked) == 'Y'
      end

      def locked_reason
        single_value :umbclockedreason
      end

    end
  end
end