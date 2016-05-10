# docker-compose run consumer ruby lib/consumer.rb

require 'rubygems'
require 'csv'
require 'json'
require 'bunny'
require 'neo4j-core'

begin
  @queue_connection = Bunny.new(:hostname => "rabbitmq", :user => "guest", :password => "guest")
  @queue_connection.start
  queue_channel = @queue_connection.create_channel
  queue  = queue_channel.queue("clinicaltrials")
  queue_channel.prefetch(25)
rescue
   sleep(3)
   retry
end

begin
  @neo_session = Neo4j::Session.open(:server_db, "http://neo4j:7474")

  trial_label = Neo4j::Label.create(:Trial)
  trial_label.create_index(:nct)
  phase_label = Neo4j::Label.create(:Phase)
  phase_label.create_index(:title)
  intervention_label = Neo4j::Label.create(:Intervention)
  intervention_label.create_index(:title)
rescue
   sleep(3)
   retry
end

queue.subscribe(:block => true, :manual_ack => true) do |delivery_info, properties, payload|

  begin
    trial = JSON.parse(payload)
  rescue Exception => e
    puts "Failed to decode Trial: #{payload.inspect}"
  end

  begin
    trial_node = Neo4j::Node.create( { nct: trial['NCT_Number'], title: trial['Title'], rank: trial['Rank'], recruitment: trial['Recruitment'] }, :Trial )
    puts "Created node #{trial_node[:NCT]} with labels #{trial_node.labels.join(', ')}"

    unless trial['Phases'].nil?
      trial['Phases'].split('|').each do |phase|
        # Check if the phase already exists
        phase_node = Neo4j::Label.find_nodes( :Phase, :title, phase ).first

        if phase_node.nil?
          phase_node = Neo4j::Node.create( { title: phase }, :Phase)
          puts "Created node #{phase_node[:title]} with labels #{phase_node.labels.join(', ')}"
        end

        Neo4j::Relationship.create(:IS_IN, trial_node, phase_node, since: 1994)
      end
    end

    unless trial['Interventions'].nil?
      trial['Interventions'].split('|').each do |intervention|
        # Check if the intervention already exists
        intervention_node = Neo4j::Label.find_nodes( :Intervention, :title, intervention ).first

        if intervention_node.nil?
          intervention_node = Neo4j::Node.create( { title: intervention }, :Intervention)
          puts "Created node #{intervention_node[:title]} with labels #{intervention_node.labels.join(', ')}"
        end

        Neo4j::Relationship.create( :TESTS, trial_node, intervention_node )
      end
    end

    unless trial['Conditions'].nil?
      trial['Conditions'].split('|').each do |condition|
        # Check if the condition already exists
        condition_node = Neo4j::Label.find_nodes( :Condition, :title, condition ).first

        if condition_node.nil?
          condition_node = Neo4j::Node.create( { title: condition }, :Condition)
          puts "Created node #{condition_node[:title]} with labels #{condition_node.labels.join(', ')}"
        end

        Neo4j::Relationship.create( :TARGETS, trial_node, condition_node )
      end
    end

    unless trial['Sponsor_Collaborators'].nil?
      trial['Sponsor_Collaborators'].split('|').each do |sponsor|
        # Check if the sponsor already exists
        sponsor_node = Neo4j::Label.find_nodes( :Sponsor, :title, sponsor ).first

        if sponsor_node.nil?
          sponsor_node = Neo4j::Node.create( { title: sponsor }, :Sponsor)
          puts "Created node #{sponsor_node[:title]} with labels #{sponsor_node.labels.join(', ')}"
        end

        Neo4j::Relationship.create( :SPONSORS, sponsor_node, trial_node )
      end
    end

    queue_channel.ack(delivery_info.delivery_tag)
  rescue Exception => e
    raise "Failed to graph Trial #{trial['NCT_Number']}: #{e.inspect}"
  end

end