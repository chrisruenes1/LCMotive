require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  extend Searchable
  extend Associatable
  def self.columns
    if @columns.nil?
      results = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
      SQL
      columns = results[0]
      @columns = columns.map {|column| column.to_sym}
    end
    @columns
  end

  def self.finalize!
    columns.each do |column_name|
      define_method(column_name.to_s+"=") do |value=nil|
        attributes[column_name] = value
      end

      define_method(column_name) do
        attributes[column_name]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      @table_name = self.to_s.tableize
    end

    @table_name
  end

  def self.all
    query = <<-SQL
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL

    results = DBConnection.execute(query)
    self.parse_all(results)
  end

  def self.parse_all(results)
    parsed = results.map do |params|
      self.send(:new, params)
    end
    parsed
  end

  def self.find(id)
    query = <<-SQL
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    params = DBConnection.execute(query, id).first
    return nil if params.nil?
    self.send(:new, params)
  end

  def initialize(params = {})
    params.keys.each do |key|
      attr_name = key.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}"+"=", params[key])
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    columns = self.class.columns
    col_names = columns.join(", ")
    question_marks = (["?"] * columns.size).join(", ")

    query = <<-SQL
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      values
        (#{question_marks})
    SQL

    DBConnection.execute(query, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns
    p set_line = columns.map { |column_name| "#{column_name} = ?"}.join(", ")

    query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL

    DBConnection.execute(query, *attribute_values, id)
  end

  def save
    if id.nil?
      self.insert
    else
      self.update
    end
  end
end
