
select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type,
ii.sku_id, count(distinct ii.id)
from putaway_items pi 
inner join inventory_items ii on pi.id = ii.putaway_item_id
inner join putaways p on pi.putaway_id = p.id
where created_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and putaway_type = 0
group by pi.id, p.id, ii.sku_id;

select sku_id, count(*)
from inventory_items
where created_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and putaway_type = 0
and sku_id = 122254
group by sku_id


select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type,
ii.sku_id, count(distinct ii.id)
from putaway_items pi 
inner join inventory_items ii on pi.id = ii.putaway_item_id
inner join putaways p on pi.putaway_id = p.id
where created_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and ii.putaway_type = 0
and ii.good is false
group by pi.id, p.id, ii.sku_id;

select sku_id, count(*)
from inventory_items
where created_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and putaway_type = 0
and good is false
and sku_id = 186365
group by sku_id


select sku_id, count(*)                                                              
from inventory_items
where used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and usage_type = 'ShipmentItem'
and sku_id = 122254
group by sku_id;

select o.id, o.created_at, ii.sku_id, o.aasm_state as "order_status",
oi.status as "order_item_status",count(distinct ii.id),
s.actual_dispatch_date, s.id as "shipment_id"
from shipment_items si
inner join inventory_items ii on ii.usage_type = 'ShipmentItem' and ii.usage_id = si.id
inner join shipments s on si.shipment_id = s.id
inner join orders o on s.order_id = o.id
inner join order_items oi on si.order_item_id = oi.id
where ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and ii.usage_type = 'ShipmentItem'
and ii.sku_id = 122254
group by ii.sku_id, o.id, oi.id, si.quantity, s.id;


select sku_id, count(*)
from inventory_items
where transferred_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and transfer_instrument_type = 'PurchaseOrderItem'
and sku_id = 122254
group by sku_id;

select ii.sku_id, count(distinct ii.id), poi.id, po.id, po.po_number
from purchase_order_items poi
inner join inventory_items ii on ii.transfer_instrument_type = 'PurchaseOrderItem' and poi.id =  ii.transfer_instrument_id
inner join purchase_orders po on poi.purchase_order_id = po.id
where transferred_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and transfer_instrument_type = 'PurchaseOrderItem'
and ii.sku_id = 122254
group by ii.sku_id;


select g.created_in_uniware_at, gi.id as "gatepass_item_id", g.uniware_gatepass_code,
case
  when g.reason = 0 then 'rtv'
  when g.reason = 1 then 'self_consumption'
  when g.reason = 2 then 'brand_collabs'
  when g.reason = 3 then 'agency'
  when g.reason = 4 then 'liquidation'
  when g.reason = 5 then 'gift'
  when g.reason = 6 then 'stock_transfer'
  else null
end as reason,
case
  when g.status = 0 then 'draft'
  when g.status = 1 then 'approved'
  else null
end as status,
ii.sku_id, count(distinct ii.id), g.for_bad_inventory
from gatepass_items gi
inner join inventory_items ii on ii.usage_type = 'GatepassItem' and ii.usage_id = gi.id
inner join gatepasses g on gi.gatepass_id = g.id
where ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and ii.organisation_id = 1
and ii.good is true
and g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and g.status = 1
and g.origin_id = 1
and g.for_bad_inventory is false
and ii.sku_id = 186365
group by gi.id, g.id, ii.sku_id;


select ii.sku_id, count(*)
from inventory_items ii
where ii.usage_type = 'GatepassItem'
and ii.usage_id in (
  select gi.id from gatepass_items gi
  inner join gatepasses g on gi.gatepass_id = g.id
  where g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
  and g.status = 1
  and g.origin_id = 1
  and g.for_bad_inventory is false
)
and ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and ii.organisation_id = 1
and ii.good is true
and ii.sku_id = 186365
group by ii.sku_id



select g.created_in_uniware_at, gi.id as "gatepass_item_id",
g.uniware_gatepass_code,
case
  when g.reason = 0 then 'rtv'
  when g.reason = 1 then 'self_consumption'
  when g.reason = 2 then 'brand_collabs'
  when g.reason = 3 then 'agency'
  when g.reason = 4 then 'liquidation'
  when g.reason = 5 then 'gift'
  when g.reason = 6 then 'stock_transfer'
  else null
end as reason,
case
  when g.status = 0 then 'draft'
  when g.status = 1 then 'approved'
  else null
end as status,
ii.sku_id, count(distinct ii.id), g.for_bad_inventory
from gatepass_items gi
inner join inventory_items ii on ii.usage_type = 'GatepassItem'
and ii.usage_id = gi.id
inner join gatepasses g on gi.gatepass_id = g.id
where ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and ii.organisation_id = 1
and ii.good is false
group by gi.id, g.id, ii.sku_id;

select ii.sku_id, count(*)
from inventory_items ii
where ii.usage_type = 'GatepassItem'
and ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
and ii.organisation_id = 1
and ii.good is false
and ii.sku_id = 156916
group by ii.sku_id














filename_command_hash = {}
 
filename_command_hash["putaway_grn_item.csv"] = <<~SQL.squish
 \\copy (
   select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
   from inventory_items ii
   inner join putaway_items pi on ii.putaway_item_id = pi.id
   inner join putaways p on pi.putaway_id = p.id
   where created_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
   and putaway_type = 0
   group by pi.id, p.id, ii.sku_id
 ) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL

filename_command_hash["putaway_grn_item_bad.csv"] = <<~SQL.squish
 \\copy (
   select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
   from inventory_items ii
   inner join putaway_items pi on ii.putaway_item_id = pi.id
   inner join putaways p on pi.putaway_id = p.id
   where created_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
   and putaway_type = 0
   and good is false
   group by pi.id, p.id, ii.sku_id
 ) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL

filename_command_hash["putaway_returned_by_customer.csv"] = <<~SQL.squish
\\copy (
  select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
  from putaway_items pi 
  inner join inventory_items ii on pi.id = ii.putaway_item_id
  inner join putaways p on pi.putaway_id = p.id
  where created_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
  and ii.putaway_type = 1
  and ii.organisation_id = 46
  and ii.good is true
  group by pi.id, p.id, ii.sku_id
) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL


filename_command_hash["putaway_returned_by_customer_bad.csv"] = <<~SQL.squish
\\copy (
  select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
  from inventory_items ii
  inner join putaway_items pi on ii.putaway_item_id = pi.id
  inner join putaways p on pi.putaway_id = p.id
  where created_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
  and ii.putaway_type = 1
  and ii.organisation_id = 46
  and ii.good is false
  group by pi.id, p.id, ii.sku_id
) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL

filename_command_hash["gatepasses_good.csv"] = <<~SQL.squish
\\copy (
  select g.created_in_uniware_at, gi.id as "gatepass_item_id", g.uniware_gatepass_code,
  case
    when g.reason = 0 then 'rtv'
    when g.reason = 1 then 'self_consumption'
    when g.reason = 2 then 'brand_collabs'
    when g.reason = 3 then 'agency'
    when g.reason = 4 then 'liquidation'
    when g.reason = 5 then 'gift'
    when g.reason = 6 then 'stock_transfer'
    else null
  end as reason,
  case
    when g.status = 0 then 'draft'
    when g.status = 1 then 'approved'
    else null
  end as status,
  ii.sku_id, count(distinct ii.id), g.for_bad_inventory
  from inventory_items ii
  inner join gatepass_items gi on ii.usage_type = 'GatepassItem' and ii.usage_id = gi.id
  inner join gatepasses g on gi.gatepass_id = g.id
  where ii.used_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
  and ii.organisation_id = 1
  and ii.good is true
  and g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
  and g.status = 1
  and g.origin_id = 1
  and g.for_bad_inventory is false
  group by gi.id, g.id, ii.sku_id
) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL

filename_command_hash["gatepasses_bad.csv"] = <<~SQL.squish
\\copy(
  select g.created_in_uniware_at, gi.id as "gatepass_item_id",
  g.uniware_gatepass_code,
  case
    when g.reason = 0 then 'rtv'
    when g.reason = 1 then 'self_consumption'
    when g.reason = 2 then 'brand_collabs'
    when g.reason = 3 then 'agency'
    when g.reason = 4 then 'liquidation'
    when g.reason = 5 then 'gift'
    when g.reason = 6 then 'stock_transfer'
    else null
  end as reason,
  case
    when g.status = 0 then 'draft'
    when g.status = 1 then 'approved'
    else null
  end as status,
  ii.sku_id, count(distinct ii.id), g.for_bad_inventory
  from inventory_items ii 
  inner join gatepass_items gi on ii.usage_type = 'GatepassItem' and ii.usage_id = gi.id
  inner join gatepasses g on gi.gatepass_id = g.id
  where ii.used_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
  and ii.organisation_id = 1
  and ii.good is false
  group by gi.id, g.id, ii.sku_id
) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL

filename_command_hash["sold.csv"] = <<~SQL.squish
\\copy(
  select o.id, o.created_at, ii.sku_id, o.aasm_state as "order_status",
  oi.status as "order_item_status",count(distinct ii.id),
  s.actual_dispatch_date, s.id as "shipment_id"
  from inventory_items ii 
  inner join shipment_items si on ii.usage_type = 'ShipmentItem' and ii.usage_id = si.id
  inner join shipments s on si.shipment_id = s.id
  inner join orders o on s.order_id = o.id
  inner join order_items oi on si.order_item_id = oi.id
  where ii.used_on between \'@all_reports_start_date\' and \'@all_reports_end_date\'
  and ii.usage_type = 'ShipmentItem'
  group by ii.sku_id, o.id, oi.id, s.id
) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL

filename_command_hash.each do |filename, copy_command|
  sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
  Rails.logger.error("SQL command is: #{sql_command}")
  output = `#{sql_command}`
  Rails.logger.error("SQL output is: #{output}")
  send_file(
    "#{Rails.root}/public/#{filename}",
    filename: filename,
  )
end

