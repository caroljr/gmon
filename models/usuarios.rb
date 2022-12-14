class Usuario < ActiveRecord::Base
  has_secure_password
  has_many :gruposusuarios, dependent: :destroy, class_name: :GruposUsuario
  has_many :grupos, through: :gruposusuarios, source: :grupo
end

class Grupo < ActiveRecord::Base
  has_many :gruposusuarios, dependent: :destroy, class_name: :GruposUsuario
  has_many :usuarios, through: :gruposusuarios, source: :usuario
end

class GruposUsuario < ActiveRecord::Base
  belongs_to :usuario
  belongs_to :grupo
end
