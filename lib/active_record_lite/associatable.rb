require 'active_support/core_ext/string/inflections'
module Associatable
  def belongs_to(association_name, settings={})
    settings = BelongsToAssocParams.new(association_name, settings)
    define_method(association_name) do
      results = DBConnection.execute(<<-SQL, self.id)
      SELECT
        #{settings.class_obj}.*
      FROM
        #{self.table_name}
      JOIN
        #{settings.other_table_name}
      ON
        #{self.table_name}.#{settings.foreign_key} = #{settings.other_table_name}.#{settings.primary_key}
      WHERE
          #{self.table_name}.#{settings.foreign_key} = ?
      SQL
      objs = self.parse_all(results)

      objs.empty? ? nil : objs.first
    end
  end

  def has_one_through(*args)
  end

  def has_many(association_name, settings={})
  end
end

class BelongsToAssocParams
  def initialize(association_name, settings={})
    defaults = {
      :class_name => association_name.to_s.camelize,
      :foreign_key => "#{association_name}_id".to_s.underscore,
      :primary_key => "id"
    }
    @settings = defaults.merge(settings)
  end

  def primary_key
    @settings[:primary_key]
  end

  def foreign_key
    @settings[:foreign_key]
  end

  def class_obj
    @settings[:class_name].constantize
  end

  def other_table
    self.class_obj.table_name
  end
end