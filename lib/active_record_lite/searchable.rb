module Searchable
  def where(fields)
    results = DBConnection.execute(<<-SQL, *fields.values)
    SELECT * FROM
      #{self.table_name}
    WHERE
      #{fields.keys.map { |k| "`#{k}`" }.join(" = ? AND ")} = ?
    SQL

    self.parse_all(results)
  end
end