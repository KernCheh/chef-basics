# execute 'apt-get update' do
#   command 'apt-get update'
# end

# OS Dendencies
%w(git ruby-dev build-essential libsqlite3-dev libssl-dev libreadline-dev).each do |pkg|
  package pkg
end

# Deployer user, sudoer and with known RSA keys
user_account 'deployer' do
  create_group true
end
group 'sudo' do
  action :modify
  members 'deployer'
  append true
end

cookbook_file 'id_rsa' do
  source 'id_rsa'
  path '/home/deployer/.ssh/id_rsa'
  group 'deployer'
  owner 'deployer'
  mode 0600
  action :create
end

cookbook_file 'id_rsa.pub' do
  source 'id_rsa.pub'
  path '/home/deployer/.ssh/id_rsa.pub'
  group 'deployer'
  owner 'deployer'
  mode 0644
  action :create
end

# Allow sudo command without password for sudoers
cookbook_file 'sudo_without_password' do
  source 'sudo_without_password'
  path '/etc/sudoers.d/sudo_without_password'
  group 'root'
  owner 'root'
  mode 0440
  action :create
end

# Authorize yourself to connect to server
cookbook_file 'authorized_keys' do
  source 'authorized_keys'
  path '/home/deployer/.ssh/authorized_keys'
  group 'deployer'
  owner 'deployer'
  mode 0600
  action :create
end

# Add Github as known host
ssh_known_hosts_entry 'github.com'

# Install Ruby Version
# include_recipe 'ruby_build'
#
# ruby_build_ruby '2.3.1'
#
# link '/usr/bin/ruby' do
#   to '/usr/local/ruby/2.3.1/bin/ruby'
# end
#
# gem_package 'bundler' do
#   options '--no-ri --no-rdoc'
# end

ruby_runtime 'any' do
  version '2.3.1'
  provider :ruby_build
end

bash "echo something" do
  code <<-EOF
     echo $(which bundler)
     echo $(ls -al /usr/local/bin)
  EOF
end

# log 'message' do
#   message File.open('/home/deployer/.ssh/id_rsa').read
#   level :info
# end

# Install Rails Application

include_recipe 'runit'

directory '/var/www' do
  owner 'deployer'
  group 'deployer'
  mode '0755'
  action :create
  recursive true
end

application '/var/www/capistrano-first-steps' do
  owner 'deployer'
  group 'deployer'

  git '/var/www/capistrano-first-steps' do
    deploy_key File.open('/home/deployer/.ssh/id_rsa').read
    repository 'git@github.com:gotealeaf/capistrano-first-steps.git'
  end

  bundle_install do
    deployment true
    without %w{development test}
  end

  rails do
    database do
      adapter 'sqlite3'
      database 'db/production.sqlite3'
    end
  end

  unicorn do
    port 8080
  end
end
