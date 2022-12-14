get '/monitores' do
  authorize!
  @dru = []
  Dru.order(:nome).pluck(:id, :nome).each do |id,nome|
    @dru << { "label": "#{nome}", "value": "#{nome}" }
  end
  @dru = @dru.to_json

  @jornada = []
  Jornada.order(:nome).pluck(:id, :nome).each do |id,nome|
    @jornada << { "label": "#{nome}", "value": "#{nome}" }
  end
  @jornada = @jornada.to_json

  @produto = []
  Produto.order(:nome).pluck(:id, :nome).each do |id,nome|
    @produto << { "label": "#{nome}", "value": "#{nome}" }
  end
  @produto = @produto.to_json

  @microservico = []
  Microservico.order(:nome).pluck(:id, :nome).each do |id,nome|
    @microservico << { "label": "#{nome}", "value": "#{nome}" }
  end
  @microservico = @microservico.to_json

  @sintoma = []
  Sintoma.order(:nome).pluck(:id, :nome).each do |id,nome|
    @sintoma << { "label": "#{nome}", "value": "#{nome}" }
  end
  @sintoma = @sintoma.to_json

  @statusmonitoracao = []
  StatusMonitoracao.order(:nome).pluck(:id, :nome).each do |id,nome|
    @statusmonitoracao << { "label": "#{nome}", "value": "#{nome}" }
  end
  @statusmonitoracao = @statusmonitoracao.to_json

  erb :monitores
end

post '/monitoresimportar' do
  authorize!
  arq = params[:file][:filename]
  file = params[:file][:tempfile]
  arqdata = Time.now.strftime('%Y%m%d%H%M%S')
  File.open("./arqs/recebidos/#{arq}_#{arqdata}", 'wb') do |f|
    f.write(file.read)
  end
  @filename = "arqs/recebidos/#{arq}_#{arqdata}"
  begin
    doc = Roo::Excelx.new(@filename, file_warning: :ignore)
    puts doc.info
  rescue Exception => e
    redirect "/monitoresimportarerro"
  end

  ids = []
  Monitores.pluck(:monitor_id).each do |monitor_id|
    ids << monitor_id
  end

  @inseridos = []
  @nao_inseridos = []
  @sem_monitor_id = []

  aba1 = doc.sheet(0)
  aba1.each_row_streaming(pad_cells: true, offset: 1) do |row|
    dru = row[1].value.strip rescue ''
    jornada = row[2].value.strip rescue ''
    produto = row[3].value.strip rescue ''
    titulo = row[4].value.strip rescue ''
    microservico = row[5].value.strip rescue ''
    sintoma = row[6].value.strip rescue ''
    dashboard = row[7].value.strip rescue ''
    impacto_it = row[8].value.strip rescue ''
    impacto_negocio = row[9].value.strip rescue ''
    integracao_jira2 = row[10].value.strip rescue false
    if integracao_jira2.downcase == 'sim'
      integracao_jira = true
    else
      integracao_jira = false
    end
    taxonomia2 = row[11].value.strip rescue false
    if taxonomia2.downcase == 'sim'
      taxonomia = true
    else
      taxonomia = false
    end
    tag_ccbp2 = row[12].value.strip rescue false
    if tag_ccbp2.downcase == 'sim'
      tag_ccbp = true
    else
      tag_ccbp = false
    end
    prioridade = row[13].value.strip rescue ''
    monitor_id = row[14].value rescue ''
    status = row[15].value.strip rescue ''
    data_ativacao = row[16].value.to_datetime rescue nil
    data_desativacao = row[18].value.to_datetime rescue nil

    dru_reg = Dru.where(:nome => dru).first.id rescue nil
    jornada_reg = Jornada.where(:nome => jornada).first.id rescue nil
    produto_reg = Produto.where(:nome => produto).first.id rescue nil
    microservico_reg = Microservico.where(:nome => microservico).first.id rescue nil
    sintoma_reg = Sintoma.where(:nome => sintoma).first.id rescue nil
    status_monitoracao_reg = StatusMonitoracao.where(:nome => status).first.id rescue nil

    if !monitor_id || monitor_id == ''
      @sem_monitor_id << row[0].value + 1
    elsif ids.include?(monitor_id)
      monitor = Monitores.includes(:dru).where(:monitor_id => monitor_id).first
      @nao_inseridos << [monitor_id, monitor.titulo, monitor.dru.nome]
    else
      reg = Monitores.new(
        :monitor_id => monitor_id,
        :titulo => titulo,
        :dru_id => dru_reg,
        :jornada_id => jornada_reg,
        :produto_id => produto_reg,
        :microservico_id => microservico_reg,
        :sintoma_id => sintoma_reg,
        :dashboard => dashboard,
        :impacto_it => impacto_it,
        :impacto_negocio => impacto_negocio,
        :integracao_jira => integracao_jira,
        :taxonomia => taxonomia,
        :tag_ccbp => tag_ccbp,
        :prioridade => prioridade,
        :status => true,
        :status_monitoracao_id => status_monitoracao_reg,
        :data_ativacao => data_ativacao,
        :data_desativacao => data_desativacao
      )
      changes = reg.changes.to_json
      changed = reg.changed
      reg.save
      nomedru = Dru.find(dru_reg).nome rescue '<span style="color:red;">não localizada</span>'
      nomejornada = Jornada.find(jornada_reg).nome rescue '<span style="color:red;">não localizada</span>'
      nomeproduto = Produto.find(produto_reg).nome rescue '<span style="color:red;">não localizado</span>'
      nomemicroservico = Microservico.find(microservico_reg).nome rescue '<span style="color:red;">não localizado</span>'
      nomesintoma = Sintoma.find(sintoma_reg).nome rescue '<span style="color:red;">não localizado</span>'
      nomestatusmonitoracao = StatusMonitoracao.find(status_monitoracao_reg).nome rescue '<span style="color:red;">não localizado</span>'

      @inseridos << [reg.monitor_id, reg.titulo, nomedru, nomejornada, nomeproduto, nomemicroservico, nomesintoma, nomestatusmonitoracao]
      reg_audit = {"descricao"=>"MONITOR registro criado por planilha",
                   "usuario"=>session[:user_id],
                   "processo"=>"monitores",
                   "registro_id" => reg.id,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end

  erb :monitoresimportarresultado, :layout => false
end

get '/monitoresimportarerro' do
  authorize!
  if params[:erro]
    if params[:erro] == 'template'
      @erro = "Parece que a planilha não está no padrão para importação de monitores."
    else
      @erro = params[:erro]
    end
  else
    @erro = "O arquivo importado não está no formato XLSX"
  end
  erb :monitoresimportarerro, :layout => false
end

get '/monitorespopular' do
  authorize!
  content_type 'application/json'
  I18n.locale = 'pt-BR'
  data = Monitores.includes(:dru, :jornada, :produto, :microservico, :sintoma, :statusmonitoracao).order(monitor_id: :asc)
                     .to_json( :include => {
                       :dru => { :only => [:nome] },
                       :jornada => { :only => [:nome] },
                       :produto => { :only => [:nome] },
                       :microservico => { :only => [:nome] },
                       :sintoma => { :only => [:nome] },
                       :statusmonitoracao => { :only => [:nome] }
                     },
                               :only => [:id,
                                         :monitor_id,
                                         :titulo,
                                         :dashboard,
                                         :impacto_it,
                                         :impacto_negocio,
                                         :integracao_jira,
                                         :taxonomia,
                                         :tag_ccbp,
                                         :prioridade,
                                         :data_ativacao,
                                         :data_desativacao,
                                         :dru_id,
                                         :jornada_id,
                                         :produto_id,
                                         :microservico_id,
                                         :sintoma_id,
                                         :status_monitoracao_id
                               ])

  data2 = JSON.parse(data)
  data2.each_with_index do |a,i|
    data2[i]["dru"] = { nome: ''} if !data2[i]["dru"]
    data2[i]["jornada"] = { nome: ''} if !data2[i]["jornada"]
    data2[i]["produto"] = { nome: ''} if !data2[i]["produto"]
    data2[i]["microservico"] = { nome: ''} if !data2[i]["microservico"]
    data2[i]["sintoma"] = { nome: ''} if !data2[i]["sintoma"]
    data2[i]["statusmonitoracao"] = { nome: ''} if !data2[i]["statusmonitoracao"]
  end
  data2.to_json

end

post '/monitoresatualizar' do
  authorize!
  content_type 'application/json'
  if params[:action] == 'edit'
    params[:data].each do |a,b|
      @id = a
      @reg = Monitores.find(a)
      p b
      @reg.assign_attributes(b)
      changes = @reg.changes.to_json
      changed = @reg.changed
      @reg.save
      reg_audit = {"descricao"=>"MONITOR atualizado",
                   "usuario"=>session[:user_id],
                   "processo"=>"monitores",
                   "registro_id" => a,
                   "alteracoes" => changes,
                   "campos" => changed
      }
      audit = Auditoria.new(reg_audit)
      audit.save
    end
  end

  data = Monitores.includes(:dru, :jornada, :produto, :microservico, :sintoma, :statusmonitoracao).find(@id)
                  .to_json( :include => {
                    :dru => { :only => [:nome] },
                    :jornada => { :only => [:nome] },
                    :produto => { :only => [:nome] },
                    :microservico => { :only => [:nome] },
                    :sintoma => { :only => [:nome] },
                    :statusmonitoracao => { :only => [:nome] }
                  },
                            :only => [:id,
                                      :monitor_id,
                                      :titulo,
                                      :dashboard,
                                      :impacto_it,
                                      :impacto_negocio,
                                      :integracao_jira,
                                      :taxonomia,
                                      :tag_ccbp,
                                      :prioridade,
                                      :data_ativacao,
                                      :data_desativacao,
                                      :dru_id,
                                      :jornada_id,
                                      :produto_id,
                                      :microservico_id,
                                      :sintoma_id,
                                      :status_monitoracao_id
                            ])
  data
end

