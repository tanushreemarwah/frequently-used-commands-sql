# GENERATE CSV
require 'csv'
file = "#{Rails.root}/orders_data.csv"

headers = ['Consumer Phone' ,'Pin Code', 'City' ,'Order #', 'Shipment # ', 'Product Name', 'Sku ID' ,'MRP' ,'SP' ,'Brand','Payment Status' ,'Delivery Status  / Shipment Status' ,'Essential Flag' ,'Order Date' ,'Expected Dispatch Date' ,'Expected Delivery Date', 'Actual Dispatch Date', 'Actual Delivery Date' ]

orders = Order.left_joins(:user, order_items: :sku)
.left_joins(:shipments, order_address: [pincode: :city])
.where("orders.created_at > ?", Date.today.at_beginning_of_month)
.select("orders.*, skus.id as sku_id, pincodes.id as pincode_id, cities.name as city_name, 
  shipments.id as shipmnet_id, order_items.selling_price as sp, order_items.mrp as mrp,
  coalesce(shipments.aasm_state, orders.aasm_state) as aasm_status,
  shipments.expected_dispatch_date as expected_dispatch_date,
  shipments.expected_delivery_date as expected_delivery_date,
  shipments.actual_dispatch_date as actual_dispatch_date,
  shipments.actual_delivery_date as actual_delivery_date")
.where("orders.aasm_state <> 'awaiting_confirmation'")
.where(source: nil)



CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
  orders.each do |o|
   sku = Sku.find_by(id: o.sku_id)
    writer <<  [o.user.phone_number,  o.pincode_id, o.city_name, o.id, o.shipmnet_id, sku.item.name, o.sku_id,  o.sp, o.mrp, (sku.item.brand.name rescue sku.item.product.brand.name rescue ''), o.payment_status, o.aasm_status, sku.is_essential?, o.created_at, o.expected_dispatch_date, o.expected_delivery_date, o.actual_dispatch_date, o.actual_delivery_date]
    end
end

# UPLOAD
require 'csv'

unparsed_csv = File.read('gp_uniware_created_at.csv')
CSV.parse(unparsed_csv, headers: true).each_with_index do |row, index|
  gp_uniware_creation_at = row['Gatepass Created At']
  uniware_gp_code = row['Gatepass Code']
  gp = Gatepass.find_by(uniware_gatepass_code: uniware_gp_code)
  next if gp.blank? or uniware_gp_code.blank? or gp.created_in_uniware_at.present?
  gp_uniware_creation_at = gp_uniware_creation_at.to_date.strftime('%Y-%m-%d')
  gp.update(created_in_uniware_at: gp_uniware_creation_at, warehouse_id: Warehouse::DTDC_WH.id)
end

require 'csv'
unparsed_csv = File.read('inventory_worth_report.csv')
CSV.parse(unparsed_csv, headers: true).each_with_index do |row, index|
  sku_id = row['Item Type SKU Code']
  available = row['Quantity']
  inv = Inventory.find_by(sku_id: sku_id, organisation_id: 1)
  next if inv.blank? or sku_id.blank? or available.blank?
  inv.available = available
  inv.blocked = 0
  inv.warehouse_id = Warehouse::DTDC_WH.id
  inv.save
end

link,image,title,pack_size,avg_rating,total_ratings,mrp(₹),discount(%),sp(₹)


ShipmentStatusChange.create(shipment_id: shipment_id, from_status: 'ready_to_ship', to_status: 'shipped', changed_at: dispatch_date)

unparsed_csv = File.read('dispatch_date_mapping.csv')
CSV.parse(unparsed_csv, headers: true).each_with_index do |row, index|
  shipment_id = row['shipment_id']
  dispatch_date = row['dispatch_date']
  shipment = Shipment.find_by(id: shipment_id)
  if shipment.present?
    next if shipment.cancelled? and shipment.cancellation_in_progress?
    if shipment.actual_dispatch_date.nil?
      shipment.actual_dispatch_date = dispatch_date
      shipment.save
    end
  end
end

InventoryItem.where(usage_type: 'ShipmentItem', used_on: nil).joins("inner join shipment_items si on usage_type = 'ShipmentItem' and usage_id = si.id inner join shipments s on si.shipment_id = s.id").pluck("s.id")

InventoryItem.where(usage_type: 'ShipmentItem', used_on: nil).all.each do |ii|
  shipment = ShipmentItem.find(ii.usage_id).shipment
  if shipment.actual_dispatch_date.present? and ii.usage_type == 'ShipmentItem' and ii.used_on.nil?
    ii.used_on = shipment.actual_dispatch_date
    ii.save
  end
end