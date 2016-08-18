# docker-compose run producer ruby lib/producer.rb

require 'rubygems'
require 'csv'
require 'json'
require 'bunny'
require 'dotenv'
Dotenv.load

begin
  @queue_connection = Bunny.new(:hostname => ENV["RABBITMQ_ENDPOINT_HOSTNAME"], :user => ENV["RABBITMQ_USER"], :password => ENV["RABBITMQ_PASSWORD"])
  @queue_connection.start

  queue_channel = @queue_connection.create_channel
  queue  = queue_channel.queue("clinicaltrials")
  queue_channel.prefetch(ENV["RABBITMQ_CHANNEL_PREFETCH"].to_i)
rescue Exception => e
  puts e.inspect
  puts "Trying to connect to Rabbit"
  sleep(3)
  retry
end

CSV.foreach("data/study_fields.csv", :headers => true) do |row|
  begin
    queue.publish(JSON.generate(row.to_hash))
  rescue Exception => e
    puts e.inspect
  end
end

@queue_connection.close