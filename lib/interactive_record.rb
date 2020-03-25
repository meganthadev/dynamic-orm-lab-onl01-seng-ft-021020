require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize 
  end 
  
  def self.column_names
    DB[:conn].results_as_hash = true 
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |column|
      column_names << column["name"]
    end 
    column_names.compact
  end   
  
  def initialize(options = {})
    options.each do |property, value|
      self.send("#{property}=", value)
    end 
  end   
  
  def table_name_for_insert
    self.class.table_name 
  end   
  
  def col_names_for_insert
    self.class.column_names.reject{|column| column == 'id'}.join(', ')
  end
  
  def values_for_insert
    values = [] 
    self.class.column_names.each do |col_name|
      values << "'{send(col_name)}'" unless send (col_name).nil?
    end 
    values.join(",")
  end 
  
  def save
    sql = <<-SQL
      INSERT INTO #{self.class.table_name} ( #{self.col_names_for_insert} )
      VALUES ( #{self.values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.class.table_name}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE name = "#{name}"
    SQL
    test = DB[:conn].execute(sql)
    test
  end
end   