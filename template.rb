if yes?("Remove README, public/index.html, public/favicon.ico, and public/images/rails.png? (y/n)")
	%w[README public/index.html public/favicon.ico public/images/rails.png].each do |file|
		run "rm #{file}" if File.exists?('README')
	end
end

if yes?("Use rspec? (y/n)")

	if yes?("Include rspec and rspec-rails as config.gems? (y/n)")
		gem "rspec", :lib => false, :version => ">= 1.3.0"
		gem "rspec-rails", :lib => false, :version => ">= 1.3.0"
	end
	
	if yes?("Install rspec and rspec-rails as system gems? (y/n)")
		rake 'gems:install', :sudo => true
	end

	generate("rspec")
end

if yes?("Would you like to install exception_notifier? (y/n)")
	plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git'
	
	app_controller = File.read("app/controllers/application_controller.rb")
	if app_controller !~ /ExceptionNotifiable/ && yes?("Add 'include ExceptionNotifiable' to application_controller.rb - recommended? (y/n)")
		File.open("app/controllers/application_controller.rb", "w") do |file|
			file.print app_controller.sub("ActionController::Base", "ActionController::Base\n  include ExceptionNotifiable")
		end
	end

	if yes?("Setup exception_notifier.rb initializer - recommended? (y/n)")
		initializer 'exception_notifier.rb', (<<-CODE).gsub(/^\s+/, '')
			ExceptionNotifier.email_prefix = "[#{`pwd`.strip.split("/").last}] "
			ExceptionNotifier.exception_recipients = %w[#{ask("List recipient emails seperated by spaces: ").strip}]
		CODE
	end
end

if yes?("Would you like to install factory_girl? (y/n)")
	run "sudo gem install factory_girl --source http://gemcutter.org"
	gem 'factory_girl', :source => 'http://gemcutter.org'
end



#route "map.root :controller => 'people'"

#generate(:scaffold, "person", "name:string", "address:text", "age:number")

#file 'app/components/foo.rb', (<<-CODE).gsub(/^\s+/, '')
#	load 'deploy' if respond_to?(:namespace) # cap2 differentiator
#	Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
#	load 'config/deploy'
#CODE

#puts "Re-run this template later with: rake rails:template LOCATION=~/template.rb"

#gem 'mislav-will_paginate', :lib => 'will_paginate',  :source => 'http://gems.github.com'

#plugin 'restful-authentication', :git => 'git://github.com/technoweenie/restful-authentication.git'

# Generate restful-authentication user and session
#generate("authenticated", "user session")

# Install and configure capistrano
#run "sudo gem install capistrano" if yes?('Install Capistrano on your local system? (y/n)')

#capify!

#file 'Capfile', <<-FILE
#  load 'deploy' if respond_to?(:namespace) # cap2 differentiator
#  Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
#  load 'config/deploy'
#FILE

