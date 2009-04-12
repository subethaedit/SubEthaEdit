module Tinder
  
  # == Usage
  #
  #   campfire = Tinder::Campfire.new 'mysubdomain'
  #   campfire.login 'myemail@example.com', 'mypassword'
  #   room = campfire.create_room 'New Room', 'My new campfire room to test tinder'
  #   room.speak 'Hello world!'
  #   room.destroy
  class Campfire
    attr_reader :subdomain, :uri

    # Create a new connection to the campfire account with the given +subdomain+.
    # There's an optional +:ssl+ option to use SSL for the connection.
    #
    #   c = Tinder::Campfire.new("mysubdomain", :ssl => true)
    def initialize(subdomain, options = {})
      options = { :ssl => false }.merge(options)
      @cookie = nil
      @subdomain = subdomain
      @uri = URI.parse("#{options[:ssl] ? 'https' : 'http' }://#{subdomain}.campfirenow.com")
    end
    
    # Log in to campfire using your +email+ and +password+
    def login(email, password)
      @logged_in = verify_response(post("login", :email_address => email, :password => password), :redirect_to => url_for)
    end
    
    def logged_in?
      @logged_in
    end
  
    def logout
      returning verify_response(get("logout"), :redirect) do |result|
        @logged_in = !result
      end
    end
  
    # Creates and returns a new Room with the given +name+ and optionally a +topic+
    def create_room(name, topic = nil)
      find_room_by_name(name) if verify_response(post("account/create/room?from=lobby", {:room => {:name => name, :topic => topic}}, :ajax => true), :success)
    end
    
    # Find a campfire room by name
    def find_room_by_name(name)
      link = Hpricot(get.body).search("//h2/a").detect { |a| a.inner_html == name }
      link.blank? ? nil : Room.new(self, link.attributes['href'].scan(/room\/(\d*)$/).to_s, name)
    end
    
    # List the users that are currently chatting in any room
    def users(*room_names)
      users = Hpricot(get.body).search("div.room").collect do |room|
        if room_names.empty? || room_names.include?((room/"h2/a").inner_html)
          room.search("//li.user").collect { |user| user.inner_html }
        end
      end
      users.flatten.compact.uniq.sort
    end

    # Deprecated: only included for backwards compatability
    def host #:nodoc:
      uri.host
    end
    
    # Is the connection to campfire using ssl?
    def ssl?
      uri.scheme == 'https'
    end
  
  private

    def url_for(path = "")
      "#{uri}/#{path}"
    end

    def post(path, data = {}, options = {})
      perform_request(options) do
        returning Net::HTTP::Post.new(url_for(path)) do |request|
          request.add_field 'Content-Type', 'application/x-www-form-urlencoded'
          request.set_form_data flatten(data)
        end
      end
    end
  
    def get(path = nil, options = {})
      perform_request(options) { Net::HTTP::Get.new(url_for(path)) }
    end
  
    def prepare_request(request, options = {})
      returning request do
        request.add_field 'Cookie', @cookie if @cookie
        if options[:ajax]
          request.add_field 'X-Requested-With', 'XMLHttpRequest'
          request.add_field 'X-Prototype-Version', '1.5.0_rc1'
        end
      end
    end
    
    def perform_request(options = {}, &block)
      @request = prepare_request(yield, options)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = ssl?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ssl?
      @response = returning http.request(@request) do |response|
        @cookie = response['set-cookie'] if response['set-cookie']
      end
    end
  
    # flatten a nested hash
    def flatten(params)
      params = params.dup
      params.stringify_keys!.each do |k,v| 
        if v.is_a? Hash
          params.delete(k)
          v.each {|subk,v| params["#{k}[#{subk}]"] = v }
        end
      end
    end

    def verify_response(response, options = {})
      if options.is_a?(Symbol)
        codes = case options
        when :success then [200]
        when :redirect then 300..399
        else raise ArgumentError.new("Unknown response #{options}")
        end
        codes.include?(response.code.to_i)
      elsif options[:redirect_to]
        verify_response(response, :redirect) && response['location'] == options[:redirect_to]
      else
        false
      end
    end
  
  end
end