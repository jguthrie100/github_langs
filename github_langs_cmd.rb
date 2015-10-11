require 'net/http'
require 'json'

# Github authentication (shouldn't share secret here, but anyway..)
auth_str = '?client_id=e70d1009b69c73e947f8&client_secret=5afe5b91d674a8f138c4dfbe9691f5d27164ded0'
user = ""

loop do
  # Grab username and keep looping until username is valid
  loop do
    print "Please enter a username: "
    user = gets.chomp
    
    break if user =~ /\w/  # Not sure what naming defs are for github, but assume it must contains at least one word char
  end

  # Create rest request URL to get list of public repos belonging to the user
  api_url = "https://api.github.com"
  url = "#{api_url}/users/#{user}/repos"

  puts "Getting list of repos..."
  resp = Net::HTTP.get_response(URI.parse(url + auth_str))

  # Check to ensure username is a GitHub account with repos - if not, return to username entry
  unless resp.code == "200"
    puts "The username '#{user}' could not be loaded. Are you sure its a valid username?"
    puts "Error: #{resp.message}"
    next
  end

  # Parse the Json response to a hash
  resp = JSON.parse(resp.body)

  if resp.empty?
    puts "The user '#{user}' doesn't have any public repositories on GitHub (and hence no identifiable favourite language)"
    exit
  end

  # Map the repo names to a new array
  projects = resp.map{|r| r["name"]} 

  # 'Master language hash' that stores the amount of bytes written in each language
  #  i.e lang_hash["Ruby"] should return the bytes of ruby code written across all repos
  lang_hash = Hash.new(0)

  # vars for Thread handling
  mutex1 = Mutex.new
  threads = Hash.new

  # Loop through each repo/project and request the languages used in each repo
  projects.each do |p|
    
    # Use Threads for API calls
    threads[p] = Thread.new do

      # URL to grab Json data containing languages used in a project
      lang_url = "#{api_url}/repos/#{user}/#{p}/languages"
      print "Getting languages used in #{p}\n"
      
      resp = Net::HTTP.get_response(URI.parse(lang_url + auth_str))
      resp = JSON.parse(resp.body)

      # Loop through the response and add the amount of bytes written in each language
      #  to the 'master languages hash'
      mutex1.synchronize do # Lock access to the main lang_hash hash
        resp.each do |lang, bytes|
          lang_hash[lang] += bytes.to_i
        end
      end
    end

  end

  # Pause main thread until all threads have finished
  threads.each do |project, thread|
    thread.join
  end

  puts
  puts "Showing results... first result is the most used language for #{user}"
  puts
  lang_hash.sort_by {|lang, bytes| bytes}.reverse.each do |lang, bytes|
    puts "#{lang}: #{bytes} bytes written"
  end

  exit
end