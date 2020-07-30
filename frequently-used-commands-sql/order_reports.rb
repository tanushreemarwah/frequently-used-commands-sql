
Gatepass Report:
\copy (select g.uniware_gatepass_code, g.reason, g.for_bad_inventory, gi.sku_id, gi.quantity from gatepasses g inner join gatepass_items gi on g.id = gi.gatepass_id) to 'gatepass.csv' with csv header;

To find info about gp:
select g.id, g.created_in_uniware_at, gi.id as "gatepass_item_id", g.uniware_gatepass_code, gi.sku_id, gi.quantity from gatepasses g inner join gatepass_items gi on g.id = gi.gatepass_id where gi.sku_id = 178772;

Putaway Report:

Grouped by sku_id putaway data including bad inventory:
\copy (
  select pi.sku_id, sum(quantity) from putaway_items pi inner join putaways p on pi.putaway_id = p.id where p.vendor_putaway_type in ('PUTAWAY_COURIER_RETURNED_ITEMS', 'PUTAWAY_RECEIVED_RETURNS', 'PUTAWAY_REVERSE_PICKUP_ITEM', 'PUTAWAY_GRN_ITEM') and pi.sku_id = 132596 group by pi.sku_id
) to 'putaway.csv' with csv header;

Complete putaway data: 
\copy (
  select pi.id as putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, pi.sku_id, pi.quantity, pi.grn_id from putaways p inner join putaway_items pi on p.id = pi.putaway_id where p.vendor_putaway_type in ('PUTAWAY_COURIER_RETURNED_ITEMS', 'PUTAWAY_RECEIVED_RETURNS', 'PUTAWAY_REVERSE_PICKUP_ITEM', 'PUTAWAY_GRN_ITEM') and pi.sku_id = 
) to 'putaway_data.csv' with csv header;

Order Report - Combining children skus as well in case of combos for reco:

# this is the sum of putaway_items quantity which should be equal to the total number of ivnentory_items
select sum(quantity) from putaway_items pi inner join putaways p on pi.putaway_id = p.id where p.vendor_putaway_type in ('PUTAWAY_COURIER_RETURNED_ITEMS', 'PUTAWAY_RECEIVED_RETURNS', 'PUTAWAY_REVERSE_PICKUP_ITEM', 'PUTAWAY_GRN_ITEM') ;

Inventory Items:
\copy (select created_on, putaway_item_id, organisation_id, sku_id, good, transferred_on, used_on, usage_type, usage_id, buying_price, putaway_type, transfer_instrument_type, transfer_instrument_id from inventory_items
  where ) to 'ii.csv' with csv header ;

# Opening Stock
select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where created_on < '2020-05-20 23:59:59'
  and used_on is null
  and organisation_id = 1
group by sku_id

Putaway Data using inventory items :
# Total Purchase = 1. Putaway GRN Items
\copy (
  select sku_id, count(*) as qty_purchased, sum(buying_price) as value_purchased
  from inventory_items
  where created_on between '2019-10-01 00:00:00' and '2020-05-18 23:59:59'
  and putaway_type = 0
  group by sku_id
) to 'ii_putaway.csv' with csv header ;

# Bad purchase = 1. Putaway GRN Items Bad
select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where created_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59'
  and organisation_id in (1, 46)
  and good is false
  and putaway_type = 0
  group by sku_id

# Sold
# A3M
  select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where used_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59'
  and usage_type = 'ShipmentItem'
  and organisation_id = 46
  group by sku_id
  # EKANEK
  select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where transferred_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59'
  and transfer_instrument_type = 'PurchaseOrderItem'
  and organisation_id = 1
  group by sku_id

# Gatepasses
gatepass_ids = SELECT gi.id FROM "gatepass_items" gi INNER JOIN "gatepasses" g ON g.deleted_at IS NULL AND g.id = gi.gatepass_id WHERE (g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-05-20 23:59:59') AND (g.status = 1) AND (g.origin_id = 1) AND (g.for_bad_inventory is false)

SELECT sku_id, count(*) as qty, cast(sum(coalesce(buying_price, 0.0)) as decimal(10, 2)) as value
  FROM "inventory_items"
  WHERE (used_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59')
  AND "inventory_items"."usage_type" = 'GatepassItem'
  AND "inventory_items"."usage_id" IN (
    SELECT string_agg(gi.id::text, ', ')
    FROM "gatepass_items" gi
    INNER JOIN "gatepasses" g 
    ON g.deleted_at IS NULL AND g.id = gi.gatepass_id
    WHERE (g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-05-20 23:59:59')
    AND (g.status = 1) AND (g.origin_id = 1)
    AND (g.for_bad_inventory is false))
  )
  AND "inventory_items"."organisation_id" = 1
  AND "inventory_items"."good" is true
  GROUP BY "inventory_items"."sku_id"

# Bad Gatepasses
select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where used_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59'
  and usage_type = 'GatepassItem'
  and good is false
  and organisation_id = 1
group by sku_id

# Total Purchase = 2. Putaway Returned by Customers
select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where created_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59'
  and good is true
  and organisation_id = 46
  and putaway_type = 1
group by sku_id

# Bad purchase = 2. Putaway Returned by Customers Bad
select sku_id, count(*) as qty, sum(buying_price) as value
  from inventory_items
  where created_on between '2019-10-01 00:00:00' and '2020-05-20 23:59:59'
  and good is false
  and organisation_id = 46
  and putaway_type = 1
group by sku_id


PROCESSED ORDER REPORT:
\copy (
  # with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id" 
  # from skus s inner join products p on s.item_id = p.id)
  # select o.id, o.created_at, o.aasm_state as "order_status", 
  # oi.sku_id as "order_item_sku_id", 
  # coalesce(child_sku_id, oi.sku_id) as "sku_id", 
  # oi.status as "order_item_status", si.quantity,
  # string_agg(s.actual_dispatch_date::text, ', ') as "actual_dispatch_date", 
  # string_agg(s.id::text, ', ') as "shipment_id" 
  # from orders o inner join order_items oi on o.id = oi.order_id 
  # left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
  # inner join shipment_items si on si.order_item_id = oi.id
  # inner join shipments s on si.shipment_id = s.id
  # where s.actual_dispatch_date >= '2019-10-01 00:00:00' 
  # and s.actual_dispatch_date <= '2020-04-30 23:59:59' 
  # and o.id not in (1900005348, 1900005011, 1900005106, 1900005107,
  # 1900005347) and oi.status not in ('cancelled','pending')
  # and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review',
  # 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested',
  # 'confirmed') 
  # and s.aasm_state not in ('cancelled', 'cancellation_in_progress') 
  # and s.warehouse_id = 2 and o.deleted_at is null
  # and oi.deleted_at is null and s.deleted_at is null
  # group by o.id, o.created_at, o.aasm_state, oi.sku_id,
  # si.quantity, csi.child_sku_id, oi.status, s.aasm_state order by o.created_at
) to 'order.csv' with csv header;

# QTY SOLD: 
  with combo_sku_ids as (select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
  from skus s inner join products p on s.item_id = p.id where p.product_type = 2)
  select coalesce(child_sku_id, oi.sku_id) as "sku_id", sum(oi.quantity)
  from order_items oi
  inner join orders o on oi.order_id = o.id
  left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
  inner join shipment_items si on si.order_item_id = oi.id
  inner join shipments s on si.shipment_id = s.id
  where s.actual_dispatch_date >= '2019-10-01' and s.actual_dispatch_date <= '2020-03-20'
  and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
  and oi.status not in ('cancelled','pending')
  and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed')
  and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
  and s.warehouse_id = 2
  and o.deleted_at is null
  and oi.deleted_at is null
  and s.deleted_at is null
group by oi.sku_id, csi.child_sku_id;

# \copy (select o.id as "order_id", s.id as "suborder_id", o.source as "order_type", o.aasm_state as "order_status", o.created_at as "order_date", o.cod as "is_cod", c.name as "city", st.state_code, oa.contact_name, s.aasm_state as "shipment_status", oi.sku_id, pr.id as "product_id", v.id as "variant_id", b.name as "brand_name", case when sku.item_type = 'Product' then pr.brand_ean when sku.item_type = 'Variant' then v.brand_ean when sku.item_type = 'Surprise' then spr.brand_ean else gift.brand_ean end as "ean", case when sku.item_type = 'Product' then pr.name when sku.item_type = 'Variant' then v.name when sku.item_type = 'Surprise' then spr.name else gift.name end as "item_name", oi.mrp, oi.selling_price, oi.quantity, o.discount, o.delivery_fee as "shipping_charges",  o.cod_fee as "cod_charges", (o.item_amount - o.discount) as "net_collectible_value", oi.gst, pt.txn_id as "transaction_id", of.coupon_code as "offer_applied",  s.actual_dispatch_date as "shipped_date", s.awb_number, lp.name as "transporter", s.actual_delivery_date as "delivery_date", ssc.changed_at as "rto_marked_date", ref.created_at as "refund_initiated_at", ref.amount as "refund_amount" from order_items oi left join orders o on oi.order_id = o.id left join shipment_items si on si.order_item_id = oi.id left join shipments s on o.id = s.order_id left join shipment_status_changes ssc on s.id = ssc.shipment_id and ssc.to_status = 'rto_received'  left join payment_transactions pt on o.id = pt.order_id left join refund_requests ref on o.id = ref.order_id left join logistics_partners lp on s.logistics_partner_id = lp.id left join order_addresses oa on o.id = oa.order_id left join pincodes pc on oa.pincode_id = pc.id left join cities c on pc.city_id = c.id left join states st on pc.state_id = st.id left join order_coupons oc on o.id = oc.order_id left join offers of on oc.offer_id = of.id left join skus sku on oi.sku_id = sku.id  left join surprises spr on sku.item_id = spr.id left join gifts gift on sku.item_id = gift.id left join variants v on sku.item_id = v.id and sku.item_type = 'Variant' left join products pr on case when sku.item_type = 'Product' then sku.item_id = pr.id when sku.item_type = 'Variant' then v.product_id = pr.id end left join brands b on pr.brand_id = b.id where s.actual_dispatch_date >= '2020-03-01' and s.actual_dispatch_date <= '2020-03-31' and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347) and oi.status not in ('cancelled') and o.aasm_state not in ('cancelled', 'cancellation_in_progress', 'cancellation_requested') and (s.aasm_state not in ('cancelled', 'cancellation_in_progress') or s.aasm_state is null) and (s.warehouse_id = 2 or s.warehouse_id is null) and o.deleted_at is null and oi.deleted_at is null and s.deleted_at is null group by oi.sku_id, o.id, s.id, s.aasm_state, c.name, st.state_code, oa.contact_name, pr.id, v.id, b.name, sku.item_type, oi.mrp, oi.selling_price,     oi.quantity, oi.gst, pt.txn_id, of.coupon_code, lp.name, ssc.changed_at, ref.created_at, ref.amount, spr.brand_ean, gift.brand_ean, spr.name, gift.name) to 'sale_order.csv' with csv header;

\copy (
  with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id" 
  from skus s inner join products p on s.item_id = p.id) 
  select o.id, o.created_at, o.aasm_state as "order_status", o.source, oi.sku_id as "order_item_sku_id", coalesce(child_sku_id, oi.sku_id) as "sku_id", s.aasm_state as "shipment_status", oi.quantity, lp.name, string_agg(s.actual_dispatch_date::text, ', ') as "actual_dispatch_date", string_agg(s.id::text, ', ') as "shipment_id" 
  from orders o inner join order_items oi on o.id = oi.order_id 
  left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id 
  inner join shipments s on o.id = s.order_id 
  inner join logistics_partners lp on s.logistics_partner_id = lp.id 
  where s.actual_dispatch_date >= '2019-10-01' and s.actual_dispatch_date <= '2020-03-03' 
  and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347, 1900004669) 
  and oi.status not in ('cancelled','pending') 
  and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed') 
  and s.aasm_state not in ('cancelled', 'cancellation_in_progress') 
  and s.warehouse_id = 2 
  and o.deleted_at is null
  and oi.deleted_at is null
  and s.deleted_at is null 
  group by o.id, o.created_at, o.aasm_state, o.user_id, o.source, oi.sku_id, oi.quantity, lp.name, csi.child_sku_id, oi.status, s.aasm_state 
  order by o.created_at
) to 'order.csv' with csv header;

sold_qty_in_inventory_movement:

  with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id" 
    from skus s inner join products p on s.item_id = p.id) 
    select coalesce(child_sku_id, oi.sku_id) as "sku_id",  sum(si.quantity) 
    from orders o inner join shipments s on o.id = s.order_id 
    inner join shipment_items si on si.shipment_id = s.id 
    inner join  order_items oi on si.order_item_id = oi.id 
    left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id 
    where s.actual_dispatch_date >= '2019-10-01' and s.actual_dispatch_date <= '2020-03-09' 
    and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347) 
    and oi.status not in ('cancelled', 'pending') 
    and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 
      'cancellation_in_progress', 'cancellation_requested', 'confirmed') 
    and s.aasm_state not in ('cancelled', 'cancellation_in_progress') 
    and s.warehouse_id = 2 
    and o.deleted_at is null 
    and oi.deleted_at is null 
    and s.deleted_at is null
    group by oi.sku_id, csi.child_sku_id;


    with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
    from skus s inner join products p on s.item_id = p.id)
    select coalesce(child_sku_id, oi.sku_id) as "sku_id", sum(oi.quantity)
    from orders o inner join order_items oi on o.id = oi.order_id
    left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
    inner join shipments s on o.id = s.order_id
    where s.actual_dispatch_date >= '2019-10-01' and s.actual_dispatch_date <= \'#{Time.now.       strftime("%Y-%m-%d")}\'
    and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
    and oi.status not in ('cancelled','pending')
    and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled',   'cancellation_in_progress', 'cancellation_requested', 'confirmed')
    and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
    and s.warehouse_id = #{Warehouse::DTDC_WH.id}'
    and o.deleted_at is null
    and oi.deleted_at is null
    and s.deleted_at is null
    group by oi.sku_id, csi.child_sku_id;


# CONFIRMED ORDERS: 
  with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
  from skus s inner join products p on s.item_id = p.id)
  select o.id, o.created_at, o.aasm_state as "order_status", oi.sku_id as "order_item_sku_id",
  coalesce(child_sku_id, oi.sku_id) as "sku_id",
  oi.status as "order_item_status", oi.quantity
  from orders o inner join order_items oi on o.id = oi.order_id
  left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
  where o.id not in (1900005348, 1900005011, 1900005106, 1900005107,
  1900005347) and oi.status not in ('cancelled') and oi.sku_id = 202649
  and o.aasm_state in ('confirmed') group by oi.sku_id, oi.quantity, o.id, o.aasm_state, csi.child_sku_id, oi.status
  order by o.created_at desc;

# BusinessInvoiceData: 
select bi.date, bi.invoice_number, poi.sku_id, bii.qty,cast(bii.buying_price as decimal(10, 2)), coalesce(p.hsn_code, v.hsn_code) as "hsn", cast(bii.tax as decimal(10, 2)), cast(bii.line_total as decimal(10,2)) from business_invoice_items bii inner join purchase_order_items poi on bii.purchase_order_item_id = poi.id inner join skus s on poi.sku_id = s.id left join products p on s.item_type = 'Product' and s.item_id = p.id left join variants v on s.item_type = 'Variant' and s.item_id = v.id  inner join business_invoices bi on bii.business_invoice_id = bi.id where bi.deleted_at is null and bii.deleted_at is null order by date asc;

Find unmapped putaway-grns:
select p.id, p.vendor_putaway_code, gp.grn_id from putaways p left join grns_putaways gp on p.id = gp.putaway_id where gp.grn_id is null;

# to find shipment_items in non-cancelled states 
with non_cancelled_shipment_items as (select si.*, s.aasm_state as "state" from shipment_items si inner join shipments s on si.shipment_id = s.id and s.aasm_state not in ('cancelled', 'cancellation_in_progress', 'created')) select si.*, oi.status from non_cancelled_shipment_items si inner join order_items oi on si.order_item_id = oi.id where oi.sku_id = 202624;

# query on inventory_items
select id, putaway_item_id as "pi_id", sku_id, organisation_id as "org_id", transferred_on, usage_type, usage_id, good from inventory_items where sku_id = 286238;

# find which order has been linked to which inv_items:
select ii.id as "ii_id", ii.putaway_item_id as "pi_id", ii.sku_id, ii.organisation_id as "org_id", ii.transferred_on, ii.usage_type, ii.usage_id, oi.order_id,  ii.good from inventory_items ii inner join order_items oi on (ii.usage_type = 'OrderItem' and ii.usage_id = oi.id)  where ii.sku_id = ;

# total inv_item consumed for gatepass
select sum(quantity) from gatepass_items;
select count (*) from inventory_items where usage_type = 'GatepassItem';

# which gatepass_item doesn't have inv_item
select gi.id, gi.sku_id, ii.id from gatepass_items gi left join inventory_items ii on gi.id = ii.usage_id and ii.usage_type = 'GatepassItem' where ii.id is null;

# which putaway_item doesn't have inv_item/grn_id
select pi.vendor_putaway_item_id as "vpi_id", p.vendor_putaway_code, p.vendor_putaway_type as "putaway_type", pi.sku_id, pi.quantity from putaway_items pi inner join putaways p on pi.putaway_id = p.id inner join inventory_items ii on pi.id = ii.putaway_item_id where pi.quantity <> 0 and p.vendor_putaway_type not in ('PUTAWAY_CANCELLED_ITEM', 'PUTAWAY_PICKLIST_ITEM', 'PUTAWAY_SHELF_TRANSFER') and pi.grn_id is null order by pi.id asc;
# grouped by
\copy (
  select p.vendor_putaway_code, pi.vendor_putaway_item_id, p.vendor_putaway_type, pi.sku_id, pi.quantity from putaway_items pi inner join putaways p on pi.putaway_id = p.id where pi.quantity <> 0 and p.vendor_putaway_type not in ('PUTAWAY_CANCELLED_ITEM', 'PUTAWAY_PICKLIST_ITEM', 'PUTAWAY_SHELF_TRANSFER') and pi.grn_id is null group by pi.id, p.id order by pi.id asc
) to 'missing_grn_item.csv' with csv header;

# putaway grn items for which inv_movement object was not created
select p.id, p.vendor_putaway_code, p.vendor_putaway_type, p.created_at, p.warehouse_id, pi.sku_id, i.sku_id, i.warehouse_id, im.sku_id, i.id, im.id from putaway_items pi inner join putaways p on pi.putaway_id = p.id left join inventories i on pi.sku_id = i.sku_id left join inventory_movements im on im.source_type = 'Putaway' and im.source_id = p.id where p.vendor_putaway_type = 'PUTAWAY_GRN_ITEM' and im.id is null ;

# putaway_grn_items jiski inventory exist nahi krti
select p.id, p.vendor_putaway_code, p.vendor_putaway_type, p.created_at, p.warehouse_id, pi.sku_id, i.sku_id, i.warehouse_id, i.id
from putaway_items pi inner join putaways p on pi.putaway_id = p.id
left join inventories i on pi.sku_id = i.sku_id  where p.vendor_putaway_type = 'PUTAWAY_GRN_ITEM' and i.id is null;

# check for duplicate putaway_items
select vendor_putaway_item_id, count(*) from putaway_items group by vendor_putaway_item_id having count(*) > 1 ;
# delete duplicates - second query second line is not really required.
delete from putaway_items a where a.id <> (select min(b.id) from putaway_items b where a.vendor_putaway_item_id = b.vendor_putaway_item_id)
or
delete from putaway_items a where a.id <> (select min(b.id) from putaway_items b where a.vendor_putaway_item_id = b.vendor_putaway_item_id)
  and (a.vendor_putaway_item_id in (select vendor_putaway_item_id from putaway_items group by vendor_putaway_item_id having count(*) > 1) );

# purchase_order_items of pos from a3m to ekanek between a date range
auto_created -> select poi.created_at, po_approval_date, aasm_state, poi.id as poi_id, poi.qty, po.id as po_id, po_number, poi.deleted_at, po.deleted_at from purchase_order_items poi inner join purchase_orders po on poi.purchase_order_id = po.id where poi.deleted_at is null and po.buyer_id = 46 and po.seller_id = 1 and po_approval_date between '2020-05-01 00:00:00' and '2020-06-15 23:59:59' and po_creator_id = 0;
tanushree_created -> select poi.created_at, po_approval_date, aasm_state, poi.id as poi_id, poi.qty, po.id as po_id, po_number, poi.deleted_at, po.deleted_at from purchase_order_items poi inner join purchase_orders po on poi.purchase_order_id = po.id where poi.deleted_at is null and po.buyer_id = 46 and po.seller_id = 1 and po_approval_date between '2020-05-01 00:00:00' and '2020-06-15 23:59:59' and po_creator_id = 26;
all -> select poi.created_at, po_approval_date, aasm_state, poi.id as poi_id, poi.qty, po.id as po_id, po_number, poi.deleted_at, po.deleted_at from purchase_order_items poi inner join purchase_orders po on poi.purchase_order_id = po.id where poi.deleted_at is null and po.buyer_id = 46 and po.seller_id = 1 and po_approval_date between '2019-10-01 00:00:00' and '2020-07-07 23:59:59' and poi.sku_id = 285656;


# soft delete purchase_order_items of system generated po from a3m to ekanek
update purchase_order_items set deleted_at = current_timestamp where id in (select poi.id from purchase_order_items poi inner join purchase_orders po on poi.purchase_order_id = po.id where poi.deleted_at is null and po.buyer_id = 46 and po.seller_id = 1 and po_approval_date between '2019-10-01 00:00:00' and '2020-07-18' and po_number not ilike 'S%')  ;

update purchase_orders set deleted_at = current_timestamp where id in (select poi.purchase_order_id from purchase_order_items poi inner join purchase_orders po on poi.purchase_order_id = po.id where po.deleted_at is null and po.buyer_id = 46 and po.seller_id = 1 and po_approval_date between '2019-10-01 00:00:00' and '2020-07-18' and po_number not ilike 'S%') ;

# sum
select poi.sku_id, sum(poi.qty) from purchase_order_items poi inner join purchase_orders po on poi.purchase_order_id = po.id where po.buyer_id = 46 and po.seller_id = 1 and poi.deleted_at is null and poi.sku_id = 202274 group by sku_id;

# shipment_id for ivnentory_items
select ii.id as ii_id, created_on, putaway_item_id as "pi_id", sku_id, organisation_id as "org_id", transferred_on, transfer_instrument_type, transfer_instrument_id, used_on, usage_type, usage_id, si.shipment_id, good from inventory_items ii inner join shipment_items si on usage_id = si.id and usage_type = 'ShipmentItem' where sku_id = 185965;

# set warehouse_id = 2 for each inventory_items right now

# USE THESE, baki sab moh maya hai

# qty sold
with combo_sku_ids as (select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
  from skus s inner join products p on s.item_id = p.id where p.product_type = 2)
  select coalesce(child_sku_id, oi.sku_id) as "sku_id", sum(si.quantity)
  from shipment_items si
  inner join shipments s on si.shipment_id = s.id
  inner join orders o on s.order_id = o.id
  inner join order_items oi on si.order_item_id = oi.id
  left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
  where s.actual_dispatch_date between '2020-06-01 00:00:00' and '2020-06-30 23:59:59'
  and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
  and oi.status not in ('cancelled','pending')
  and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed')
  and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
  and s.warehouse_id = 2
  and o.deleted_at is null
  and oi.deleted_at is null
  and s.deleted_at is null and (oi.sku_id = 286171 or csi.child_sku_id = 286171)
  group by oi.sku_id, csi.child_sku_id;

considering sku_ids of shipment_items instead of order_items :

processed_orders_report: 
  with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id" 
  from skus s inner join products p on s.item_id = p.id)
  select o.id, o.created_at, o.aasm_state as "order_status",
  oi.sku_id as "order_item_sku_id",
  coalesce(child_sku_id, oi.sku_id) as "sku_id",
  oi.status as "order_item_status", si.quantity,
  s.actual_dispatch_date, s.id as "shipment_id"
  from shipment_items si
  inner join shipments s on si.shipment_id = s.id
  inner join orders o on s.order_id = o.id
  inner join  order_items oi on si.order_item_id = oi.id
  left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
  where s.actual_dispatch_date between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
  and o.id not in (1900005348, 1900005011, 1900005106, 1900005107,
  1900005347) and oi.status not in ('cancelled','pending')
  and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review',
  'created', 'cancellation_requested',
  'confirmed')
  and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
  and s.warehouse_id = 2
  and o.deleted_at is null
  and oi.deleted_at is null and s.deleted_at is null and (oi.sku_id = 285733 or csi.child_sku_id = 285733)
  group by o.id, o.created_at, o.aasm_state,
  oi.sku_id, si.quantity, csi.child_sku_id, oi.status, s.aasm_state, s.id, s.actual_dispatch_date
order by o.created_at;

#--------------------------------

select ii.sku_id, count(*)                                                              
  from shipment_items si                                                           
  inner join inventory_items ii on ii.usage_type = 'ShipmentItem' and ii.usage_id = si.id
  inner join shipments s on si.shipment_id = s.id
  inner join orders o on s.order_id = o.id
  inner join order_items oi on si.order_item_id = oi.id
  where ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
  and ii.usage_type = 'ShipmentItem'
  and ii.sku_id = 122254
  group by ii.sku_id;

select o.id, o.created_at, ii.sku_id, o.aasm_state as "order_status",
  oi.status as "order_item_status", si.quantity,
  s.actual_dispatch_date, s.id as "shipment_id"
  from shipment_items si
  inner join inventory_items ii on ii.usage_type = 'ShipmentItem' and ii.usage_id = si.id
  inner join shipments s on si.shipment_id = s.id
  inner join orders o on s.order_id = o.id
  inner join order_items oi on si.order_item_id = oi.id
  where ii.used_on between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
  and ii.usage_type = 'ShipmentItem'
  and ii.sku_id = 122254
  group by o.id, oi.id, si.id , s.id, ii.id;

#---------------------------------

# orders of combo products - to test for anything related to kits
select oi.order_id, oi.sku_id, p.children, sp.id as shipment_id from order_items oi 
  inner join skus s on oi.sku_id = s.id and s.item_type = 'Product' 
  inner join products p on s.item_id = p.id and p.product_type = 2 and p.children is not null 
  inner join shipments sp on oi.order_id = sp.order_id where sp.id is not null 
  and sp.aasm_state in ('shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received');

# inv_items is more than putaway_items.quantity
select ii.putaway_item_id, pi.quantity,  count(distinct ii.id) from putaway_items pi inner join inventory_items ii on pi.id = ii.putaway_item_id  group by ii.putaway_item_id, pi.quantity having pi.quantity <> count(distinct ii.id);
# and delete if extra
delete from inventory_items where id in (select id from inventory_items where putaway_item_id  = "#{putaway_item_id}" order by created_at desc limit "#{diff}");

# purchase_order_item not yet consumed - idk maybe
select poi.qty, count(distinct ii.id) from purchase_order_items poi inner join inventory_items ii on poi.id = ii.transfer_instrument_id and ii.transfer_instrument_type = 'PurchaseOrderItem' and poi.purchase_order_id = 1727 group by ii.transfer_instrument_id, poi.qty having count(distinct ii.id) <> poi.qty;

t=0 ; 6186 - putaway_items

order id	Status	Pincode	City	State	Amt	Payment Mode	Order created date
Shipment created date	Expected dispatch date	Actual dispatched date	Expected Delivery Date	Actual delivery Date	AWB
Is COD fee Paid	Is Delivery Fee paid


select o.id as order_id, o.aasm_state as "order_status", oa.pincode_id as pincode, c.name as "city", st.state_code as "state_code",
  case when (o.source ilike 'Campaign%' or o.source ilike 'Welcome%') then false else o.cod end as "is_cod", o.created_at as order_created_at,
  s.id as "shipment_id", s.expected_dispatch_date, s.actual_dispatch_date, s.expected_delivery_date, s.actual_delivery_date, s.awb_number
  from shipments s
  inner join orders o on s.order_id = o.id
  left join order_addresses oa on o.id = oa.order_id
  left join pincodes pc on oa.pincode_id = pc.id
  left join cities c on pc.city_id = c.id
  left join states st on pc.state_id = st.id
  where o.created_at between'2020-04-01 00:00:00' and '2020-06-10 23:59:59'
  and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
  and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created')
  and s.id is not null
  and s.warehouse_id = 2
  and o.deleted_at is null
  and s.deleted_at is null
  group by o.id, s.id, oa.pincode_id, c.name, st.state_code
  order by o.created_at;

and s.aasm_state not in ('cancelled', 'cancellation_in_progress')


# https://foxy.in/payment_methods?upgrade_to_prepaid=true&order_id=%{id}

ShipmentItem.joins(:shipment).where("shipment_items.aasm_state <> 'cancelled' or shipment_items.aasm_state is null").where(shipments: {aasm_state: ['shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received']}).where.not(shipments: { warehouse_id: Warehouse::FOXY_COLLAB_WH.id }).where.not(shipments: { order_id: [1900005348, 1900005011, 1900005106, 1900005107, 1900005347] }).where(shipments: {id: []})
ShipmentItem.joins(:shipment).where(shipments: {aasm_state: ['shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received']}).where.not(shipments: { warehouse_id: Warehouse::FOXY_COLLAB_WH.id }).where.not(shipments: { order_id: [1900005348, 1900005011, 1900005106, 1900005107, 1900005347] }).where(shipments: {id: []})


For auto_created POs. --------------------------------------------------------------------------------------

select po_approval_date, aasm_state, po.id as po_id, poi.id as poi_id, poi.sku_id,
cast(poi.buying_price as decimal(10,2)), poi.qty, cast(poi.taxable_value as decimal(10, 2)),
poi.tax, poi.sgst, poi.cgst, cast(poi.line_total as decimal(10, 2))
from purchase_order_items poi
inner join purchase_orders po on poi.purchase_order_id = po.id
where poi.deleted_at is null and po.deleted_at is null
and po.buyer_id = 46 and po.seller_id = 1
and po_approval_date between '2020-06-01 00:00:00' and '2020-06-30 23:59:59'
order by po_approval_date;

ShipmentItem.joins(shipment: :shipment_status_changes)
.where(shipment_status_changes: {
  to_status: ['shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received'],
  changed_at: '2020-06-01 00:00:00'..'2020-06-30 23:59:59'})
.where("shipment_items.aasm_state <> 'cancelled' or shipment_items.aasm_state is null")
.where(shipments: {aasm_state: ['shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received']})
.where.not(shipments: { warehouse_id: Warehouse::FOXY_COLLAB_WH.id })
.where.not(shipments: { order_id: [1900005348, 1900005011, 1900005106, 1900005107, 1900005347] }).includes(:order_item).order(:created_at)

----------new query-------------
SELECT "shipment_items".*
FROM "shipment_items"
INNER JOIN "shipments" ON "shipments"."id" = "shipment_items"."shipment_id" AND "shipments"."deleted_at" IS NULL
INNER JOIN "shipment_status_changes" ON "shipment_status_changes"."shipment_id" = "shipments"."id"
WHERE "shipment_items"."deleted_at" IS NULL AND "shipment_status_changes"."to_status" IN ('shipped', 'in_transit')
AND "shipment_status_changes"."changed_at" BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
AND (shipment_items.aasm_state <> 'cancelled' or shipment_items.aasm_state is null)
AND "shipments"."aasm_state" NOT IN ('cancelled', 'cancellation_in_progress')
AND "shipments"."warehouse_id" != 1
AND "shipments"."order_id" NOT IN (1900005348, 1900005011, 1900005106, 1900005107, 1900005347) ORDER BY "shipment_items"."created_at" ASC

----------old query-------------
SELECT "shipment_items".*
FROM "shipment_items"
INNER JOIN "shipments" ON "shipments"."id" = "shipment_items"."shipment_id" AND "shipments"."deleted_at" IS NULL
WHERE "shipment_items"."deleted_at" IS NULL
AND (shipment_items.aasm_state <> 'cancelled' or shipment_items.aasm_state is null)
AND "shipments"."aasm_state" IN ('shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received')
AND "shipments"."warehouse_id" != 1
AND "shipments"."order_id" NOT IN (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
AND (shipments.created_at between '2020-06-28 18:30:00' and '2020-06-29 18:30:00')
ORDER BY "shipment_items"."created_at" ASC
-----------------------------



start_date = '2020-06-01'
end_date = '2020-06-02'


date_today = '2020-06-02'
if date_today < '2020-07-01 00:00:00'
  start_date = start_date.to_datetime.in_time_zone("New Delhi").beginning_of_day
  end_date = (start_date == end_date.to_datetime.in_time_zone("New Delhi").beginning_of_day) ? end_date.to_datetime.in_time_zone("New Delhi").end_of_day : end_date.to_datetime.in_time_zone("New Delhi").beginning_of_day

  # AutoCreatePoJob.perform_async(start_date: date_today.yesterday, end_date: date_today)

  shipment_items = ShipmentItem 
  .joins(shipment: :shipment_status_changes)
  .where(shipment_status_changes: {
    to_status: ['shipped'],
    changed_at: "#{start_date}".."#{end_date}"})
  .where("shipment_items.aasm_state <> 'cancelled' or shipment_items.aasm_state is null")
  .where.not(shipments: {aasm_state: ['cancelled', 'cancellation_in_progress']})
  .where.not(shipments: { warehouse_id: Warehouse::FOXY_COLLAB_WH.id })
  .where.not(shipments: { order_id: [1900005348, 1900005011, 1900005106, 1900005107, 1900005347] })
  .includes(:order_item)
  .order(:created_at)

  warehouse_id = 2

  shipment_item_ids = shipment_items
    .joins(:shipment)
    .where(shipments: {warehouse_id: warehouse_id})
    .pluck(:id)
    .uniq

  sku_quantity_hash_for_this_warehouse = ShipmentItem
    .where(id: shipment_item_ids)
    .joins("inner join order_items oi on shipment_items.order_item_id = oi.id
      left join (
        select s.id as kit_sku_id, unnest(p.children) as child_sku_id
        from skus s inner join products p on s.item_id = p.id
      ) as combo_product_skus on oi.sku_id = combo_product_skus.kit_sku_id")
    .group("final_sku_id")
    .pluck("coalesce(combo_product_skus.child_sku_id, oi.sku_id) as final_sku_id, sum(shipment_items.quantity)")
    .to_h

  sku_quantity_hash_for_this_warehouse.each do |sku_id, quantity|
    sku = Sku.find(sku_id)
    brand = sku.item.brand
    ekanek_id = Organisation::EKANEK_ORG.id
    margin_percent = sku.margin_percent(ekanek_id)
    if margin_percent.nil?
      item = sku.item_type == 'Variant' ? sku.item.product : sku.item
      fm = (item.priority.in? ['Priority SKU', 'Single Stock']) ? 0 : 1
      ai = AssortmentInput.create!(organisation_id: ekanek_id, brand_id: brand.id, product_id: nil, variant_id: nil, product_category_id: nil, fulfillment_model: fm, margin_percent: 13.0)
    end
    OrganisationToBrand.find_or_create_by!(organisation_id: ekanek_id, brand_id: brand.id)
  end
  po = PurchaseOrder.auto_create(date_today.yesterday, sku_quantity_hash_for_this_warehouse, warehouse_id)

  unless po.save
    raise po.errors.full_messages.join(', ')
  end
  po.consume_inventory_for_ekanek
  po.update(aasm_state: 'settled')

  start_date = date_today
  date_today = date_today + 1.day
end



with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
from skus s inner join products p on s.item_id = p.id)
select o.id, o.created_at, o.aasm_state as "order_status",
oi.sku_id as "order_item_sku_id",
coalesce(child_sku_id, oi.sku_id) as "sku_id",
oi.status as "order_item_status", si.quantity,
s.actual_dispatch_date, s.id as "shipment_id"
from shipment_items si
inner join shipments s on si.shipment_id = s.id
inner join orders o on s.order_id = o.id
inner join  order_items oi on si.order_item_id = oi.id
left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
where s.actual_dispatch_date between '2020-06-01 18:30:00' and '2020-06-30 23:59:59'
and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
and oi.status not in ('cancelled','pending')
and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed')
and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
and s.warehouse_id = 2
and o.deleted_at is null
and oi.deleted_at is null and s.deleted_at is null and (oi.sku_id = 286154 or csi.child_sku_id = 286154)
group by o.id, o.created_at, o.aasm_state, oi.sku_id, si.quantity, csi.child_sku_id, oi.status, s.aasm_state, s.id, s.actual_dispatch_date
order by o.created_at






SELECT shipment_items.shipment_id, "shipment_items".order_item_id, oi.sku_id,
shipment_items.quantity, shipments.aasm_state, shipment_status_changes.to_status, shipment_status_changes.changed_at
FROM "shipment_items" inner join order_items oi on shipment_items.order_item_id = oi.id
INNER JOIN "shipments" ON "shipments"."id" = "shipment_items"."shipment_id" AND "shipments"."deleted_at" IS NULL
INNER JOIN "shipment_status_changes" ON "shipment_status_changes"."shipment_id" = "shipments"."id"
WHERE "shipment_items"."deleted_at" IS NULL 
AND "shipment_status_changes"."to_status" not in (coalesce('shipped', 'in_transit'))
AND "shipment_status_changes"."changed_at" BETWEEN '2010-10-01 00:00:00' AND '2020-07-15 23:59:59'
AND (shipment_items.aasm_state <> 'cancelled' or shipment_items.aasm_state is null)
AND "shipments"."aasm_state" NOT IN ('cancelled', 'cancellation_in_progress')
AND "shipments"."warehouse_id" != 1
AND "shipments"."order_id" NOT IN (1900005348, 1900005011, 1900005106, 1900005107, 1900005347) 
ORDER BY "shipment_items"."created_at" DESC;



shipments_not_marked_as_shipped_ever = Shipment
  .joins(:shipment_status_changes)
  .where("aasm_state in ('shipped', 'in_transit', 'out_for_delivery', 'out_for_delivery_for_second_attempt', 'out_for_delivery_for_third_attempt', 'delivered', 'first_attempt_failed', 'second_attempt_failed', 'third_attempt_failed', 'rto', 'return_processing', 'rto_received')")
  .where.not(warehouse_id: Warehouse::FOXY_COLLAB_WH.id)
  .where.not("order_id in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)")
  .where.not(shipment_status_changes: {to_status: 'shipped'})
  .group("shipments.id")



  
  ShipmentStatusChange.create(shipment_id: shipment_id, from_status: 'ready_to_ship', to_status: 'shipped', changed_at: dispatch_date)


  select g.created_in_uniware_at, g.uniware_gatepass_code,
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
  end as status, g.for_bad_inventory, gi.sku_id, gi.quantity
  from gatepasses g
  inner join gatepass_items gi
  on g.id = gi.gatepass_id
  and g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-07-14 23:59:59'
  order by g.created_in_uniware_at
