#LCMotive

## An lightweight user-friendly Ruby MVC and SQL ORM

LCMotive combines a stripped-down ORM with a no-frills MVC, is built on Ruby and uses Rack as a response/request interface.

### API highlights

#### ORM
The SQLObject wraps raw SQL queries so that a programmer using LCMotive will never have to write them. For example, searching for an object with an arbitrary of parameters can be done by simply passing a hash to SQLObject#where.

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

It is also easy to set up association methods between objects. Simple methods such as belongs_to or has_many are available, as are more complex ones such as has_one_through. To enable the latter, each object stores on it one or more assoc_options, which keep track of the data that relates the object to others.

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

Below is an implementation of has_one_through using a nested set of assoc_options:


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

### MVC

The router provides a RESTful HTTP convention using metaprogramming:

````Ruby
[:get, :post, :put, :delete].each do |http_method|
  define_method(http_method) do |pattern, controller_class, action_name|
    add_route(pattern, http_method, controller_class, action_name)
  end
````

And a single call to render :template_name will render the named template. This is accomplished by binding the current context to erb's result method:

````Ruby
def render(template_name)
  template_file = "views/#{self.class.to_s.underscore}/#{template_name.to_s}.html.erb"
  contents = File.read(template_file)
  erb = ERB.new(contents)
  html_content = erb.result(binding)
  render_content(html_content, 'text/html')
end
````

Finally, both flash and flash.now methods are available. Flash.now is stored in a local object while flash is persisted in a cookie:

````Ruby
class Flash
  
  attr_reader :now
  
  def initialize(req)
    cookie = req.cookies["_rails_lite_app_flash"]
    cookie_content = cookie ? JSON.parse(cookie) : {}
    @flash = FlashStore.new
    @now = FlashStore.new(cookie_content)
  end
  
  def [](key)
    @now[key] || @flash[key]
  end
  
  def []=(key, value)
    @flash[key] = value
    @now[key] = value
  end
  
  def store_flash(res)
    value = @flash.to_json
    res.set_cookie("_rails_lite_app_flash", {path: "/", value: value})
  end
end
````

### Example
