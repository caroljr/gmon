#!/usr/bin/env puma

#daemonize true
pidfile '/app/btg/gmon/tmp/pids/puma.pid'
state_path '/app/btg/gmon/tmp/pids/puma.state'
stdout_redirect '/app/btg/gmon/log/stdout', '/app/btg/gmon/log/stderr', true

threads 8, 32
#bind 'unix:///app/btg/gmon/tmp/sockets/puma.sock'
bind 'tcp://0.0.0.0:8080'

workers 2

on_worker_boot do |worker_number|
  ActiveRecord::Base.establish_connection(host: "10.193.198.96", adapter: 'postgresql', database: 'gmon', username: 'postgres', password: "moc1998", pool: '30', encoding: 'utf8')
  if worker_number === 0
    $scheduler_thread = true
  end
end

preload_app!
