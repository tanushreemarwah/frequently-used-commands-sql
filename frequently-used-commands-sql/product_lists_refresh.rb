20924
8784
53861

product = Product.find(10093)
media = product.media
id = product.id


# top videos
Foxy -> YT, artist signed up? , level -> no. of priority products tagged, YT view count (no mention of artist level being greater than 5 in this one)
top_videos = media.joins("inner join artists a on media.artist_id = a.id left join media_products mp on mp.medium_id = media.id left join (select * from products where priority in ('Priority SKU', 'Single Stock')) p on mp.product_id = p.id") .group("media.id, a.id") .order("case when media.type = 'FoxyVideo' then 0 when media.type = 'YoutubeVideo' then 1 else 2 end, case when a.user_id is null then 1 else 0 end, a.level desc, count(distinct p.id) desc, media.youtube_view_count desc").limit(10).pluck("media.type, a.user_id, a.level, count(distinct p.id), media.youtube_view_count")

# all videos
all_videos = media .joins(:artist) .order("case when artists.user_id is null then 1 else 0 end, artists.level desc, media.youtube_view_count desc").pluck("artists.user_id, artists.level, media.youtube_view_count")

# latest videos
Foxy -> YT, artist signed up? , created_at ; level > 5
ignore_set = media .joins("inner join artists a on media.artist_id = a.id left join media_products mp on mp.medium_id = media.id left join (select * from products where priority in ('Priority SKU', 'Single Stock')) p on mp.product_id = p.id") .group("media.id, a.id") .order("case when media.type = 'FoxyVideo' then 0 when media.type = 'YoutubeVideo' then 1 else 2 end, case when a.user_id is null then 1 else 0 end, a.level desc, count(distinct p.id) desc, media.youtube_view_count desc").limit(10).pluck("media.id")
media = ignore_set.size > 0 ? self.media.where.not(id: ignore_set) : self.media
latest_videos = media .joins("left join artists on media.artist_id = artists.id") .where("artists.level > 5") .order("case when media.type = 'FoxyVideo' then 0 when media.type = 'YoutubeVideo' then 1 else 2 end, case when artists.user_id is null then 1 else 0 end, media.created_at desc").pluck("media.type, artists.user_id, media.created_at, artists.level")

# frequently bought together
media = product.media
id = product.id
ids_of_all_videos_of_this_product = MediaProduct.where(product_id: id, medium_id: media.pluck(:id).uniq).pluck(:medium_id).uniq
ids_of_other_products_tagged_in_videos_of_this_product = MediaProduct .joins("inner join products p on media_products.product_id = p.id inner join skus s on s.item_type = 'Product' and s.item_id = media_products.product_id left join inventories i on s.id = i.sku_id") .where(medium_id: ids_of_all_videos_of_this_product) .where.not(product_id: id) .group("media_products.product_id, p.id")
.order("case when sum(i.quantity) > 0 then 0 else 1 end,
case when p.status in (#{Product.statuses[:published]}, #{Product.statuses[:publishable]}) then 0
when p.status = #{Product.statuses[:draft]} then 2 else null end,
count(media_products.product_id) desc,
case when p.priority in ('Priority SKU', 'Single Stock') then 0
when p.priority in ('Priority SKU', 'Single Stock') then 1 else 2 end, sum(i.quantity) desc") 
.pluck("media_products.product_id, sum(i.quantity), case when p.status = 0 then 'draft' when p.status = 1 then 'publishable' when p.status = 2 then 'published' else null end, count(media_products.product_id), p.priority") 


# recommending artists
# no user signed up makes the list empty
(8784 has singed up artists)
media_products = product.media_products
artist_ids = Artist .where(id: Medium.where(id: media_products.map(&:medium_id)).pluck(:artist_id).uniq) .where('user_id is not null') .order(level: :desc) .pluck(:id, :level)

# brand top products
top_products = product.brand.top_products
brand_top_products = Product .where("products.id in (#{top_products.pluck(:id).join(', ')})") .joins("inner join skus s on s.item_type = 'Product' and products.id = s.item_id left join inventories i on s.id = i.sku_id") .having("sum(i.quantity) > 0") .group("i.sku_id, products.id, priority, out_of_stock") .order("case when priority in ('Priority SKU', 'Single Stock') then 0 when priority in ('Order Later', 'Listing Only') then 1 else 2 end, sum(i.quantity) desc") .pluck("priority, sum(i.quantity)")

# category top products
top_products = product.product_category.top_products
category_top_products = Product .where("products.id in (#{top_products.pluck(:id).uniq.join(', ')})") .joins("inner join skus s on s.item_type = 'Product' and products.id = s.item_id inner join brands b on products.brand_id = b.id left join inventories i on s.id = i.sku_id") .having("sum(i.quantity) > 0") .group("i.sku_id, products.id, priority, out_of_stock, phase") .order("case when priority in ('Priority SKU', 'Single Stock') then 0 when priority in ('Order Later', 'Listing Only') then 1 else 2 end, phase").pluck("priority, phase")

# 
product =
Artist.joins("inner join orders o on artists.user_id = o.user_id inner join order_items oi on o.id = oi.order_id inner join skus on oi.sku_id = skus.id ").where("case when skus.item_type = 'Variant' then skus.item_id in (#{product.variants.pluck(:id).join(', ')}) when skus.item_type = 'Product' then item_id = #{product.id} else null end").order("artists.level desc").pluck("artists.id, artists.level")

# including inventories  of variants/child skus as well
brand_top_products = Product
  .where("products.id in (#{top_products.pluck(:id).join(', ')})")
  .joins("inner join variants v on products.id = v.product_id
    inner join skus s on case when products.product_type = #{Product.product_types[:solo]} then s.item_type = 'Product' and products.id = s.item_id
    when products.product_type = #{Product.product_types[:parent_product]} then s.item_type = 'Variant' and s.item_id = v.id
    when products.product_type = #{Product.product_types[:combo]} then s.item_id in (array_to_string(products.children)) end
    left join inventories i on s.id = i.sku_id")
  .group("i.sku_id, products.id, v.id")
  .pluck("s.item_type, s.id, sum(i.quantity)"
)





# ARTIST PAGE REFRESH

rank by desc no of priority products tagged -> 
select m.id, m.type, count(distinct p.id), rank() over (order by count(distinct p.id) desc) rank from media m inner join media_products mp on m.id = mp.medium_id left join (select * from products where priority in ('Priority SKU', 'Single Stock')) p on mp.product_id = p.id where m.artist_id = 67 and m.status = 3 group by m.id order by case when count(distinct p.id) > 0 then 0 else 1 end, case when m.type = 'FoxyVideo' then 0 when m.type = 'YoutubeVideo' then 1 else 2 end;

select m.id, m.type, count(distinct p.id), RANK () over (order by count(distinct p.id) desc) rank
from media m
inner join media_products mp on m.id = mp.medium_id
left join (select * from products where priority in ('Priority SKU', 'Single Stock')) p on mp.product_id = p.id
where m.artist_id = 67 and m.status = 3
group by m.id
order by 
  case when count(distinct p.id) > 0 then 0 else 1 end,
  case when m.type = 'FoxyVideo' then 0 when m.type = 'YoutubeVideo' then 1 else 2 end
;


top 5 videos shuffle randomly - select r.id, r.type, r.count, r.rank from (select m.id, m.type, count(distinct p.id) as count, rank() over (order by count(distinct p.id) desc) rank from media m inner join media_products mp on m.id = mp.medium_id left join (select * from products where priority in ('Priority SKU', 'Single Stock')) p on mp.product_id = p.id where m.artist_id = 67 and m.status = 3 group by m.id order by case when count(distinct p.id) > 0 then 0 else 1 end, case when m.type = 'FoxyVideo' then 0 when m.type = 'YoutubeVideo' then 1 else 2 end) as r order by r.rank, random() limit 5;
after that count(distinct p.id) desc












