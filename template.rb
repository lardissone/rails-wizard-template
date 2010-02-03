# Some helpful methods

def y?(s)
  yes?("\n#{s} (y/n)")
end

def maybe_gem_install(s)
  run "sudo gem install #{s}" if y?("sudo gem install #{s}?")
end

def maybe_update_file(options = {})
  old_contents = File.read(options[:file])
  look_for = options[:after] || options[:before] # but not both!
  return if options[:unless_present] && old_contents =~ options[:unless_present]

  if options[:action].nil? || y?("#{options[:action]} to #{options[:file]}?")
    File.open(options[:file], "w") do |file|
      file.print old_contents.sub(look_for, "#{look_for}\n#{options[:content]}") if options[:after]
      file.print old_contents.sub(look_for, "#{options[:content]}\n#{look_for}") if options[:before]
    end

    if old_contents.scan(look_for).length > 1
      puts "\nNOTE: #{options[:file]} may not have been updated correctly, so please take a look at it.\n"
    end
  end
end

# The template

if y?("Remove README, public/index.html, public/favicon.ico, and public/images/rails.png?")
  %w[README public/index.html public/favicon.ico public/images/rails.png].each do |file|
    run "rm #{file}" if File.exists?(file)
  end
end

if y?("Use rspec?")
  gem "rspec", :lib => false, :version => ">= 1.3.0"
  gem "rspec-rails", :lib => false, :version => ">= 1.3.0"

  maybe_gem_install("rspec rspec-rails")

  generate("rspec")
end

if y?("Would you like to install exception_notifier?")
  plugin 'exception_notifier', :svn => 'http://dev.rubyonrails.org/svn/rails/plugins/exception_notification/'

  maybe_update_file :file => "app/controllers/application_controller.rb", :action => "Add 'include ExceptionNotifiable'",
                    :unless_present => /ExceptionNotifiable/, :after => "ActionController::Base", :content => "  include ExceptionNotifiable"

  if y?("Setup exception_notifier.rb initializer?")
    initializer 'exception_notifier.rb', (<<-CODE).gsub(/^\s+/, '')
			ExceptionNotifier.email_prefix = "[#{@root.split('/').last}] "
			ExceptionNotifier.exception_recipients = %w[#{ask("\nList recipient emails seperated by spaces: ").strip}]
    CODE
  end
end

if y?("Would you like to install factory_girl?")
  gem 'factory_girl', :source => 'http://gemcutter.org'
  maybe_gem_install "factory_girl"
  if File.exists?("spec")
    run "mkdir spec/factories" unless File.exists?("spec/factories")
  else
    run "mkdir test/factories" unless File.exists?("test/factories")
  end
end

if y?("Use will_paginate?")
  gem 'will_paginate'
  maybe_gem_install "will_paginate"
end

if y?("Use formtastic?")
  plugin "formtastic", :git => "git://github.com/justinfrench/formtastic.git"
end

if y?("Use authlogic?")
  gem "authlogic"
  maybe_gem_install "authlogic"

  puts
  puts "I can now attempt to create a simple authlogic setup."
  puts "You should NOT do this if you already have a users_controller, "
  puts "a user_sessions_controller, a user model, or a user_session model, as they"
  puts "will be DESTROYED.  If you are just creating this Rails app, then this should"
  puts "hopefully work."
  puts
  puts "Code from: http://github.com/binarylogic/authlogic_example"
  puts
  puts "(Also, this may hang when run on existing Rails apps with any of the above files in place.)"
  puts
  if y?("Should I configure a basic authlogic setup?")
    maybe_update_file :file => "app/controllers/application_controller.rb", :unless_present => /helper_method :current_user_session, :current_user/,
                      :after => "ActionController::Base", :content => "  helper_method :current_user_session, :current_user"

    maybe_update_file :file => "app/controllers/application_controller.rb", :unless_present => /return \@current_user if defined\?\(@current_user\)/,
                      :before => "end", :content => (<<-CODE).gsub(/\A +| +\Z/, '')

  filter_parameter_logging :password, :password_confirmation

  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
    CODE

    generate :session, "user_session"
    generate :controller, "user_sessions"

    generate :rspec_model, "user"

    file 'app/models/user.rb', (<<-CODE).gsub(/\A +| +\Z/, '')
class User < ActiveRecord::Base
  acts_as_authentic
end
    CODE

    file Dir['db/migrate/*_create_users.rb'].first, (<<-CODE).gsub(/\A +| +\Z/, '')
class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string    :login,               :null => false                # optional, you can use email instead, or both
      t.string    :email,               :null => false                # optional, you can use login instead, or both
      t.string    :crypted_password,    :null => false                # optional, see below
      t.string    :password_salt,       :null => false                # optional, but highly recommended
      t.string    :persistence_token,   :null => false                # required
      t.string    :single_access_token, :null => false                # optional, see Authlogic::Session::Params
      t.string    :perishable_token,    :null => false                # optional, see Authlogic::Session::Perishability

      # Magic columns, just like ActiveRecord's created_at and updated_at. These are automatically maintained by Authlogic if they are present.
      t.integer   :login_count,         :null => false, :default => 0 # optional, see Authlogic::Session::MagicColumns
      t.integer   :failed_login_count,  :null => false, :default => 0 # optional, see Authlogic::Session::MagicColumns
      t.datetime  :last_request_at                                    # optional, see Authlogic::Session::MagicColumns
      t.datetime  :current_login_at                                   # optional, see Authlogic::Session::MagicColumns
      t.datetime  :last_login_at                                      # optional, see Authlogic::Session::MagicColumns
      t.string    :current_login_ip                                   # optional, see Authlogic::Session::MagicColumns
      t.string    :last_login_ip                                      # optional, see Authlogic::Session::MagicColumns
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
  CODE

    file 'app/controllers/user_sessions_controller.rb', (<<-CODE).gsub(/\A +| +\Z/, '')
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
  CODE

    file 'app/views/user_sessions/new.html.erb', (<<-CODE).gsub(/\A +| +\Z/, '')
<h1>Login</h1>

<% form_for @user_session, :url => user_session_path do |f| %>
  <%= f.error_messages %>
  <%= f.label :login %><br />
  <%= f.text_field :login %><br />
  <br />
  <%= f.label :password %><br />
  <%= f.password_field :password %><br />
  <br />
  <%= f.check_box :remember_me %><%= f.label :remember_me %><br />
  <br />
  <%= f.submit "Login" %>
<% end %>
CODE

    file 'app/controllers/users_controller.rb', (<<-CODE).gsub(/\A +| +\Z/, '')
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
    CODE

    run "mkdir -p app/views/users"

    file "app/views/users/_form.html.erb", (<<-CODE).gsub(/\A +| +\Z/, '')
<%= form.label :login %><br />
<%= form.text_field :login %><br />
<br />
<%= form.label :email %><br />
<%= form.text_field :email %><br />
<br />
<%= form.label :password, form.object.new_record? ? nil : "Change password" %><br />
<%= form.password_field :password %><br />
<br />
<%= form.label :password_confirmation %><br />
<%= form.password_field :password_confirmation %><br />
    CODE

    file "app/views/users/edit.html.erb", (<<-CODE).gsub(/\A +| +\Z/, '')
<h1>Edit My Account</h1>

<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Update" %>
<% end %>

<br /><%= link_to "My Profile", account_path %>
    CODE

    file "app/views/users/new.html.erb", (<<-CODE).gsub(/\A +| +\Z/, '')
<h1>Register</h1>

<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Register" %>
<% end %>
    CODE

    file "app/views/users/show.html.erb", (<<-CODE).gsub(/\A +| +\Z/, '')
<p>
  <b>Login:</b>
  <%=h @user.login %>
</p>

<p>
  <b>Login count:</b>
  <%=h @user.login_count %>
</p>

<p>
  <b>Last request at:</b>
  <%=h @user.last_request_at %>
</p>

<p>
  <b>Last login at:</b>
  <%=h @user.last_login_at %>
</p>

<p>
  <b>Current login at:</b>
  <%=h @user.current_login_at %>
</p>

<p>
  <b>Last login ip:</b>
  <%=h @user.last_login_ip %>
</p>

<p>
  <b>Current login ip:</b>
  <%=h @user.current_login_ip %>
</p>

<%= link_to 'Edit', edit_account_path %>
    CODE

    route "map.resource :user_session"
    route "map.root :controller => \"user_sessions\", :action => \"new\""
    route "map.resource :account, :controller => \"users\""
    route "map.resources :users"

    rake "db:migrate"
  end
end

if y?("Install and configure capistrano?")
  maybe_gem_install "capistrano"
  run "capify ."
end

puts
puts "Done running the rails-wizard-template!"
puts