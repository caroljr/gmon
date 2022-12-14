def gera_tag(str)
  texto = str.strip.downcase
  texto = texto.gsub(/'+/, '')
  texto = texto.gsub(/"+/, '')
  texto = texto.gsub(/\*+/, '')
  texto = texto.gsub(/=+/, '')
  texto = texto.gsub(/~+/, '')
  texto = texto.gsub(/\++/, '-mais-')
  texto = texto.gsub(/ +/, '-')
  texto = texto.gsub(/_+/, '-')
  texto = texto.gsub(/\[+/, '-')
  texto = texto.gsub(/]+/, '-')
  texto = texto.gsub(/\{+/, '-')
  texto = texto.gsub(/}+/, '-')
  texto = texto.gsub(/\(+/, '-')
  texto = texto.gsub(/\)+/, '-')
  texto = texto.gsub(/\/+/, '-')
  texto = texto.gsub(/\\+/, '-')
  texto = texto.gsub(/\|+/, '-')
  texto = texto.gsub(/<+/, '-')
  texto = texto.gsub(/>+/, '-')
  texto = texto.gsub(/\.+/, '-')
  texto = texto.gsub(/,+/, '-')
  texto = texto.gsub(/;+/, '-')
  texto = texto.gsub(/&+/, '-')
  texto = texto.gsub(/%+/, '-')
  texto = texto.gsub(/\$+/, '-')
  texto = texto.gsub(/#+/, '-')
  texto = texto.gsub(/@+/, '-')
  texto = texto.gsub(/!+/, '-')
  texto = texto.gsub(/á|à|ã|â/, 'a')
  texto = texto.gsub(/é|è|ẽ|ê/, 'e')
  texto = texto.gsub(/í|ì|ĩ/, 'i')
  texto = texto.gsub(/ó|ò|õ|ô/, 'o')
  texto = texto.gsub(/ú|ù|ũ/, 'u')
  texto = texto.gsub(/ç/, 'c')
  texto = texto.gsub(/º/, 'o')
  texto = texto.gsub(/ª/, 'a')
  texto = texto.gsub(/-+/, '-')
  texto = texto.chomp("-")
  if texto[0..0] == '-'
    texto = texto[1..-1]
  end

  return texto
end

get '/atualizartags' do
  authorize!
  reg = Dru.all
  reg.each do |dru|
    dru.assign_attributes("tag": gera_tag(dru["nome"]))
    dru.save
  end
  reg2 = Jornada.all
  reg2.each do |jornada|
    jornada.assign_attributes("tag": gera_tag(jornada["nome"]))
    jornada.save
  end
  reg3 = Produto.all
  reg3.each do |produto|
    produto.assign_attributes("tag": gera_tag(produto["nome"]))
    produto.save
  end
  reg4 = Microservico.all
  reg4.each do |microservico|
    microservico.assign_attributes("tag": gera_tag(microservico["nome"]))
    microservico.save
  end
  reg5 = Sintoma.all
  reg5.each do |sintoma|
    sintoma.assign_attributes("tag": gera_tag(sintoma["nome"]))
    sintoma.save
  end
  "ok"
end

get '/catalogo' do
  authorize!

  erb :catalogo
end

get '/drupopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Dru.order(nome: :asc)
                     .to_json( :only => [:id,
                                         :nome,
                                         :tag,
                                         :status
                               ])
  data
end

post '/druatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    campo = params[:data].flatten()[1].flatten()[0]
    valor0 = params[:data].flatten()[1].flatten()[1]
    if campo == "status"
      if valor0 == "true"
        valor = true
      else
        valor = false
      end
      @reg = Dru.find(id)
      @reg.assign_attributes("#{campo}": valor)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"DRU atualizada",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    else
      @reg = Dru.find(id)
      @reg.assign_attributes("#{campo}": valor0)
      @reg.assign_attributes("tag": gera_tag(@reg["nome"]))
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"DRU atualizada",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :tag,
                                 :status
  ])
  data
end

post '/drucriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data].flatten()[1].flatten()[1]
    status0 = params[:data].flatten()[1].flatten()[3]
    if status0 == "true"
      status = true
    else
      status = false
    end
    tag = gera_tag(nome)
    reg = Dru.new(:nome => nome, :tag => tag, :status => status)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"DRU registro criado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = reg.to_json( :only => [:id,
                                      :nome,
                                      :tag,
                                      :status
  ])
  data
end

get '/jornadapopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Jornada.order(nome: :asc)
            .to_json( :only => [:id,
                                :nome,
                                :tag,
                                :status
            ])
  data
end

post '/jornadaatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    campo = params[:data].flatten()[1].flatten()[0]
    valor0 = params[:data].flatten()[1].flatten()[1]
    if campo == "status"
      if valor0 == "true"
        valor = true
      else
        valor = false
      end
      @reg = Jornada.find(id)
      @reg.assign_attributes("#{campo}": valor)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Jornada atualizada",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    else
      @reg = Jornada.find(id)
      @reg.assign_attributes("#{campo}": valor0)
      @reg.assign_attributes("tag": gera_tag(@reg["nome"]))
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Jornada atualizada",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :tag,
                                 :status
  ])
  data
end

post '/jornadacriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data].flatten()[1].flatten()[1]
    status0 = params[:data].flatten()[1].flatten()[3]
    if status0 == "true"
      status = true
    else
      status = false
    end
    tag = gera_tag(nome)
    reg = Jornada.new(:nome => nome, :tag => tag, :status => status)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"Jornada registro criado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = reg.to_json( :only => [:id,
                                :nome,
                                :tag,
                                :status
  ])
  data
end

get '/produtopopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Produto.order(nome: :asc)
                .to_json( :only => [:id,
                                    :nome,
                                    :tag,
                                    :status
                ])
  data
end

post '/produtoatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    campo = params[:data].flatten()[1].flatten()[0]
    valor0 = params[:data].flatten()[1].flatten()[1]
    if campo == "status"
      if valor0 == "true"
        valor = true
      else
        valor = false
      end
      @reg = Produto.find(id)
      @reg.assign_attributes("#{campo}": valor)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Produto atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    else
      @reg = Produto.find(id)
      @reg.assign_attributes("#{campo}": valor0)
      @reg.assign_attributes("tag": gera_tag(@reg["nome"]))
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Produto atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :tag,
                                 :status
  ])
  data
end

post '/produtocriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data].flatten()[1].flatten()[1]
    status0 = params[:data].flatten()[1].flatten()[3]
    if status0 == "true"
      status = true
    else
      status = false
    end
    tag = gera_tag(nome)
    reg = Produto.new(:nome => nome, :tag => tag, :status => status)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"Produto registro criado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = reg.to_json( :only => [:id,
                                :nome,
                                :tag,
                                :status
  ])
  data
end

get '/microservicopopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Microservico.order(nome: :asc)
                .to_json( :only => [:id,
                                    :nome,
                                    :tag,
                                    :status
                ])
  data
end

post '/microservicoatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    campo = params[:data].flatten()[1].flatten()[0]
    valor0 = params[:data].flatten()[1].flatten()[1]
    if campo == "status"
      if valor0 == "true"
        valor = true
      else
        valor = false
      end
      @reg = Microservico.find(id)
      @reg.assign_attributes("#{campo}": valor)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Microserviço atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    else
      @reg = Microservico.find(id)
      @reg.assign_attributes("#{campo}": valor0)
      @reg.assign_attributes("tag": gera_tag(@reg["nome"]))
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Microserviço atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :tag,
                                 :status
  ])
  data
end

post '/microservicocriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data].flatten()[1].flatten()[1]
    status0 = params[:data].flatten()[1].flatten()[3]
    if status0 == "true"
      status = true
    else
      status = false
    end
    tag = gera_tag(nome)
    reg = Microservico.new(:nome => nome, :tag => tag, :status => status)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"Microserviço registro criado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = reg.to_json( :only => [:id,
                                :nome,
                                :tag,
                                :status
  ])
  data
end

get '/sintomapopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Sintoma.order(nome: :asc)
                     .to_json( :only => [:id,
                                         :nome,
                                         :tag,
                                         :status
                     ])
  data
end

post '/sintomaatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    campo = params[:data].flatten()[1].flatten()[0]
    valor0 = params[:data].flatten()[1].flatten()[1]
    if campo == "status"
      if valor0 == "true"
        valor = true
      else
        valor = false
      end
      @reg = Sintoma.find(id)
      @reg.assign_attributes("#{campo}": valor)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Sintoma atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    else
      @reg = Sintoma.find(id)
      @reg.assign_attributes("#{campo}": valor0)
      @reg.assign_attributes("tag": gera_tag(@reg["nome"]))
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Sintoma atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :tag,
                                 :status
  ])
  data
end

post '/sintomacriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data].flatten()[1].flatten()[1]
    status0 = params[:data].flatten()[1].flatten()[3]
    if status0 == "true"
      status = true
    else
      status = false
    end
    tag = gera_tag(nome)
    reg = Sintoma.new(:nome => nome, :tag => tag, :status => status)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"Sintoma registro criado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = reg.to_json( :only => [:id,
                                :nome,
                                :tag,
                                :status
  ])
  data
end

get '/statusmonitoracaopopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = StatusMonitoracao.order(nome: :asc)
                .to_json( :only => [:id,
                                    :nome,
                                    :status
                ])
  data
end

post '/statusmonitoracaoatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    campo = params[:data].flatten()[1].flatten()[0]
    valor0 = params[:data].flatten()[1].flatten()[1]
    if campo == "status"
      if valor0 == "true"
        valor = true
      else
        valor = false
      end
      @reg = StatusMonitoracao.find(id)
      @reg.assign_attributes("#{campo}": valor)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Status monitoração atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    else
      @reg = StatusMonitoracao.find(id)
      @reg.assign_attributes("#{campo}": valor0)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"Status monitoração atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"catalogo",
                   "registro_id" => @reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :status
  ])
  data
end

post '/statusmonitoracaocriar' do
  authorize!
  content_type 'text/html'
  if params[:action] == 'create'
    nome = params[:data].flatten()[1].flatten()[1]
    status0 = params[:data].flatten()[1].flatten()[3]
    if status0 == "true"
      status = true
    else
      status = false
    end
    reg = StatusMonitoracao.new(:nome => nome, :status => status)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"Status monitoração registro criado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = reg.to_json( :only => [:id,
                                :nome,
                                :status
  ])
  data
end

post '/gerartag' do
  authorize!
  content_type 'text/html'
  gera_tag(params[:textotag])
end