
showing alag alag oi.sku_id, csi.child_sku_id :

with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id" 
from skus s inner join products p on s.item_id = p.id) 
select coalesce(child_sku_id, oi.sku_id) as "sku_id", sum(oi.quantity)
from orders o inner join order_items oi on o.id = oi.order_id 
left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id 
inner join shipments s on o.id = s.order_id 
where s. actual_dispatch_date >= '2019-10-01' 
and s.actual_dispatch_date <= '2020-03-03' 
and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347, 1900004669) 
and oi.status not in ('cancelled','pending') 
and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 
  'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed') 
and s.aasm_state not in ('cancelled', 'cancellation_in_progress') 
and s.warehouse_id = 2 
and o.deleted_at is null 
and oi.deleted_at is null 
and s.deleted_at is null 
and (csi.child_sku_id = 285527 or oi.sku_id = 285527) 
group by oi.sku_id, oi.quantity, csi.child_sku_id;


showing sum :

with combo_sku_ids as(select s.id as "kit_sku_id", unnest(p.children) as "child_sku_id"
from skus s inner join products p on s.item_id = p.id)
select coalesce(child_sku_id, oi.sku_id) as "sku_id", sum(oi.quantity)
from orders o inner join order_items oi on o.id = oi.order_id
left join combo_sku_ids csi on csi.kit_sku_id = oi.sku_id
inner join shipments s on o.id = s.order_id
where s.actual_dispatch_date >= '2019-10-01' and s.actual_dispatch_date <= '2020-03-03'
and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347, 1900004669)
and oi.status not in ('cancelled','pending')
and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed')
and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
and s.warehouse_id = 2
and o.deleted_at is null
and oi.deleted_at is null
and s.deleted_at is null and (csi.child_sku_id = 197457 or oi.sku_id = 197457)
group by oi.sku_id, csi.child_sku_id;


<%= form.select :publisher_type, options_for_select(['Artist', 'Brand', 'UserAttributeAllowedValue'],
form.object&.publisher_type),
{prompt: 'Choose Publisher Type'},
{ onchange: 'empty_publisher_id();',
  class: 'form-control polymorphic-select2-type'
}
%>
<div class="row mt-2">
<div class="col">
  <div class="form-group">
    <label for="">Publisher Type</label>
    <%= form.select :publisher_type, options_for_select(['Artist', 'Brand', 'UserAttributeAllowedValue'], form.object&.publisher_type), {prompt: 'Choose Publisher Type'}, { onchange: 'empty_publisher_id();', class: 'form-control polymorphic-select2-type' } %>
      <select name="story[publisher_type]" id="" class="form-control polymorphic-select2-type" onchange="empty_publisher_id();">
        <option value="Artist">Artist</option>
        <option value="Brand">Brand</option>
        <option value="UserAttributeAllowedValue">User Attribute</option>
      </select>
  </div>
</div>
<div class="col">
  <div class="form-group">
    <label for="">Publisher ID</label>
    <select name="story[publisher_id]" id="" class="form-control has-select2 -polymorphic-select2">
        <% if form.object&.publisher_id.present? %>
          <option value="<%= form.object.publisher_id %>" selected><%= form.object.publisher.name || form.object.publisher.title || form.object.publisher.id %></option>
        <% end %>
    </select>
  </div>
</div>
</div>