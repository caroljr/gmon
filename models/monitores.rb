class Mon < ActiveRecord::Base
  self.table_name = 'monitors'
  has_many :monitorsitemsrelations, class_name: :MonitorsItemsRelation
  has_many :items, through: :monitorsitemsrelations
end

class Item < ActiveRecord::Base
  has_many :monitorsitemsrelations, class_name: :MonitorsItemsRelation
  has_many :mons, through: :monitorsitemsrelations
  belongs_to :campo
end

class Campo < ActiveRecord::Base
  has_many :items
end

class MonitorsItemsRelation < ActiveRecord::Base
  belongs_to :mon
  belongs_to :item
end