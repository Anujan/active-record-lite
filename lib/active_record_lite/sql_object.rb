class SQLObject < MassObject
  extend Searchable

  def self.set_table_name(name)
    @table_name = name
  end

  def self.table_name
    @table_name
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{table_name}")
    self.parse_all(results)
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