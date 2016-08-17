require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    p where_line = params.keys.map{|key| "#{key} = ?"}.join(" AND ")
    query = <<-SQL
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      where
        #{where_line}
    SQL
    
    results = DBConnection.execute(query, *params.values)
    results.map { |params| self.send(:new, params)}
  end
end
