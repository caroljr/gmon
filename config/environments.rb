configure :production, :development, :homologacao do
	db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/gmon')

	ActiveRecord::Base.establish_connection(
			:adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
			:host     => db.host,
			:username => 'postgres',
			:password => 'moc1998',
			:database => db.path[1..-1],
			:encoding => 'utf8'
	)

end
