class Monitores < ActiveRecord::Base
  self.table_name = 'monitores'
  belongs_to :dru
  belongs_to :jornada
  belongs_to :produto
  belongs_to :microservico
  belongs_to :sintoma, class_name: :Sintoma
  belongs_to :statusmonitoracao, class_name: :StatusMonitoracao, foreign_key: "status_monitoracao_id"
end

class Dru < ActiveRecord::Base
  self.table_name = 'dru'
end

class Jornada < ActiveRecord::Base
  self.table_name = 'jornada'
end

class Produto < ActiveRecord::Base
  self.table_name = 'produto'
end

class Microservico < ActiveRecord::Base
  self.table_name = 'microservico'
end

class Sintoma < ActiveRecord::Base
  self.table_name = 'sintoma'
end

class StatusMonitoracao < ActiveRecord::Base
  self.table_name = 'status_monitoracao'
end

