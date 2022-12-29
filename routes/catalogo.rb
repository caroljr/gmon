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
  reg = Item.all
  reg.each do |item|
    item.assign_attributes("valor_tag": gera_tag(item["nome"]))
    item.save
  end
  "ok"
end

get '/catalogo' do
  authorize!
  @campos = []
  Campo.order(:nome).pluck(:nome,:id).each do |nome,id|
    @campos << { label: nome, value: id.to_i }
  end
  @campos = @campos.to_json
  erb :catalogo
end

get '/itemspopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Item.includes(:campo).order("campos.nome": :asc, nome: :asc)
                     .to_json( :include => { :campo => { :only => :nome }
                     },
                               :only => [:id,
                                         :nome,
                                         :valor_tag,
                                         :status
                               ])
  data
end

post '/itematualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    @reg = Item.find(id)
    if nome = params[:data][id]["nome"]
      nome = params[:data][id]["nome"]
      @reg.assign_attributes("nome": nome, "valor_tag": gera_tag(nome))
    else
      campo_id = params[:data][id]["campo"]["nome"]
      @reg.assign_attributes("campo_id": campo_id)
    end

    changes = @reg.changes.to_json
    changed = @reg.changed
    @reg.save
    reg_audit = {"descricao"=>"ITEM atualizado",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => @reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :valor_tag,
                                 :status
  ])
  data
end

post '/itemcriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data]["0"]["nome"]
    campo_id = params[:data]["0"]["campo"]["nome"]
    valor_tag = gera_tag(nome)
    reg = Item.new(:nome => nome, :valor_tag => valor_tag, :campo_id => campo_id)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"ITEM registro criado",
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
                                :valor_tag,
                                :status
  ])
  data
end

get '/classespopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Campo.order(nome: :asc).to_json( :only => [:id, :nome, :atributo_tag, :status])
  data
end

post '/classeatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    id = params[:data].flatten()[0]
    @reg = Campo.find(id)
    if nome = params[:data][id]["nome"]
      nome = params[:data][id]["nome"]
      atributo = "ccbp-" + gera_tag(nome)
      @reg.assign_attributes("nome": nome, "atributo_tag": atributo)
    end

    changes = @reg.changes.to_json
    changed = @reg.changed
    @reg.save
    reg_audit = {"descricao"=>"CLASSE atualizada",
                 "usuario"=>session[:user_id],
                 "processo"=>"catalogo",
                 "registro_id" => @reg.id,
                 "alteracoes" => changes,
                 "campos" => changed
    }
    audit = Auditoria.new(reg_audit)
    audit.save
  end
  data = @reg.to_json( :only => [:id,
                                 :nome,
                                 :atributo_tag,
                                 :status
  ])
  data
end

post '/classecriar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'create'
    nome = params[:data]["0"]["nome"]
    atributo = "ccbp-" + gera_tag(nome)
    reg = Campo.new(:nome => nome, :atributo_tag => atributo)
    changes = reg.changes.to_json
    changed = reg.changed
    reg.save
    reg_audit = {"descricao"=>"CLASSE registro criado",
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
                                :atributo_tag,
                                :status
  ])
  data
end


post '/gerartag' do
  authorize!
  content_type 'text/html'
  gera_tag(params[:textotag])
end

get '/consultartag' do
  content_type 'application/json'
  if params[:tag]
    nome = Item.where(:valor_tag => params[:tag]).first.nome rescue nil
    classe = Item.includes(:campo).where(:valor_tag => params[:tag]).first.campo.nome rescue nil
  end
  json = '{ "nome": "' + nome + '", "classe": "' + classe + '" }'
  json.to_json
end

