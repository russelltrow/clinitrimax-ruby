# docker-compose run consumer ruby lib/consumer.rb

require 'rubygems'
require 'csv'
require 'json'
require 'bunny'
require 'neography'

begin
  @queue_connection = Bunny.new(:hostname => "rabbitmq", :user => "guest", :password => "guest")
  @queue_connection.start
  queue_channel = @queue_connection.create_channel
  queue  = queue_channel.queue("clinicaltrials")
  queue_channel.prefetch(10)
rescue
   sleep(3)
   retry
end

begin
  @neo = Neography::Rest.new
  @neo = Neography::Rest.new({:authentication => nil})
  @neo = Neography::Rest.new("http://neo4j:7474")
rescue
   sleep(3)
   retry
end

puts " [*] Waiting for messages. To exit press CTRL+C"

queue.subscribe(:block => true, :manual_ack => true) do |delivery_info, properties, payload|
  puts " [x] Received '#{payload}'"
  queue_channel.ack(delivery_info.delivery_tag)
  sleep 0.5

  # begin
  #   trial = JSON.parse(payload)
  # rescue Exception => e
  #   raise e.inspect
  # end

  # new_trial_node = @neo.create_node( "NCT" => trial['NCT_Number'], "title" => trial['Title'] )
  # @neo.add_label( new_trial_node, "Trial" )
end