require 'rubygems'
require 'csv'
require 'json'
require 'bunny'

@queue_connection = Bunny.new(:hostname => "rabbitmq", :user => "guest", :password => "guest")
@queue_connection.start
queue_channel = @queue_connection.create_channel
queue  = queue_channel.queue("test1")

CSV.foreach("data/study_fields.csv", :headers => true) do |row|
  queue.publish(row.to_json)
end

@queue_connection.close