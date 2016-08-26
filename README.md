#LCMotive

## An lightweight user-friendly Ruby MVC and SQL ORM

LCMotive combines a stripped-down ORM with a no-frills MVC, and is built on Ruby and uses Rack as a response/request interface

#### API highlights

SQLObject makes it so that a programmer using LCMotive will never have to write raw SQL queries. For example, you can search for an object with any number of parameters simply by passing a hash SQLObject#where.

````Ruby
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
````
