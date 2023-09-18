class Asset < ApplicationRecord
    has_one :segment, required:false

end
