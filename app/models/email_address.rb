class EmailAddress < ActiveRecord::Base
  BLACKLISTED_EMAILS = ['root@localhost']

  class << self
    def search_sql(address_string)
      conditions = ['address IN (?)', address_string.split - BLACKLISTED_EMAILS]

      %[SELECT array_agg(id) AS ids
      FROM email_addresses
      WHERE #{ sanitize_sql_array(conditions) }]
    end
  end
end