require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

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
end
