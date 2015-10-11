require 'net/http'
require 'json'

class ProfilesController < ApplicationController

  def search
    redirect_to "/profiles/#{params[:id]}"
  end

  def index
  end

  def show
    # Github authentication (shouldn't share secret here, but anyway..)
    auth_str = '?client_id=e70d1009b69c73e947f8&client_secret=5afe5b91d674a8f138c4dfbe9691f5d27164ded0'

    user = params[:id]

    # Create rest request URL to get list of public repos belonging to the user
    api_url = "https://api.github.com"
    url = "#{api_url}/users/#{user}/repos"
    resp = Net::HTTP.get_response(URI.parse(url + auth_str))

    # Parse the Json response to a hash
    resp = JSON.parse(resp.body)

    # Map the repo names to a new array
    projects = resp.map{|r| r["name"]} 

    # 'Master language hash' that stores the amount of bytes written in each language
    #  i.e lang_hash["Ruby"] returns the bytes of ruby code written across all repos
    lang_hash = Hash.new(0)
    
    # vars for Thread handling
#    mutex1 = Mutex.new
#    threads = Hash.new

    # Loop through each repo/project and request the languages used in each repo
    projects.each do |p|
      
      # Create a thread that handles the api call for getting languages
#      threads[p] = Thread.new do

        # URL to grab Json data containing languages used in a project
        lang_url = "#{api_url}/repos/#{user}/#{p}/languages"
        
        resp = Net::HTTP.get_response(URI.parse(lang_url + auth_str))
        resp = JSON.parse(resp.body)

        # Loop through the response and add the amount of bytes written in each language
        #  to the 'master languages hash'
#        mutex1.synchronize do # Lock access to the main lang_hash hash
          resp.each do |lang, bytes|
            lang_hash[lang] += bytes.to_i
          end
#        end
#      end

    end

    # Pause main thread until all threads have finished
#    threads.each do |project, thread|
#      thread.join
#    end

    @lang_hash = lang_hash
  end

  def show_threads
    # Github authentication (shouldn't share secret here, but anyway..)
    auth_str = '?client_id=e70d1009b69c73e947f8&client_secret=5afe5b91d674a8f138c4dfbe9691f5d27164ded0'

    user = params[:id]

    # Create rest request URL to get list of public repos belonging to the user
    api_url = "https://api.github.com"
    url = "#{api_url}/users/#{user}/repos"
    resp = Net::HTTP.get_response(URI.parse(url + auth_str))

    # Parse the Json response to a hash
    resp = JSON.parse(resp.body)

    # Map the repo names to a new array
    projects = resp.map{|r| r["name"]} 

    # 'Master language hash' that stores the amount of bytes written in each language
    #  i.e lang_hash["Ruby"] returns the bytes of ruby code written across all repos
    lang_hash = Hash.new(0)
    
    # vars for Thread handling
    mutex1 = Mutex.new
    threads = Hash.new

    # Loop through each repo/project and request the languages used in each repo
    projects.each do |p|
      
      # Create a thread that handles the api call for getting languages
      threads[p] = Thread.new do

        # URL to grab Json data containing languages used in a project
        lang_url = "#{api_url}/repos/#{user}/#{p}/languages"
        
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

    @lang_hash = lang_hash
  end
end
