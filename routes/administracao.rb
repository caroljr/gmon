def find_missing(array1, array2)
  missing_elements = []
  array1.each { |e|
    unless array2.include? e
      missing_elements << e
    end
  }
  return missing_elements
end

get '/admusuarios' do
  authorize!
  @users = Usuario.order(:username).distinct
  erb :admusuarios
end

get '/admcriarusuario' do
  authorize!

  erb :admcriarusuario
end

post '/admcriarusuario' do
  authorize!

  @alerta = 0
  nome = params[:usuario][:nome]
  username = params[:usuario][:username]

  usuario = Usuario.where(:username => username)
  if !usuario.empty?
    @alerta = 1
    redirect '/admcriarusuario?alerta=1'
  end

  params[:usuario][:status] = true
  img = Avatarly.generate_avatar(nome, opts={})
  arq = "public/assets/avatar/#{username}.png"
  File.open(arq, 'wb') do |f|
    f.write img
  end
  user = Usuario.create(params[:usuario])

  reg_audit1 = {:usuario => session[:user_id],
               :processo => 'gmon - administracao',
               :descricao => "#{request.ip} - usuário #{user.username} criado"
  }

  audit = Auditoria.create(reg_audit1)

  redirect '/admusuarios'
end

post '/admeditarusuario' do
  authorize!

  @user = Usuario.find(params[:id])
  erb :admeditarusuario
end

post '/admsubmiteditarusuario' do
  authorize!

  user = Usuario.find(params[:id])
  old1 = user.to_json.split(",")
  username = user.username

  user.assign_attributes(params[:users])
  changes = user.changes.to_json
  changed = user.changed
  user.save

  if !changed.empty?
    reg_audit = {:usuario => session[:user_id],
                 :processo => 'gmon - administracao',
                 :descricao => "#{request.ip} - usuário #{username} alterado",
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.create(reg_audit)
  end
  redirect '/admusuarios'
end

post '/admstatususuario' do
  authorize!

  if params[:status]
    Usuario.find(params[:id]).update_attribute(:status, true)
  else
    Usuario.find(params[:id]).update_attribute(:status, false)
  end
  redirect '/admusuarios'
end

post '/admexcluirusuario' do
  authorize!

  if params[:id]
    u = Usuario.find(params[:id])
    reg_audit = {:usuario => session[:user_id],
                 :processo => 'gmon - administracao',
                 :descricao => "#{request.ip} - usuário #{u.username} excluído",
                 "alteracoes" => u.to_json,
                 "campos" => ['Todos']
    }
    audit = Auditoria.create(reg_audit)

    u.destroy!
  end
  redirect '/admusuarios'
end

post '/admstatuseditar' do
  authorize!

  content_type 'application/json'
  @reg = Usuario.find(params[:id])
  if params[:status] == 'true'
    status = true
    acao = 'ativado'
  else
    status = false
    acao = 'desativado'
  end
  @reg.update(status: status)

  reg_audit = {:usuario => session[:user_id],
               :processo => 'gmon - administracao',
               :descricao => "Usuário #{@reg.nome} foi #{acao}"
  }
  audit = Auditoria.create(reg_audit)

  @reg.to_json
end

get '/alterarsenha' do
  authorize!
  erb :alterarsenha
end

post '/submitalterarsenha' do
  authorize!
  usuario = session[:user_id]
  novasenha = params['novasenha']
  reg = Usuario.find_by(:username => usuario)
  reg.update(password: novasenha)

  reg_audit = {:usuario => session[:user_id],
               :processo => 'gmon - administracao',
               :descricao => "Usuário #{reg.nome} alterou sua senha"
  }
  audit = Auditoria.create(reg_audit)

  redirect '/'
end

get '/auditoria' do
  authorize!
  if params[:inicio] && params[:inicio] != ''
    @ini = params[:inicio]
  else
    @ini = (Date.today - 30.days).strftime('%d-%m-%Y')
  end
  if params[:termino] && params[:termino] != ''
    @ter = params[:termino]
  else
    @ter = Date.today.strftime('%d-%m-%Y')
  end
  erb :auditoria
end

get '/audit1' do
  authorize!
  content_type 'application/json'
  if params[:inicio].nil? || params[:inicio] != ''
    ini = params[:inicio].to_datetime.strftime('%Y-%m-%d 00:00:00') rescue (Date.today - 30.days).strftime('%Y-%m-%d 00:00:00')
  else
    ini = (Date.today - 30.days).strftime('%Y-%m-%d 00:00:00')
  end
  if params[:termino].nil? || params[:termino] != ''
    ter = params[:termino].to_datetime.strftime('%Y-%m-%d 23:59:59') rescue Date.today.strftime('%Y-%m-%d 23:59:59')
  else
    ter = Date.today.strftime('%Y-%m-%d 23:59:59')
  end
  data = Auditoria.where("created_at >= '#{ini}'").where("created_at <= '#{ter}'").order('created_at desc')
                  .to_json(:only => [:id,
                                     :descricao,
                                     :usuario,
                                     :created_at,
                                     :campos,
                                     :alteracoes,
                                     :registro_id
                  ])
  data2 = JSON.parse(data)
  data2.each_with_index do |a,i|
    if data2[i]["campos"]
      campos = ''
      data2[i]["campos"].each do |c|
        campos = campos + c + ', '
      end
      data2[i]["campos"] = campos[0...-2]
    end
    if data2[i]["alteracoes"]
      a = JSON.parse(data2[i]["alteracoes"])
      de = a.values[0][0].to_s rescue ''
      para = a.values[0][1].to_s rescue ''
      alteracoes = a.keys[0].to_s + ': ' + de + ' -> ' + para
      data2[i]["alteracoes"] = alteracoes
    end
  end
  data2.to_json
end

get '/audit2' do
  authorize!
  content_type 'application/json'
  data2 = Auditoria.find_by_id(params[:id]).alteracoes
  data = []
  if data2
    a = JSON.parse(data2)
    a.keys.each do |k|
      data << {
        campo: k,
        valores: a[k]
      }
    end
  end
  data.to_json
end
