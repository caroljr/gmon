require 'net/ldap'
require 'sucker_punch'
require 'active_support/all'
require 'active_support/time'
include ActiveSupport::NumberHelper
require 'sinatra'
require 'rake'
require 'rufus/scheduler'
require 'sinatra/activerecord'
require './config/environments'
require 'net/smtp'
require 'imgkit'
require 'pdfkit'
require 'action_view'
require 'encryptor'
require 'securerandom'
require 'working_hours'
require 'zlib'
require 'base64'
require 'nokogiri'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'groupdate'
require 'json'
require 'descriptive-statistics'
require "carrierwave"
require "carrierwave/orm/activerecord"
require 'chronic_duration'
require 'mail'
require 'bcrypt'
require 'paperclip'
require 'paranoia'
require 'rmagick'
require 'avatarly'
require 'time_math'
#require 'axlsx'
require 'betterlorem'
require 'roo'

home_dir = '/app/btg/gmon'
Dir["#{home_dir}/models/*.rb"].each do |file|
  require file
end
Dir["#{home_dir}/routes/*.rb"].each do |file|
  require file
end
Dir["#{home_dir}/jobs/*.rb"].each do |file|
  require file
end
Dir["#{home_dir}/helpers/*.rb"].each do |file|
  require file
end

configure do
  set :protection, except: [:frame_options]
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.load_path = Dir[File.join(settings.root, 'config/locales', '*.yml')]
  I18n.backend.load_translations

  # options = { :address              => "10.244.3.16",
  #             :port                 => 25,
  #             :openssl_verify_mode => "none"
  # }
  # Mail.defaults do
  #   delivery_method :smtp, options
  # end
  enable :logging
end

log = Logger.new(STDOUT)
ActiveRecord::Base.logger = Logger.new(STDOUT)

if settings.environment == :production
  log.info 'SERVICO INICIADO COMO AMBIENTE PRODUCAO'
  set :url, 'https://gmon'
end

if settings.environment == :homologacao
  log.info 'SERVICO INICIADO COMO AMBIENTE HOMOLOGACAO'
  set :url, 'https://gmon'
end

if settings.environment == :development
  log.info 'SERVICO INICIADO COMO AMBIENTE DESENVOLVIMENTO'
  set :url, 'http://192.168.15.9:4569'
end

I18n.locale = 'pt-BR'

configure { set :server, :puma }
Paperclip.options[:command_path] = "/usr/bin/"

require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end

use Rack::Session::Cookie, :key => 'rack.rp3.session',
    :secret => 'segredo%%sessao%%gmon'

CarrierWave.configure do |config|
  config.root = File.dirname(__FILE__) + "/public"
end

helpers do
  def authorize!
    redirect(to('/login')) unless session[:logged_in]
  end
  def admin!
    redirect(to('/')) unless session[:grupo_gmon_admin]
  end

  def isgmonadmin
    if session[:grupo_gmon_admin] == true
      return true
    else
      return false
    end
  end

  def human_boolean(boolean)
    boolean ? 'Sim' : 'Não'
  end

end

get '/login' do
  erb :login, :layout => false
end

post '/login' do
  session[:grupo_gmon_admin] = false
  session[:grupo_gmon_usuario] = false

  user = Usuario.find_by(:username => params[:username])
  if user && user.authenticate(params[:password]) && user.status
    grupos = []
    user.grupos.each do |value|
      if value.identificador == "gmon_admin"
        session[:grupo_gmon_admin] = true
      end
      if value.identificador == "gmon_usuario"
        session[:grupo_gmon_usuario] = true
      end
      grupos << value.identificador
    end

    session[:logged_in] = true
    if session[:logged_in]
      session[:id] = user.id
      session[:user_id] = user.username
      session[:username] = user.username
      session[:nome] = user.nome
      session[:auth] = 'gmon'
      session[:url_inicial] = '/'
      email = "#{session[:username]}@btgpactual.com.br"
      reg_audit = {descricao: "LOGIN SUCESSO IP: #{request.ip}", usuario: session[:user_id], processo: "gmon"}
      audit = Auditoria.create(reg_audit)
      "<script>window.location.href='#{session[:url_inicial]}';</script>"
    else
      reg_audit = {descricao: "LOGIN FALHOU PARA UID: #{params[:username]} IP: #{request.ip}", processo: "gmon"}
      audit = Auditoria.create(reg_audit)
      "<script>bootbox.alert({message:'Seu usuário não tem permissão para acessar o GMON!', size:'small', locale:'pt-br'});</script>"
    end
  else
    reg_audit = {descricao: "LOGIN FALHOU PARA UID: #{params[:username]} IP: #{request.ip}", processo: "gmon"}
    audit = Auditoria.create(reg_audit)
    "<script>bootbox.alert({message:'Confirme seu usuário e senha, e tente novamente!', size:'small', locale:'pt-br'});</script>"
  end
end

get '/esqueceusenha' do
  erb :esqueceusenha, :layout => false
end

post '/esqueceusenha' do
  #TODO validar dados enviados no formulario e enviar email com nova senha para usuario
  redirect '/login'
end

get '/' do
	authorize!
	erb :index
end

get '/admin' do
	authorize!
	erb :admin
end

get '/admlogstdout' do
  authorize!
  admin!
  if File.file?("log/stdout")
    send_file "log/stdout", :filename => "stdout.txt", :disposition => 'attachment', :type => 'text/txt'
    reg_audit = {descricao: "Log stdout acessado por UID: #{params[:username]} IP: #{request.ip}", processo: "gmon"}
    audit = Auditoria.create(reg_audit)
  else
    redirect back
  end
end

get '/admlogstderr' do
  authorize!
  admin!
  if File.file?("log/stderr")
    send_file "log/stderr", :filename => "stderr.txt", :disposition => 'attachment', :type => 'text/txt'
    reg_audit = {descricao: "Log stderr acessado por UID: #{params[:username]} IP: #{request.ip}", processo: "gmon"}
    audit = Auditoria.create(reg_audit)
  else
    redirect back
  end
end

get '/admlogjobs' do
  authorize!
  admin!
  if File.file?("log/sucker_punch.log")
    send_file "log/sucker_punch.log", :filename => "sucker_punch.txt", :disposition => 'attachment', :type => 'text/txt'
    reg_audit = {descricao: "Log jobs acessado por UID: #{params[:username]} IP: #{request.ip}", processo: "gmon"}
    audit = Auditoria.create(reg_audit)
  else
    redirect back
  end
end

get '/logout' do
  reg_audit = {descricao: "LOGOUT", usuario: session[:user_id], processo: "gmon"}
  audit = Auditoria.create(reg_audit)
  session.clear
  redirect '/login'
end
