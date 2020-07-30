

select COALESCE(ai1.margin_percent, ai2.margin_percent, ai3.margin_percent, ai4.margin_percent, ai5.margin_percent)
AS margin_percent,
FROM brands b

# products
LEFT OUTER JOIN products p on p.brand_id = b.id
INNER JOIN variants v on v.product_id = p.id
LEFT OUTER JOIN assortment_inputs ai5
  on ai5.brand_id = p.brand_id
  and ai5.product_category_id is null
  and ai5.product_id is null
  and ai5.variant_id is null
  and p.priority not in ('Single Stock','Priority SKU')
  and ai5.fulfillment_model != 0
  and ai5.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai4 
  on ai4.brand_id = p.brand_id
  and ai4.product_category_id is null
  and ai4.product_id is null
  and ai4.variant_id is null
  and p.priority IN ('Single Stock','Priority SKU')
  and ai4.fulfillment_model = 0
  and ai4.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai3
  on ai3.product_category_id = p.product_category_id
  and ai3.brand_id = p.brand_id
  and ai3.product_id is null
  and ai3.variant_id is null
  and ai3.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai2
  on ai2.product_id = p.id
  and ai2.variant_id is null
  and ai2.organisation_id <> 1

# variants
LEFT OUTER JOIN assortment_inputs ai5 on ai5.brand_id = p.brand_id and ai5.product_category_id is null and ai5.product_id is null and ai5.variant_id is null and p.priority not in ('Single Stock', 'Priority SKU') and ai5.fulfillment_model != 0 and ai5.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai4 on ai4.brand_id = p.brand_id and ai4.product_category_id is null and ai4.product_id is null and ai4.variant_id is null and p.priority IN ('Single Stock', 'Priority SKU') and ai4.fulfillment_model = 0 and ai4.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai3 on ai3.product_category_id = p.product_category_id and ai3.brand_id = p.brand_id and ai3.product_id is null and ai3.variant_id is null and ai3.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai2 on ai2.product_id = p.id and ai2.variant_id is null and ai2.organisation_id <> 1
LEFT OUTER JOIN assortment_inputs ai1 on ai1.variant_id = v.id and ai1.organisation_id <> 1
