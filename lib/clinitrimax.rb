require 'rubygems'
require 'csv'
require 'neography'

@neo = Neography::Rest.new
@neo = Neography::Rest.new({:authentication => nil})
@neo = Neography::Rest.new("http://neo4j:7474")

CSV.foreach("data/study_fields.csv", :headers => true) do |row|
  new_trial_node = @neo.create_node( "NCT" => row['NCT_Number'], "title" => row['Title'] )
  @neo.add_label( new_trial_node, "Person" )
end