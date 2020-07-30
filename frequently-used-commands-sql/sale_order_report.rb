-------------------brand discounts foxy discount etc----------------------------


with order_items_ratio as (
  select oi.id, case when (o.item_amount = 0.00 or o.item_amount is null) then 0.00 else ((oi.selling_price * oi.quantity) / o.item_amount) end as "ratio"
  from order_items oi inner join orders o on oi.order_id = o.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
order_item_charges as (
  select oi.id, coalesce(cast((o.discount * oir.ratio) as decimal(10, 2)), 0) as "discount"
  from order_items oi
  inner join order_items_ratio oir on oi.id = oir.id 
  inner join orders o on oi.order_id = o.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
shipment_items_ratio as (
  select si.id, case when (s.value = 0.00 or s.value is null) then 0.00 else ((oi.selling_price * si.quantity) / s.value) end as "ratio"
  from shipment_items si inner join order_items oi on si.order_item_id = oi.id inner join shipments s on si.shipment_id = s.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
shipment_item_charges as (
  select si.id, coalesce(cast((s.discount_applicable * sir.ratio) as decimal(10, 2)), 0) as "discount"
  from shipment_items si
  inner join order_items oi on si.order_item_id = oi.id
  inner join shipment_items_ratio sir on si.id = sir.id
  inner join shipments s on si.shipment_id = s.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
)
select
orders.created_at as order_date, orders.id as order_id,
s.id as shipment_id,s.created_at as shipment_created_at,
case when source ilike 'Campaign%' then 'Campaign' when (oi.is_surprise is true or skus.item_type = 'Surprise') then 'Surprise' when (solo_combo_products.gwp is true and oi.is_surprise is not true) then 'GWP' else 'Normal' end as type,
oi.sku_id as sku_id, coalesce(v.name, solo_combo_products.name) as item_name,
oi.mrp*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) - coalesce(sic.discount, oic.discount, 0) - (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as shipment_value,
oi.mrp, coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as quantity,
case when skus.item_type = 'Product' and solo_combo_products.gwp is true and oi.is_surprise is not true then oi.mrp else null end as total_customer_discount_gwp,
case when skus.item_type = 'Surprise' or oi.is_surprise is true then oi.mrp else null end as total_customer_discount_surprise,
case when source ilike 'Campaign%' then oi.mrp else null end as total_customer_discount_campaign,
coalesce(sic.discount, oic.discount, 0) + (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as order_discount,
case when source ilike 'Campaign%' then 0.00 else (coalesce(sic.discount, oic.discount, 0)) end as coupon_discount,
case when (
  (skus.item_type = 'Surprise')
  or (skus.item_type = 'Product' and solo_combo_products.gwp is true)
  or (source ilike 'Campaign%')
  or oi.is_surprise is true) then 0.00
else (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity)
end as selling_price_discount,
case when (skus.item_type = 'Product' and solo_combo_products.gwp is true and oi.is_surprise is not true) then 100 when (skus.item_type = 'Surprise' or oi.is_surprise is true or source ilike 'Campaign%') then 0 end as percentage_of_brand_funded_discount,
string_agg(offers.brand_funding_percentage::text, ', ') as brand_funding_percentage_coupons,
string_agg(offers.coupon_code, ', ') as coupon_codes
from orders
left outer join order_items oi
  on oi.order_id = orders.id
  and oi.deleted_at is null
  and (oi.status is null or (oi.status <> 'cancelled' and oi.acceptance_state <> 3))
inner join skus on skus.id = oi.sku_id
left join products solo_combo_products on skus.item_type = 'Product' and skus.item_id = solo_combo_products.id
left join variants v on skus.item_type = 'Variant' and skus.item_id = v.id
left outer join (
  select shipment_items.* from shipment_items
    inner join shipments
    on shipment_items.shipment_id = shipments.id
    and shipments.aasm_state <> 'cancelled'
    and shipments.deleted_at is null)
  as non_cancelled_shipment_items on non_cancelled_shipment_items.order_item_id = oi.id
  and non_cancelled_shipment_items.deleted_at is null
left join shipments s on non_cancelled_shipment_items.shipment_id = s.id
left join shipment_item_charges sic on non_cancelled_shipment_items.id = sic.id
left join order_item_charges oic on oi.id = oic.id
left join order_coupons on order_coupons.order_id = orders.id
left join offers on offers.id = order_coupons.offer_id
where orders.aasm_state not in ('created', 'awaiting_confirmation', 'abandoned', 'cancelled') and orders.created_at between '2020-05-01 00:00:00' and '2020-05-31 23:59:59'
group by orders.id, s.id, oi.id, v.id, solo_combo_products.id, non_cancelled_shipment_items.quantity, sic.discount, oic.discount, skus.id
order by orders.id, s.id



----------------------- sale order report ------------------------------------------------

  # remove refund columns
  ref.created_at as "refund_initiated_at", ref.amount as "refund_amount" 
  left join refund_requests ref on o.id = ref.order_id


  combo sku = 285937
  # shipment_items - CURRENT QUERY
  with combo_sku_ids as (
    select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
    from skus s inner join products p on s.item_id = p.id where p.product_type = 2
  ),
  shipment_items_ratio as (
    select si.id, case when (s.value = 0.00 or s.value is null) then 0.00 else ((oi.selling_price * si.quantity) / s.value) end as "ratio"
    from shipment_items si inner join order_items oi on si.order_item_id = oi.id inner join shipments s on si.shipment_id = s.id
  ),
  shipment_total_quantity as (
    select s.id, cast(sum(si.quantity) as decimal(10, 2)) as "total_quantity" 
    from shipments s 
    inner join shipment_items si on s.id = si.shipment_id group by s.id
  ),
  shipment_item_charges as (
    select si.id, coalesce(cast((s.discount_applicable * sir.ratio) as decimal(10, 2)), 0) as "discount",
    coalesce(cast((s.delivery_fee * cast((si.quantity / stq.total_quantity) as decimal(10,2))) as decimal(10, 2)), 0) as "delivery_fee",
    coalesce(cast((s.cod_charges * cast((si.quantity / stq.total_quantity) as decimal(10,2))) as decimal(10, 2)), 0) as "cod_charges"
    from shipment_items si
    inner join order_items oi on si.order_item_id = oi.id
    inner join shipment_items_ratio sir on si.id = sir.id
    inner join shipments s on si.shipment_id = s.id
    inner join orders o on s.order_id = o.id
    inner join shipment_total_quantity stq on s.id = stq.id
  )
  select o.id as "order_id",
  s.id as "shipment_id",
  case when o.source ilike 'Campaign%' then 'Campaign' when o.source ilike 'Welcome%' then 'Welcome Gift' else 'Customer Order' end as "order_type",
  o.aasm_state as "order_status",
  o.created_at as "order_date",
  s.created_at as "shipment_date",
  case when (o.source ilike 'Campaign%' or o.source ilike 'Welcome%') then false else o.cod end as "is_cod",
  c.name as "city",
  st.state_code as "state_code",
  oa.contact_name,
  s.aasm_state as "shipment_status",
  coalesce(child_sku_id, oi.sku_id) as "sku_id",
  pr.id as "product_id",
  v.id as "variant_id",
  case when sku.item_type in ('Product', 'Variant') then coalesce(v.gwp, pr.gwp) else 'f' end as "gwp",
  case when sku.item_type = 'Surprise' then 't' else 'f' end as "is_surprise",
  prop.name as "property_name",
  pv.boolean_value as "property_value",
  b.name as "brand_name",
  string_agg(org.name::text, ', ') as "vendor_names",
  case when sku.item_type = 'Product' then pr.brand_ean when sku.item_type = 'Variant' then v.brand_ean when sku.item_type = 'Surprise' then spr.brand_ean else gift.brand_ean end as "ean",
  case when sku.item_type = 'Product' then pr.name when sku.item_type = 'Variant' then v.name when sku.item_type = 'Surprise' then spr.name else gift.name end as "item_name",
  case when sku.item_type = 'Product' then pr.hsn_code when sku.item_type = 'Variant' then v.hsn_code when sku.item_type = 'Surprise' then spr.hsn_code else gift.hsn_code end as "hsn_code",
  oi.mrp, oi.selling_price, si.quantity,
  sic.discount,
  sic.delivery_fee as "shipping_charges",
  sic.cod_charges,
  hm.gst_rate,
  case when (wh_st.id = customer_st.id) then 'Intrastate' else 'Interstate' end as "jurisdiction",
  ((oi.selling_price * si.quantity) - sic.discount + sic.delivery_fee + sic.cod_charges) as "net_collectible_value",
  oi.gst, pt.txn_id as "transaction_id",
  string_agg(of.coupon_code::text, ', ') as "offers_applied",
  s.actual_dispatch_date as "shipped_date",
  s.awb_number,
  lp.name as "transporter",
  s.actual_delivery_date as "delivery_date",
  ssc.changed_at as "rto_marked_date"
  from shipment_items si
  inner join order_items oi on si.order_item_id = oi.id
  inner join orders o on oi.order_id = o.id
  inner join shipments s on si.shipment_id = s.id
  left join shipment_item_charges sic on si.id = sic.id
  left join shipment_status_changes ssc on s.id = ssc.shipment_id and ssc.to_status = 'rto_received'
  left join payment_transactions pt on o.id = pt.order_id
  left join logistics_partners lp on s.logistics_partner_id = lp.id
  left join order_addresses oa on o.id = oa.order_id
  left join pincodes pc on oa.pincode_id = pc.id
  left join cities c on pc.city_id = c.id
  left join states st on pc.state_id = st.id
  left join warehouses w on s.warehouse_id = w.id
  left join warehouse_addresses wa on w.id = wa.id
  left join pincodes wh_pc on wa.pincode::integer = wh_pc.id
  left join states wh_st on wh_pc.state_id = wh_st.id
  left join pincodes customer_pc on oa.pincode_id = customer_pc.id
  left join states customer_st on customer_pc.state_id =  customer_st.id
  left join order_coupons oc on o.id = oc.order_id
  left join offers of on oc.offer_id = of.id
  left join skus sku on oi.sku_id = sku.id
  left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
  left join surprises spr on sku.item_id = spr.id
  left join gifts gift on sku.item_id = gift.id
  left join variants v on sku.item_id = v.id and sku.item_type = 'Variant'
  left join products pr on case when sku.item_type = 'Product' then sku.item_id = pr.id when sku.item_type = 'Variant' then v.product_id = pr.id end
  left join property_values pv on pv.entity_type = 'Product' and pv.entity_id = coalesce(pr.id, v.product_id) and pv.boolean_value is true
  left join properties prop on prop.id = pv.property_id and prop.name = 'Essential'
  left join hsn_mappings hm on hm.hsn_code = pr.hsn_code or hm.hsn_code = v.hsn_code or hm.hsn_code = spr.hsn_code or hm.hsn_code = gift.hsn_code
  left join brands b on pr.brand_id = b.id
  left join organisation_to_brands otb on b.id = otb.brand_id
  left join organisations org on otb.organisation_id = org.id and org.id <> 1
  where s.created_at between '2020-05-01 00:00:00' and '2020-06-30 23:59:59'
  and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
  and oi.status not in ('cancelled')
  and o.aasm_state not in ('cancelled', 'cancellation_in_progress', 'cancellation_requested')
  and (s.aasm_state not in ('cancelled', 'cancellation_in_progress') or s.aasm_state is null)
  and (s.warehouse_id = 2 or s.warehouse_id is null)
  and o.deleted_at is null
  and oi.deleted_at is null
  and s.deleted_at is null
  group by oi.sku_id, csi.child_sku_id, o.id, s.id, s.aasm_state, c.name, st.state_code,
  oa.contact_name, pr.id, v.id, b.name, sku.item_type, oi.mrp, oi.selling_price,
  oi.quantity, oi.gst, pt.txn_id, lp.name, ssc.changed_at,
  spr.brand_ean, gift.brand_ean, spr.name, gift.name,  spr.hsn_code, gift.hsn_code,
  hm.gst_rate, wa.pincode, oa.pincode_id, wh_st.id, customer_st.id,
  sic.discount, sic.delivery_fee, sic.cod_charges, si.quantity, si.id, prop.name, pv.boolean_value;



--------------Order - set expected dispatch and delivery date for old orders ---------------
Order.all.each do |o|
  o.expected_dispatch_date = o.created_at + 2.days
  o.expected_delivery_date = o.expected_dispatch_date + (Tat.find_by(destination_pincode: order_address&.pincode&.id)&.duration || 3).days
  begin
    o.save
  rescue
    puts o.errors.full_messsages.join(', ')
  end
end








------------------------------------------------------------------------------------------------------------


rohan ka kaam

with combo_sku_ids as (
  select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
  from skus s inner join products p on s.item_type = 'Product' and s.item_id = p.id where p.product_type = 2
),
combo_products_ratio as (
  select combo_sku_ids.kit_sku_id, unnest(p.children) as "child_sku_id", (coalesce(p.mrp, v.mrp) / combo_products.mrp) as ratio
  from combo_sku_ids
  inner join skus s on combo_sku_ids.child_sku_id = s.id
  inner join products p on s.item_type = 'Product' and s.item_id = p.id 
  inner join variants v on s.item_type = 'Variant' and s.item_id = v.id
  inner join skus ks on combo_sku_ids.kit_sku_id = ks.id
  inner join products combo_products on ks.item_type = 'Product' and p.id = ks.item_id
),
order_items_ratio as (
  select oi.id, case when (o.item_amount = 0.00 or o.item_amount is null) then 0.00 else ((oi.selling_price * oi.quantity) / o.item_amount) end as "ratio"
  from order_items oi inner join orders o on oi.order_id = o.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
order_item_charges as (
  select oi.id, coalesce(cast((o.discount * oir.ratio) as decimal(10, 2)), 0) as "discount"
  from order_items oi
  inner join order_items_ratio oir on oi.id = oir.id
  inner join orders o on oi.order_id = o.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
shipment_items_ratio as (
  select si.id, case when (s.value = 0.00 or s.value is null) then 0.00 else ((oi.selling_price * si.quantity) / s.value) end as "ratio"
  from shipment_items si inner join order_items oi on si.order_item_id = oi.id inner join shipments s on si.shipment_id = s.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
shipment_item_charges as (
  select si.id, coalesce(cast((s.discount_applicable * sir.ratio) as decimal(10, 2)), 0) as "discount"
  from shipment_items si
  inner join order_items oi on si.order_item_id = oi.id
  inner join shipment_items_ratio sir on si.id = sir.id
  inner join shipments s on si.shipment_id = s.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
)
select
orders.created_at as order_date, orders.id as order_id,
coalesce(csi.child_sku_id, oi.sku_id) as "sku_id",
s.id as shipment_id,s.created_at as shipment_created_at,
case when source ilike 'Campaign%' then 'Campaign' when (oi.is_surprise is true or skus.item_type = 'Surprise') then 'Surprise' when (solo_combo_products.gwp is true and oi.is_surprise is not true) then 'GWP' else 'Normal' end as type,
oi.sku_id as sku_id, coalesce(v.name, solo_combo_products.name) as item_name,
oi.mrp*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) - coalesce(sic.discount, oic.discount, 0) - (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as shipment_value,
case when cpr.child_sku_id is not null then cpr.ratio * oi.mrp else oi.mrp end as mrp,
coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as quantity,
case when skus.item_type = 'Product' and solo_combo_products.gwp is true and oi.is_surprise is not true then oi.mrp else null end as total_customer_discount_gwp,
case when skus.item_type = 'Surprise' or oi.is_surprise is true then oi.mrp else null end as total_customer_discount_surprise,
case when source ilike 'Campaign%' then oi.mrp else null end as total_customer_discount_campaign,
coalesce(sic.discount, oic.discount, 0) + (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as order_discount,
case when source ilike 'Campaign%' then 0.00 else (coalesce(sic.discount, oic.discount, 0)) end as coupon_discount,
case when (
  (skus.item_type = 'Surprise')
  or (skus.item_type = 'Product' and solo_combo_products.gwp is true)
  or (source ilike 'Campaign%')
  or oi.is_surprise is true) then 0.00
else (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity)
end as selling_price_discount,
case when (skus.item_type = 'Product' and solo_combo_products.gwp is true and oi.is_surprise is not true) then 100 when (skus.item_type = 'Surprise' or oi.is_surprise is true or source ilike 'Campaign%') then 0 end as percentage_of_brand_funded_discount,
string_agg(offers.brand_funding_percentage::text, ', ') as brand_funding_percentage_coupons,
string_agg(offers.coupon_code, ', ') as coupon_codes
from orders
left outer join order_items oi
  on oi.order_id = orders.id
  and oi.deleted_at is null
  and (oi.status is null or (oi.status <> 'cancelled' and oi.acceptance_state <> 3))
inner join skus on skus.id = oi.sku_id
left join products solo_combo_products on skus.item_type = 'Product' and skus.item_id = solo_combo_products.id
left join variants v on skus.item_type = 'Variant' and skus.item_id = v.id
left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
left join combo_products_ratio cpr on csi.child_sku_id = cpr.child_sku_id
left outer join (
  select shipment_items.* from shipment_items
    inner join shipments
    on shipment_items.shipment_id = shipments.id
    and shipments.aasm_state <> 'cancelled'
    and shipments.deleted_at is null)
  as non_cancelled_shipment_items on non_cancelled_shipment_items.order_item_id = oi.id
  and non_cancelled_shipment_items.deleted_at is null
left join shipments s on non_cancelled_shipment_items.shipment_id = s.id
left join shipment_item_charges sic on non_cancelled_shipment_items.id = sic.id
left join order_item_charges oic on oi.id = oic.id
left join order_coupons on order_coupons.order_id = orders.id
left join offers on offers.id = order_coupons.offer_id
where orders.aasm_state not in ('created', 'awaiting_confirmation', 'abandoned', 'cancelled') and orders.created_at between '2020-05-01 00:00:00' and '2020-05-31 23:59:59'
and (oi.sku_id = 285937 or csi.child_sku_id = 285937)
group by orders.id, s.id, oi.id, v.id, solo_combo_products.id, non_cancelled_shipment_items.quantity, sic.discount, oic.discount, skus.id, csi.child_sku_id, cpr.child_sku_id, cpr.ratio, cpr.kit_sku_id
order by orders.id, s.id




with combo_sku_ids as (
  select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
  from skus s inner join products p on s.item_type = 'Product' and s.item_id = p.id where p.product_type = 2
),
combo_products_ratio as (
  select combo_sku_ids.kit_sku_id, unnest(p.children) as "child_sku_id", (coalesce(p.mrp, v.mrp) / combo_products.mrp) as ratio
  from combo_sku_ids
  inner join skus s on combo_sku_ids.child_sku_id = s.id
  inner join products p on s.item_type = 'Product' and s.item_id = p.id 
  inner join variants v on s.item_type = 'Variant' and s.item_id = v.id
  inner join skus ks on combo_sku_ids.kit_sku_id = ks.id
  inner join products combo_products on ks.item_type = 'Product' and p.id = ks.item_id
),
order_items_ratio as (
  select oi.id, case when (o.item_amount = 0.00 or o.item_amount is null) then 0.00 else ((oi.selling_price * oi.quantity) / o.item_amount) end as "ratio"
  from order_items oi inner join orders o on oi.order_id = o.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
order_item_charges as (
  select oi.id, coalesce(cast((o.discount * oir.ratio) as decimal(10, 2)), 0) as "discount"
  from order_items oi
  inner join order_items_ratio oir on oi.id = oir.id
  inner join orders o on oi.order_id = o.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
shipment_items_ratio as (
  select si.id, case when (s.value = 0.00 or s.value is null) then 0.00 else ((oi.selling_price * si.quantity) / s.value) end as "ratio"
  from shipment_items si inner join order_items oi on si.order_item_id = oi.id inner join shipments s on si.shipment_id = s.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
),
shipment_item_charges as (
  select si.id, coalesce(cast((s.discount_applicable * sir.ratio) as decimal(10, 2)), 0) as "discount"
  from shipment_items si
  inner join order_items oi on si.order_item_id = oi.id
  inner join shipment_items_ratio sir on si.id = sir.id
  inner join shipments s on si.shipment_id = s.id
  where oi.acceptance_state <> 3 or oi.status not in ('cancelled')
)
select
orders.created_at as order_date, orders.id as order_id,
coalesce(csi.child_sku_id, oi.sku_id) as "sku_id",
s.id as shipment_id,s.created_at as shipment_created_at,
case when source ilike 'Campaign%' then 'Campaign' when (oi.is_surprise is true or skus.item_type = 'Surprise') then 'Surprise' when (solo_combo_products.gwp is true and oi.is_surprise is not true) then 'GWP' else 'Normal' end as type,
oi.sku_id as sku_id, coalesce(v.name, solo_combo_products.name) as item_name,
oi.mrp*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) - coalesce(sic.discount, oic.discount, 0) - (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as shipment_value,
case when cpr.child_sku_id is not null then cpr.ratio * oi.mrp else oi.mrp end as mrp,
coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as quantity,
case when skus.item_type = 'Product' and solo_combo_products.gwp is true and oi.is_surprise is not true then oi.mrp else null end as total_customer_discount_gwp,
case when skus.item_type = 'Surprise' or oi.is_surprise is true then oi.mrp else null end as total_customer_discount_surprise,
case when source ilike 'Campaign%' then oi.mrp else null end as total_customer_discount_campaign,
coalesce(sic.discount, oic.discount, 0) + (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity) as order_discount,
case when source ilike 'Campaign%' then 0.00 else (coalesce(sic.discount, oic.discount, 0)) end as coupon_discount,
case when (
  (skus.item_type = 'Surprise')
  or (skus.item_type = 'Product' and solo_combo_products.gwp is true)
  or (source ilike 'Campaign%')
  or oi.is_surprise is true) then 0.00
else (oi.mrp - oi.selling_price)*coalesce(non_cancelled_shipment_items.quantity, oi.quantity)
end as selling_price_discount,
case when (skus.item_type = 'Product' and solo_combo_products.gwp is true and oi.is_surprise is not true) then 100 when (skus.item_type = 'Surprise' or oi.is_surprise is true or source ilike 'Campaign%') then 0 end as percentage_of_brand_funded_discount,
string_agg(offers.brand_funding_percentage::text, ', ') as brand_funding_percentage_coupons,
string_agg(offers.coupon_code, ', ') as coupon_codes
from orders
left outer join order_items oi
  on oi.order_id = orders.id
  and oi.deleted_at is null
  and (oi.status is null or (oi.status <> 'cancelled' and oi.acceptance_state <> 3))
inner join skus on skus.id = oi.sku_id
left join products solo_combo_products on skus.item_type = 'Product' and skus.item_id = solo_combo_products.id
left join variants v on skus.item_type = 'Variant' and skus.item_id = v.id
left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
left join combo_products_ratio cpr on csi.child_sku_id = cpr.child_sku_id
left outer join (
  select shipment_items.* from shipment_items
    inner join shipments
    on shipment_items.shipment_id = shipments.id
    and shipments.aasm_state <> 'cancelled'
    and shipments.deleted_at is null)
  as non_cancelled_shipment_items on non_cancelled_shipment_items.order_item_id = oi.id
  and non_cancelled_shipment_items.deleted_at is null
left join shipments s on non_cancelled_shipment_items.shipment_id = s.id
left join shipment_item_charges sic on non_cancelled_shipment_items.id = sic.id
left join order_item_charges oic on oi.id = oic.id
left join order_coupons on order_coupons.order_id = orders.id
left join offers on offers.id = order_coupons.offer_id
where orders.aasm_state not in ('created', 'awaiting_confirmation', 'abandoned', 'cancelled') and orders.created_at between '2020-05-01 00:00:00' and '2020-05-31 23:59:59'
and (oi.sku_id = 285937 or csi.child_sku_id = 285937)
group by orders.id, s.id, oi.id, v.id, solo_combo_products.id, non_cancelled_shipment_items.quantity, sic.discount, oic.discount, skus.id, csi.child_sku_id, cpr.child_sku_id, cpr.ratio, cpr.kit_sku_id
order by orders.id, s.id
