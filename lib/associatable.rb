require_relative 'searchable'
require_relative 'belongs_to_options'
require_relative 'has_many_options'
require 'active_support/inflector'

module Associatable
  
  def belongs_to(name, options = {})
    
    options = BelongsToOptions.new(name, options)
    self.assoc_options[name] = options

    define_method(name) do
      options = self.class.assoc_options[name]
      
      foreign_key_value = self.send(options.foreign_key)
  
      options
        .model_class
        .where(options.primary_key => foreign_key_value)
        .first
    end

  end

  def has_many(name, options = {})

    self.assoc_options[name]=HasManyOptions.new(name, self.name, options)
    
    define_method(name) do
      options = self.class.assoc_options[name]
      
      primary_key_value = self.send(options.primary_key)
      
      options
        .model_class
        .where(options.foreign_key => primary_key_value)
    end
  end

  
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
  
  def assoc_options
    @assoc_options ||= {}
  end
end
