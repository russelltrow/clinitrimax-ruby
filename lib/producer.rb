# docker-compose run producer ruby lib/producer.rb

require 'rubygems'
require 'csv'
require 'json'
require 'bunny'

begin
  @queue_connection = Bunny.new(:hostname => "rabbitmq", :user => "guest", :password => "guest")
  @queue_connection.start
  queue_channel = @queue_connection.create_channel
  queue  = queue_channel.queue("clinicaltrials")
rescue
   sleep(3)
   retry
end

CSV.foreach("data/study_fields.csv", :headers => true) do |row|
  queue.publish(JSON.generate(row.to_hash))
  puts "Published: #{row['Title']}"
end

@queue_connection.close