class Auditoria < ActiveRecord::Base
  self.table_name = 'auditoria'
  serialize :campos
  serialize :alteracoes
end
