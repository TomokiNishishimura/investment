# config valid for current version and patch releases of Capistrano
lock "~> 3.7.0"

set :application, 'your_app_name'
set :repo_url, 'git@github.com:your_repository.git'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/your_app_root/#{fetch(:application)}"

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto
set :format, :pretty
set :log_level, :debug

set :puma_threads,  [4, 16]
set :puma_workers, 0

# Default value for :pty is false
set :pty, true

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle}

# credentials.yml.encのdecryptに必要。今回は手動で転送する。
set :linked_files, fetch(:linked_files, []).push("config/master.key")

# rbenvをシステムにインストールしたか? or ユーザーローカルにインストールしたか?
set :rbenv_type, :user # :system or :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all # default value

# pumaの設定
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log,  "#{release_path}/log/puma.error.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
# rbenvをユーザローカルにインストールする場合に必要
append :rbenv_map_bins, 'puma', 'pumactl'

# Default value for keep_releases is 5
set :keep_releases, 3

# bundle installの並列実行数
set :bundle_jobs, 4

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end
  before :start, :make_dirs
end

namespace :deploy do
  desc 'Make sure local git is in sync with remote.'
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  desc 'db:seed'
  task :db_seed do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:seed'
        end
      end
    end
  end

  after  :migrate,      :seed
  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
end
