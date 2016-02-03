require 'twitter'

class TwitterClient

  attr_accessor :client

  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['WIN_CONSUMER_KEY']
      config.consumer_secret = ENV['WIN_CONSUMER_SECRET']
      config.access_token = ENV['WIN_TOKEN']
      config.access_token_secret = ENV['WIN_TOKEN_SECRET']
    end
  end

end
