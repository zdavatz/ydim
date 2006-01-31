#!/usr/bin/env ruby
# Item -- ydim -- 11.01.2006 -- hwyss@ywesee.com

module YDIM
	class Item
		DATA_KEYS = [ :data, :expiry_time, :item_type, :price, :quantity, :text,
			:time, :unit, :vat_rate ]
		attr_accessor :index, *DATA_KEYS
		def initialize(data={})
			update(data)
		end
		def total_brutto
			total_netto + vat
		end
		def total_netto
			@quantity.to_f * @price.to_f
		end
		def update(data)
			data.each { |key, val|
				if(DATA_KEYS.include?(key.to_sym))
					instance_variable_set("@#{key}", val)
				end
			}
		end
		def vat
			total_netto * (@vat_rate.to_f / 100.0)
		end
	end
	module ItemId
		def next_item_id
			id = @next_item_id.to_i
			@next_item_id = id.next
			id
		end
	end
end
