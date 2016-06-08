require 'active_support/inflector'


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
    @class_name.underscore + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.each do |key,value|
      self.send("#{key}=", value)
    end
    @foreign_key ||= "#{name.to_s.singularize}_id".to_sym
    @primary_key ||= :id
    @class_name ||= name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.each do |key,value|
      self.send("#{key}=", value)
    end

    @foreign_key ||= "#{self_class_name.to_s.singularize.downcase}_id".to_sym
    @primary_key ||= :id
    @class_name ||= name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      foreign_key = self.send(self.class.assoc_options[name].foreign_key)
      target_class = self.class.assoc_options[name].model_class
      target = target_class.where(
        self.class.assoc_options[name].primary_key => foreign_key
        )
      target.first
    end

  end

  def has_many(name, options = {})
    assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      target_class = self.class.assoc_options[name].model_class
      foreign_key_val = self.id
      target = target_class.where(
        self.class.assoc_options[name].foreign_key => foreign_key_val
        )
      target
    end
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      target_table = source_options.table_name
      target_id = self.send(through_options.foreign_key)

      results = DBConnection.execute(<<-SQL, target_id)
        SELECT
          #{target_table}.*
        FROM
          #{through_table}
        JOIN
          #{target_table}
        ON
          #{target_table}.#{source_options.primary_key} = #{through_table}.#{source_options.foreign_key}
        WHERE
          #{through_table}.#{through_options.primary_key} = ?
      SQL

      results.map do |result|
        source_options.model_class.new(result)
      end.first
    end
  end

  def assoc_options
      @assoc_options ||= {}
  end
end
