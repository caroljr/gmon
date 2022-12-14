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
  admin!
  @users = Usuario.where.not(username: 'master.kalendae').order(:username).distinct
  erb :admusuarios
end

get '/admcriarusuario' do
  authorize!
  admin!
  @grupos = Grupo.where.not(identificador: 'rp3_master_kalendae').order(:nome).pluck(:id,:nome)
  @lobs = Lob.order(:lob).pluck(:id,:lob)
  @paineis = Painel.order(:painel).pluck(:id,:painel)
  @mapas = Mapa.order(:mapa).pluck(:id,:mapa)
  @relatorios = Relatorio.order(:relatorio).pluck(:id,:relatorio)
  erb :admcriarusuario
end

post '/admcriarusuario' do
  authorize!
  admin!
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
  array1 = []
  array2 = []
  if params[:grupos]
    params[:grupos].each do |a|
      array1 << a.to_i
    end
  end
  adicionar = find_missing(array1, array2)
  listagrupos = ''
  adicionar.each do |a|
    grupo = Grupo.find(a)
    user.grupos << grupo
    listagrupos = listagrupos + grupo.nome + " "
  end

  array1 = []
  array2 = []
  if params[:lobs]
    params[:lobs].each do |a|
      array1 << a.to_i
    end
  end
  adicionar = find_missing(array1, array2)
  listalobs = ''
  adicionar.each do |a|
    lob = Lob.find(a)
    user.lobs << lob
    listalobs = listalobs + lob.lob + " "
  end

  array1 = []
  array2 = []
  if params[:paineis]
    params[:paineis].each do |a|
      array1 << a.to_i
    end
  end
  adicionar = find_missing(array1, array2)
  listapaineis = ''
  adicionar.each do |a|
    painel = Painel.find(a)
    user.paineis << painel
    listapaineis = listapaineis + painel.painel + " "
  end

  array1 = []
  array2 = []
  if params[:relatorios]
    params[:relatorios].each do |a|
      array1 << a.to_i
    end
  end
  adicionar = find_missing(array1, array2)
  listarelatorios = ''
  adicionar.each do |a|
    relatorio = Relatorio.find(a)
    user.relatorios << relatorio
    listarelatorios = listarelatorios + relatorio.relatorio + " "
  end

  array1 = []
  array2 = []
  if params[:mapas]
    params[:mapas].each do |a|
      array1 << a.to_i
    end
  end
  adicionar = find_missing(array1, array2)
  listamapas = ''
  adicionar.each do |a|
    mapa = Mapa.find(a)
    user.mapas << mapa
    listamapas = listamapas + mapa.mapa + " "
  end

  reg_audit1 = {:usuario => session[:user_id],
               :processo => 'rP3 - administracao',
               :descricao => "#{request.ip} - usuário #{user.username} criado"
  }
  reg_audit2 = {:usuario => session[:user_id],
                :processo => 'rP3 - administracao',
                :descricao => "#{request.ip} - usuário #{user.username} Grupos adicionados: #{listagrupos}"
  }
  reg_audit3 = {:usuario => session[:user_id],
                :processo => 'rP3 - administracao',
                :descricao => "#{request.ip} - usuário #{user.username} LOBs adicionadas: #{listalobs}"
  }
  reg_audit4 = {:usuario => session[:user_id],
                :processo => 'rP3 - administracao',
                :descricao => "#{request.ip} - usuário #{user.username} Painéis adicionados: #{listapaineis}"
  }
  reg_audit5 = {:usuario => session[:user_id],
                :processo => 'rP3 - administracao',
                :descricao => "#{request.ip} - usuário #{user.username} Relatórios adicionados: #{listarelatorios}"
  }
  reg_audit6 = {:usuario => session[:user_id],
                :processo => 'rP3 - administracao',
                :descricao => "#{request.ip} - usuário #{user.username} Mapas de calor adicionados: #{listamapas}"
  }
  audit = Auditoria.create(reg_audit1)
  audit = Auditoria.create(reg_audit2)
  audit = Auditoria.create(reg_audit3) if !listalobs.empty?
  audit = Auditoria.create(reg_audit4) if !listapaineis.empty?
  audit = Auditoria.create(reg_audit5) if !listarelatorios.empty?
  audit = Auditoria.create(reg_audit6) if !listamapas.empty?

  redirect '/admusuarios'
end

post '/admeditarusuario' do
  authorize!
  admin!
  @grupos = Grupo.where.not(identificador: 'rp3_master_kalendae').order(:nome).pluck(:id,:nome)
  @lobs = Lob.order(:lob).pluck(:id,:lob)
  @paineis = Painel.order(:painel).pluck(:id,:painel)
  @mapas = Mapa.order(:mapa).pluck(:id,:mapa)
  @relatorios = Relatorio.order(:relatorio).pluck(:id,:relatorio)
  @user = Usuario.includes(:grupos,:lobs,:paineis,:mapas,:relatorios).find(params[:id])
  erb :admeditarusuario
end

post '/admsubmiteditarusuario' do
  authorize!
  admin!
  user = Usuario.find(params[:id])
  old1 = user.to_json.split(",")
  username = user.username

  user.assign_attributes(params[:users])
  changes = user.changes.to_json
  changed = user.changed
  user.save

  array1 = []
  array2 = []
  if params[:grupos]
    params[:grupos].each do |a|
      array1 << a.to_i
    end
  end
  reg2 = user.grupos.pluck(:id, :nome)
  if !reg2.empty?
    old2 = ''
    reg2.each do |r|
      array2 << r[0].to_i
      old2 = old2 + r[1] + ' '
    end
  end
  adicionar = find_missing(array1, array2)
  remover = find_missing(array2, array1)
  adicionar.each do |a|
    grupo = Grupo.find(a)
    user.grupos << grupo
  end
  remover.each do |a|
    grupo = Grupo.find(a)
    user.grupos.destroy(grupo)
  end

  if !changed.empty?
    reg_audit = {:usuario => session[:user_id],
                 :processo => 'rP3 - administracao',
                 :descricao => "#{request.ip} - usuário #{username} alterado",
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.create(reg_audit)
  end

  if !adicionar.empty? || !remover.empty?
    adicionarnome = []
    removernome = []
    adicionar.each do |ad|
      adicionarnome << Grupo.find(ad).nome
    end
    remover.each do |rm|
      removernome << Grupo.find(rm).nome
    end
    reg_audit2 = {:usuario => session[:user_id],
                  :processo => 'rP3 - administracao',
                  :descricao => "#{request.ip} - usuário #{username} grupos alterados",
                  "alteracoes" => {:'adicionados' => [adicionarnome], :'removidos' => [removernome] },
                  "campos" => ['Grupos']
    }
    audit = Auditoria.new(reg_audit2)
    audit.save
  end

  ## LOBs
  if params[:lobs]
    array1 = []
    array2 = []
    params[:lobs].each do |a|
      array1 << a.to_i
    end
    reg2 = user.lobs.pluck(:id, :lob)
    if !reg2.empty?
      old2 = ''
      reg2.each do |r|
        array2 << r[0].to_i
        old2 = old2 + r[1] + ' '
      end
    end
    adicionar = find_missing(array1, array2)
    remover = find_missing(array2, array1)
    adicionar.each do |a|
      lob = Lob.find(a)
      user.lobs << lob
    end
    remover.each do |a|
      lob = Lob.find(a)
      user.lobs.destroy(lob)
    end

    if !adicionar.empty? || !remover.empty?
      adicionarnome = []
      removernome = []
      adicionar.each do |ad|
        adicionarnome << Lob.find(ad).lob
      end
      remover.each do |rm|
        removernome << Lob.find(rm).lob
      end
      reg_audit2 = {:usuario => session[:user_id],
                    :processo => 'rP3 - administracao',
                    :descricao => "#{request.ip} - usuário #{username} LOBs alteradas",
                    "alteracoes" => {:'adicionados' => [adicionarnome], :'removidos' => [removernome] },
                    "campos" => ['LOBs']
      }
      audit = Auditoria.new(reg_audit2)
      audit.save
    end
  end

  ## Painéis
  if params[:paineis]
    array1 = []
    array2 = []
    params[:paineis].each do |a|
      array1 << a.to_i
    end
    reg2 = user.paineis.pluck(:id, :painel)
    if !reg2.empty?
      old2 = ''
      reg2.each do |r|
        array2 << r[0].to_i
        old2 = old2 + r[1] + ' '
      end
    end
    adicionar = find_missing(array1, array2)
    remover = find_missing(array2, array1)
    adicionar.each do |a|
      painel = Painel.find(a)
      user.paineis << painel
    end
    remover.each do |a|
      painel = Painel.find(a)
      user.paineis.destroy(painel)
    end

    if !adicionar.empty? || !remover.empty?
      adicionarnome = []
      removernome = []
      adicionar.each do |ad|
        adicionarnome << Painel.find(ad).painel
      end
      remover.each do |rm|
        removernome << Painel.find(rm).painel
      end
      reg_audit2 = {:usuario => session[:user_id],
                    :processo => 'rP3 - administracao',
                    :descricao => "#{request.ip} - usuário #{username} Painéis alterados",
                    "alteracoes" => {:'adicionados' => [adicionarnome], :'removidos' => [removernome] },
                    "campos" => ['LOBs']
      }
      audit = Auditoria.new(reg_audit2)
      audit.save
    end
  end

  ## Relatórios
  if params[:relatorios]
    array1 = []
    array2 = []
    params[:relatorios].each do |a|
      array1 << a.to_i
    end
    reg2 = user.relatorios.pluck(:id, :relatorio)
    if !reg2.empty?
      old2 = ''
      reg2.each do |r|
        array2 << r[0].to_i
        old2 = old2 + r[1] + ' '
      end
    end
    adicionar = find_missing(array1, array2)
    remover = find_missing(array2, array1)
    adicionar.each do |a|
      relatorio = Relatorio.find(a)
      user.relatorios << relatorio
    end
    remover.each do |a|
      relatorio = Relatorio.find(a)
      user.relatorios.destroy(relatorio)
    end

    if !adicionar.empty? || !remover.empty?
      adicionarnome = []
      removernome = []
      adicionar.each do |ad|
        adicionarnome << Relatorio.find(ad).relatorio
      end
      remover.each do |rm|
        removernome << Relatorio.find(rm).relatorio
      end
      reg_audit2 = {:usuario => session[:user_id],
                    :processo => 'rP3 - administracao',
                    :descricao => "#{request.ip} - usuário #{username} Relatórios alterados",
                    "alteracoes" => {:'adicionados' => [adicionarnome], :'removidos' => [removernome] },
                    "campos" => ['LOBs']
      }
      audit = Auditoria.new(reg_audit2)
      audit.save
    end
  end

  ## Mapas de calor
  if params[:mapas]
    array1 = []
    array2 = []
    params[:mapas].each do |a|
      array1 << a.to_i
    end
    reg2 = user.mapas.pluck(:id, :mapa)
    if !reg2.empty?
      old2 = ''
      reg2.each do |r|
        array2 << r[0].to_i
        old2 = old2 + r[1] + ' '
      end
    end
    adicionar = find_missing(array1, array2)
    remover = find_missing(array2, array1)
    adicionar.each do |a|
      mapa = Mapa.find(a)
      user.mapas << mapa
    end
    remover.each do |a|
      mapa = Mapa.find(a)
      user.mapas.destroy(mapa)
    end

    if !adicionar.empty? || !remover.empty?
      adicionarnome = []
      removernome = []
      adicionar.each do |ad|
        adicionarnome << Mapa.find(ad).mapa
      end
      remover.each do |rm|
        removernome << Mapa.find(rm).mapa
      end
      reg_audit2 = {:usuario => session[:user_id],
                    :processo => 'rP3 - administracao',
                    :descricao => "#{request.ip} - usuário #{username} Mapas alterados",
                    "alteracoes" => {:'adicionados' => [adicionarnome], :'removidos' => [removernome] },
                    "campos" => ['LOBs']
      }
      audit = Auditoria.new(reg_audit2)
      audit.save
    end
  end

  redirect '/admusuarios'
end

post '/admstatususuario' do
  authorize!
  admin!
  if params[:status]
    Usuario.find(params[:id]).update_attribute(:status, true)
  else
    Usuario.find(params[:id]).update_attribute(:status, false)
  end
  redirect '/admusuarios'
end

post '/admexcluirusuario' do
  authorize!
  admin!
  if params[:id]
    u = Usuario.find(params[:id])
    listagrupos = ''
    u.grupos.each do |g|
      listagrupos = listagrupos + g.nome + ' '
    end

    reg_audit = {:usuario => session[:user_id],
                 :processo => 'rP3 - administracao',
                 :descricao => "#{request.ip} - usuário #{u.username} excluído",
                 "alteracoes" => {:'camposexcluidos' => [u.to_json], :'gruposexcluidos' => [listagrupos] },
                 "campos" => ['Todos']
    }
    audit = Auditoria.create(reg_audit)

    u.destroy!
  end
  redirect '/admusuarios'
end

post '/admstatuseditar' do
  authorize!
  admin!
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
               :processo => 'rP3 - administracao',
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
    data << {
      campo: a.keys[0].to_s,
      valores: a.values[0]
    }
  end
  data.to_json
end
