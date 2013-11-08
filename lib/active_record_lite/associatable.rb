require 'active_support/core_ext/string/inflections'
module Associatable
  def belongs_to(association_name, settings={})
    settings = BelongsToAssocParams.new(association_name, settings)
    define_method(association_name) do
      results = DBConnection.execute(<<-SQL, self.get(settings.foreign_key))
      SELECT
        *
      FROM
        #{settings.other_table}
      WHERE
        #{settings.other_table}.#{settings.primary_key} = ?
      SQL
      return nil if results.empty?

      settings.other_class.new(results.first)
    end
  end

  def has_one_through(association_name, source, target)
    define_method(association_name) do
      self.send(source).send(target)
    end
  end

  def has_many(association_name, settings={})
    settings = HasManyAssocParams.new(association_name, self.class, settings)
    define_method(association_name) do
      results = DBConnection.execute(<<-SQL, self.get(settings.primary_key))
      SELECT
        *
      FROM
        #{settings.other_table}
      WHERE
        #{settings.foreign_key} = ?
      SQL

      settings.other_class.parse_all(results)
    end

    define_method("#{association_name.to_s.singularize}_ids") do
      results = DBConnection.execute(<<-SQL, self.get(settings.primary_key))
      SELECT
        id
      FROM
        #{settings.other_table}
      WHERE
        #{settings.foreign_key} = ?
      SQL

      results.map { |arr| arr["id"] }
    end

    define_method("#{association_name.to_s.singularize}_ids=") do |ids|
      self.send(association_name).clear
      results = DBConnection.execute(<<-SQL, self.id, *ids)
      UPDATE
        #{settings.other_table}
      SET
        #{settings.foreign_key} = ?
      WHERE
        id IN (#{ids.map {|m| "?" }.join(", ")})
      SQL

      nil
    end
  end
end

class AssocParams
  def primary_key
    @settings[:primary_key]
  end

  def foreign_key
    @settings[:foreign_key]
  end

  def other_class
    @settings[:class_name].constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(association_name, settings={})
    defaults = {
      :class_name => association_name.to_s.camelize,
      :foreign_key => "#{association_name}_id".to_s.underscore,
      :primary_key => "id"
    }
    @settings = defaults.merge(settings)
    @settings[:association_name] = association_name
  end
end

class HasManyAssocParams < AssocParams
  def initialize(association_name, current_class, settings={})
    singular = association_name.to_s.singularize
    defaults = {
      :class_name => singular.camelize,
      :foreign_key => "#{current_class}_id".underscore,
      :primary_key => "id"
    }
    @settings = defaults.merge(settings)
  end
end