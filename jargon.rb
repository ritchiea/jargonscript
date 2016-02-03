require 'json'
require "/home/ar/projects/winscript/twitter_client.rb"

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
end

def write_status!
  file = File.new('status.json', 'w+')
  file.write(JSON.generate(@status))
  file.close
end

query = ['"move the needle"','"huge win for"','"think outside the box"','"value add"','"core values" OR "core competency"',
         '"open the kimono" OR "opening the kimono"','ideation -suicidal -suicide','"corporate family"','"circle back"',
         '"moving the cheese"','"architect of change"','"data lake"','disestablish','"global platform"','"ground truthing"',
         'grow "your personal brand"','"step change"','"employee life cycle"','"bleeding edge"',
         '"circle back"'].map {|txt| txt << ' -rt'}

file = File.open('status.json', 'r')
@status = JSON.parse(file.read)
file.close

if @status['active_pid'].blank?
  @status['active_pid'] = Process.pid
  @status['last_run'] = Time.now.to_s
  write_status!
else
  # an active pid is present so another script is in progress
  puts "another script in progess"
  abort
end

begin
  puts "connecting to client"
  tc = TwitterClient.new
  tweets = []
  if @status['last_tweet'].blank?
    # skip if no last tweet
    puts "no last tweet"
    abort
  else
    puts "getting tweets"
    # query each search term individually because long OR queries fail
    query.each do |search_term|
      tc.client.search(search_term, since_id: @status['last_tweet'], result_type: 'recent', count: 100, language: 'en').each do |tweet|
        # add tweet to array but skip tweets where our search term matches the screen name
        if tweet.user.screen_name.match(/gamechanger/i) && !tweet.text.match(/gamechanger/i)
          next
        else
          tweets << tweet
        end
      end
      sleep 5 # sleep to avoid hitting twitter rate limit
    end
  end
  if tweets.empty?
    puts "no tweets"
  end
  # sort tweets by id to post oldest first
  tweets.sort{|x,y| x.id.to_i <=> y.id.to_i }.each_with_index do |tweet, i|
    puts "retweeting..."
    puts tweet.inspect
    # set last tweet in JSON file if index is last tweet in array
    if i == tweets.length - 1
      #last tweet
      puts "writing last tweet #{tweet.id}"
      @status['last_tweet'] = tweet.id
      write_status!
    end
    begin
      tc.client.retweet(tweet)
    rescue Twitter::Error::Unauthorized => e
      puts "can't retweet - unauthorized"
      puts e.message
      next
    rescue Twitter::Error::Forbidden => e
      puts "can't retweet - forbidden"
      puts e.message
      next
    rescue Twitter::Error::AlreadyRetweeted
      puts "already retweeted"
      next
    end
    if i < tweets.length - 1
      # sleep again to avoid hitting rate limit
      sleep 5
    end
  end
  # script is done, clear active pid and write status
  @status['active_pid'] = nil
  write_status!
rescue StandardError => e
  puts "script failed"
  puts e.message
  puts e.backtrace
  puts e.inspect
ensure
  @status['active_pid'] = nil
  write_status!
end
