#LCMotive

## An lightweight user-friendly Ruby MVC and SQL ORM

LCMotive combines a stripped-down ORM with a no-frills MVC, and is built on Ruby and uses Rack as a response/request interface

#### API highlights

The SQLObject wraps raw SQL queries so that programmer using LCMotive will never have to write them. For example, searching for an object with any number of parameters can be done simply by passing a hash SQLObject#where.

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

It is also easy to set up association methods between objects. Simple methods such as belongs_to or has_many are available, as are more complex ones such as has_one_through. To enable the latter, each object stores on it one or multiple assoc_options, which keep track of the data that relates the object to others.

````Ruby
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end
````

Below is an implementation of has_one_through using a nested set of assoc_options


````Ruby
def has_one_through(name, through_name, source_name)
  define_method(name) do
    through_options = self.class.assoc_options[through_name]
    source_options = through_options.model_class.assoc_options[source_name]
    
    through_table = through_options.table_name
    through_primary_key = through_options.primary_key
    through_foreign_key = through_options.foreign_key
    
    source_table = source_options.table_name
    source_primary_key = source_options.primary_key
    source_foreign_key = source_options.foreign_key
    
    key_val = self.send(through_foreign_key)
    results = DBConnection.execute(<<-SQL, key_val)
      SELECT
        #{source_table}.*
      FROM
        #{through_table}
      JOIN
        #{source_table}
      ON
        #{through_table}.#{source_foreign_key} = #{through_table}.#{through_primary_key}
      WHERE
        #{through_table}.#{through_primary_key} = ?
    SQL
    
    source_options.model_class.parse_all(results).first
  end
end
````
