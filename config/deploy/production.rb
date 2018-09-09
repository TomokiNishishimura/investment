set :stage, :production
set :rails_env, 'production'

set :branch, ENV['BRANCH_NAME'] || 'master'

set :migration_role, 'db'

# server-based syntax
server 'xxx.xxx.xxx.xxx', user: 'your_user_name', roles: %w{web app db}

# Custom SSH Options
set :ssh_options, {
    keys: %w{~/.ssh/your_ssh_key},
    forward_agent: true,
    auth_methods: %w(publickey)
}
