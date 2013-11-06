require 'db_connection'

class MassObject
  def self.my_attr_accessible(*args)
    @attributes ||= []
    @attributes.push(*args)
    my_attr_accessor(*args)
  end

  def self.attributes
    @attributes || []
  end

  def initialize(attrs)
    attrs.each do |k, v|
      k = k.to_sym unless k.is_a?(Symbol)
      raise "can't mass assign when #{k} is not on the whitelist" unless self.class.attributes.include?(k)
      instance_variable_set("@#{k}".to_sym, v)
    end
  end

  def self.parse_all(args)
    [].tap do |arr|
      args.each do |hash|
        arr << self.new(hash)
      end
    end
  end
end

class SQLObject < MassObject
  def self.set_table_name(name)
    @table_name = name
  end

  def self.table_name
    @table_name
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{table_name}")
    results.map { |result| self.new(result) }
  end

  def self.find(primary_key)
    result = DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ?", primary_key)
    return nil if result.empty?
    self.new(result.first)
  end

  def attrs_with_values
    Hash.new.tap do |arr|
      self.class.attributes.each do |atr|
        next if atr == :id
        atr_name = "@#{atr}".to_sym
        arr[atr.to_s] = instance_variable_get(atr_name)
      end
    end
  end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  private
  def update
    attrs = attrs_with_values
    DBConnection.execute(<<-SQL, *attrs.values)
    UPDATE
      #{self.class.table_name}
    SET
      #{attrs.keys.join(" = ?,")} = ?
    SQL
  end

  def create
    attrs = attrs_with_values
    DBConnection.execute(<<-SQL, *attrs.values)
    INSERT INTO #{self.class.table_name} (#{attrs.keys.join(", ")})
    VALUES (#{attrs.values.map { |v| "?" }.join(", ")})
    SQL
    @id = DBConnection.last_insert_row_id
  end
end

class Object
  def self.my_attr_accessor(*args)
    args.each do |attr_name|
      attr_name = attr_name.to_s
      instance_var_sym = "@#{attr_name}".to_sym
      define_method("#{attr_name}") do
        instance_variable_get(instance_var_sym)
      end

      define_method("#{attr_name}=") do |val|
        instance_variable_set(instance_var_sym, val)
      end
    end
  end
end