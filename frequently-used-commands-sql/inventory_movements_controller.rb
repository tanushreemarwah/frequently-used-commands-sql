class InventoryMovementsController < ApplicationController
  before_action :set_inventory_movement, only: [:show, :edit, :update, :destroy]
  before_action :set_default_date_params, except: [:show, :edit, :update, :destroy]
  respond_to :csv, :html, :json

  # GET /inventory_movements
  # GET /inventory_movements.json
  def index
    @datatable = InventoryMovementsDatatable.new
    respond_to do |format|
      format.html
      format.csv do
        day_before_start_date = (@imr_start_date <= @initial_date) ? DateTime.now.end_of_day : (@imr_start_date.to_datetime - 1.day).end_of_day
        ekanek = Organisation::EKANEK_ORG
        a3m = Organisation::A3M_ORG
        params[:organisation_id] = params[:organisation_id].to_i

        # "Brand Name", "Brand Owner", "Item Name", "Item Type", "MRP", "GWP/Surprise"
        brand_name_hash, brand_owner_hash, name_hash, item_type_hash, mrp_hash, gwp_surprise_hash = Sku.create_item_detail_hashes

        # Opening Stock
        organisation_ids = params[:organisation_id] == 0 ? [ekanek.id, a3m.id] : params[:organisation_id]
        opening_stock_quantity_hash, opening_stock_value_hash = InventoryItem.create_opening_stock_hashes(day_before_start_date, organisation_ids)

        organisation_ids = (params[:organisation_id].in? [0, ekanek.id]) ? [ekanek.id, a3m.id] : params[:organisation_id]
        # Total Purchase = 1. Putaway GRN Items
        sku_purchased_quantity_hash, sku_purchased_value_hash = InventoryItem.create_purchased_hashes(@imr_start_date, @imr_end_date, organisation_ids)
        # Bad purchase = 1. Putaway GRN Items Bad
        sku_bad_qty_purchased_hash, sku_bad_value_purchased_hash = InventoryItem.create_bad_purchased_hashes(@imr_start_date, @imr_end_date, organisation_ids)

        organisation_id = params[:organisation_id] == 0 ? a3m.id : params[:organisation_id]
        # 2. Putaway Returned by Customers
        sku_quantity_returned_by_customers_hash, sku_value_returned_by_customers_hash = InventoryItem.create_returned_by_customer_hashes(@imr_start_date, @imr_end_date, organisation_id)
        # 2. Putaway Returned by Customers Bad
        sku_qty_bad_stock_returned_by_customer_hash, sku_value_bad_stock_returned_by_customer_hash = InventoryItem.create_bad_returned_by_customer_hashes(@imr_start_date, @imr_end_date, organisation_id)
        # Sold
        sku_quantity_sold_hash, sku_value_sold_hash = InventoryItem.create_sold_hashes(@imr_start_date, @imr_end_date, organisation_id)

        # Gatepasses
        organisation_id = params[:organisation_id] == 0 ? ekanek.id : params[:organisation_id]
        sku_quantity_returned_to_vendor_hash, sku_value_returned_to_vendor_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'rtv', organisation_id)
        sku_self_consumed_quantity_hash, sku_self_consumed_value_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'self_consumption', organisation_id)
        sku_quantity_sent_for_brand_collabs_hash, sku_value_sent_for_brand_collabs_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'brand_collabs', organisation_id)
        sku_quantity_sent_to_agency_hash, sku_value_sent_to_agency_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'agency', organisation_id)
        sku_gift_quantity_hash, sku_gift_value_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'gift', organisation_id)
        sku_quantity_liquidated_hash, sku_value_liquidated_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'liquidation', organisation_id)
        sku_stock_transfer_quantity_hash, sku_stock_transfer_value_hash = InventoryItem.create_gatepass_reason_hashes(@imr_start_date, @imr_end_date, 'stock_transfer', organisation_id)
        # Bad Gatepasses
        sku_bad_qty_gatepass_hash, sku_bad_value_gatepass_hash = InventoryItem.create_bad_gatepass_hashes(@imr_start_date, @imr_end_date, organisation_id)
        # Blocked Qty
        sku_blocked_qty_hash = Inventory.create_sku_blocked_qty_hash

        require 'csv'
        filename = 
        case params[:organisation_id].to_i
        when 0
          'Consolidated-IMR.csv'
        when ekanek.id
          'EkAnek-IMR.csv'
        when a3m.id
          'A3M-IMR.csv'
        end

        CSV.open("#{filename}", "wb") do |response_csv|
          response_csv << ["SKU ID", "Brand Name", "Brand Owner", "Item Name", "Item Type", "MRP", "GWP/Surprise", "Opening Stock Qty", "Opening Stock Value", "Qty Purchased", "Value Purchased",
            "Qty Returned By Customer", "Value Returned By Customer", "Total Putaway Qty", "Total Putaway Value",
            "Qty Sold", "Value Sold", "Qty Returned to Vendor", "Value Returned to Vendor", "Qty Used for Self Consumption",
            "Value Used for Self Consumption",  "Qty used for Brand Collabs", "Value used for Brand Collabs", "Qty sent to Agency",
            "Value sent to Agency", "Qty used as Gift",  "Value used as Gift", "Qty Liquidated", "Value Liquidated",
            "Stock Transfer Qty", "Stock Transfer Value", "Gatepass Bad Qty", "Gatepass Bad Value", "Total Gatepass", "Total Gatepass Value", "Stock Adjustment",
            "Closing Stock Qty", "Closing Stock Value" , "Good Qty", "Good Qty Value", "Bad Qty", "Bad Qty Value", "Qty Blocked"]

          skus = InventoryItem.pluck(:sku_id).uniq
          skus.each do |sku_id|
            report = []
            report << sku_id
            sku = Sku.find sku_id

            report << brand_name_hash[sku_id]
            report << brand_owner_hash[sku_id]
            report << name_hash[sku_id]
            report << item_type_hash[sku_id]
            report << mrp_hash[sku_id]
            report << gwp_surprise_hash[sku_id]

            opening_stock_quantity = (@imr_start_date <= @initial_date) ? 0 : opening_stock_quantity_hash[sku_id].to_i
            opening_stock_value = (@imr_start_date <= @initial_date) ? 0 : opening_stock_value_hash[sku_id].to_f
            report << opening_stock_quantity
            report << opening_stock_value
            report << sku_purchased_quantity_hash[sku_id].to_i
            report << sku_purchased_value_hash[sku_id].to_f
            report << sku_quantity_returned_by_customers_hash[sku_id].to_i
            report << sku_value_returned_by_customers_hash[sku_id].to_f
            total_putaway_qty = sku_purchased_quantity_hash[sku_id].to_i + sku_quantity_returned_by_customers_hash[sku_id].to_i
            total_putaway_value = sku_purchased_value_hash[sku_id].to_f + sku_value_returned_by_customers_hash[sku_id].to_f
            report << total_putaway_qty
            report << total_putaway_value
            report << sku_quantity_sold_hash[sku_id].to_i
            report << sku_value_sold_hash[sku_id].to_f
            report << sku_quantity_returned_to_vendor_hash[sku_id].to_i
            report << sku_value_returned_to_vendor_hash[sku_id].to_f
            report << sku_self_consumed_quantity_hash[sku_id].to_i
            report << sku_self_consumed_value_hash[sku_id].to_f
            report << sku_quantity_sent_for_brand_collabs_hash[sku_id].to_i
            report << sku_value_sent_for_brand_collabs_hash[sku_id].to_f
            report << sku_quantity_sent_to_agency_hash[sku_id].to_i
            report << sku_value_sent_to_agency_hash[sku_id].to_f
            report << sku_gift_quantity_hash[sku_id].to_i
            report << sku_gift_value_hash[sku_id].to_f
            report << sku_quantity_liquidated_hash[sku_id].to_i
            report << sku_value_liquidated_hash[sku_id].to_f
            report << sku_stock_transfer_quantity_hash[sku_id].to_i
            report << sku_stock_transfer_value_hash[sku_id].to_f
            report << sku_bad_qty_gatepass_hash[sku_id].to_i
            report << sku_bad_value_gatepass_hash[sku_id].to_f
            total_gp_qty = sku_quantity_returned_to_vendor_hash[sku_id].to_i +
                        sku_self_consumed_quantity_hash[sku_id].to_i +
                        sku_quantity_sent_for_brand_collabs_hash[sku_id].to_i +
                        sku_quantity_sent_to_agency_hash[sku_id].to_i +
                        sku_gift_quantity_hash[sku_id].to_i +
                        sku_quantity_liquidated_hash[sku_id].to_i +
                        sku_stock_transfer_quantity_hash[sku_id].to_i +
                        sku_bad_qty_gatepass_hash[sku_id].to_i
            total_gp_value = sku_value_returned_to_vendor_hash[sku_id].to_f +
                        sku_self_consumed_value_hash[sku_id].to_f +
                        sku_value_sent_for_brand_collabs_hash[sku_id].to_f +
                        sku_value_sent_to_agency_hash[sku_id].to_f +
                        sku_gift_value_hash[sku_id].to_f +
                        sku_value_liquidated_hash[sku_id].to_f +
                        sku_stock_transfer_value_hash[sku_id].to_f +
                        sku_bad_value_gatepass_hash[sku_id].to_f
            report << total_gp_qty
            report << total_gp_value
            report << 0 # stock adjustment 0 for now

            inwarded_quantity = total_putaway_qty
            inwarded_value = total_putaway_value

            outwarded_quantity = sku_quantity_sold_hash[sku_id].to_i + total_gp_qty
            outwarded_value = sku_value_sold_hash[sku_id].to_f + total_gp_value

            closing_stock_quantity = opening_stock_quantity + inwarded_quantity - outwarded_quantity
            closing_stock_value = opening_stock_value + inwarded_value - outwarded_value

            # total_bad = putaway_grn_bad + putaway_return_bad - gatepass_bad
            bad_qty = sku_bad_qty_purchased_hash[sku_id].to_i +
                      sku_qty_bad_stock_returned_by_customer_hash[sku_id].to_i -
                      sku_bad_qty_gatepass_hash[sku_id].to_i
            bad_stock_value = sku_bad_value_purchased_hash[sku_id].to_f +
                              sku_value_bad_stock_returned_by_customer_hash[sku_id].to_f -
                              sku_bad_value_gatepass_hash[sku_id].to_f

            good_qty = closing_stock_quantity - bad_qty
            good_stock_value = closing_stock_value - bad_stock_value

            report << closing_stock_quantity
            report << closing_stock_value
            report << good_qty
            report << good_stock_value
            report << bad_qty
            report << bad_stock_value
            report << sku_blocked_qty_hash[sku_id].to_i
            response_csv << report
          end

          send_file(
            "#{filename}",
            filename: "#{filename}",
          )
        end
      end
    end
  end

  def download_putaway_data
    filename = "putaway_data.csv"
    config = Wms::Application.config.database_configuration[::Rails.env]
    dbhost, dbuser, dbname, dbpassword = config['host'], config['username'], config['database'], config['password']
    copy_command = <<~SQL.squish
    \\copy (
      select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, pi.sku_id, pi.quantity
      from putaways p
      inner join putaway_items pi on p.id = pi.putaway_id
      where p.vendor_putaway_type in ('PUTAWAY_COURIER_RETURNED_ITEMS', 'PUTAWAY_RECEIVED_RETURNS', 'PUTAWAY_REVERSE_PICKUP_ITEM', 'PUTAWAY_GRN_ITEM')
      and p.unicommerce_creation_at between \'#{@putaway_start_date}\' and \'#{@putaway_end_date}\'
      order by p.unicommerce_creation_at
    ) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
    Rails.logger.error("SQL command is: #{sql_command}")
    output = `#{sql_command}`
    Rails.logger.error("SQL output is: #{output}")
    send_file(
      "#{Rails.root}/public/#{filename}",
      filename: filename,
    )
  end

  def download_gatepass_data
    filename = "gatepass_data.csv"
    config = Wms::Application.config.database_configuration[::Rails.env]
    dbhost, dbuser, dbname, dbpassword = config['host'], config['username'], config['database'], config['password']
    copy_command = <<~SQL.squish
    \\copy (
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
      and g.created_in_uniware_at between \'#{@gatepass_start_date}\' and \'#{@gatepass_end_date}\'
      order by g.created_in_uniware_at
    ) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
    Rails.logger.error("SQL command is: #{sql_command}")
    output = `#{sql_command}`
    Rails.logger.error("SQL output is: #{output}")
    send_file(
      "#{Rails.root}/public/#{filename}",
      filename: filename,
    )
  end

  def download_sale_order_data
    filename = "sale_order_data.csv"
    config = Wms::Application.config.database_configuration[::Rails.env]
    dbhost, dbuser, dbname, dbpassword = config['host'], config['username'], config['database'], config['password']
    copy_command = <<~SQL.squish
    \\copy (
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
      where s.actual_dispatch_date between \'#{@sale_order_start_date}\' and \'#{@sale_order_end_date}\'
      and o.id not in (1900005348, 1900005011, 1900005106, 1900005107, 1900005347)
      and oi.status not in ('cancelled','pending')
      and o.aasm_state not in ('awaiting_confirmation', 'awaiting_review', 'created', 'cancelled', 'cancellation_in_progress', 'cancellation_requested', 'confirmed')
      and s.aasm_state not in ('cancelled', 'cancellation_in_progress')
      and s.warehouse_id = \"#{Warehouse::DTDC_WH.id}\"
      and o.deleted_at is null
      and oi.deleted_at is null and s.deleted_at is null
      group by o.id, o.created_at, o.aasm_state, oi.sku_id, si.quantity, csi.child_sku_id, oi.status, s.aasm_state, s.id, s.actual_dispatch_date
      order by o.created_at
    ) TO '#{Rails.root}/public/#{filename}' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
    Rails.logger.error("SQL command is: #{sql_command}")
    output = `#{sql_command}`
    Rails.logger.error("SQL output is: #{output}")
    send_file(
      "#{Rails.root}/public/#{filename}",
      filename: filename,
    )
  end

  # GET /inventory_movements/1
  # GET /inventory_movements/1.json
  def show
  end

  # GET /inventory_movements/new
  def new
    @inventory_movement = InventoryMovement.new
  end

  # GET /inventory_movements/1/edit
  def edit
  end

  # PATCH/PUT /inventory_movements/1
  # PATCH/PUT /inventory_movements/1.json
  def update
    respond_to do |format|
      if @inventory_movement.update(inventory_movement_params)
        format.html { redirect_to @inventory_movement, notice: 'Inventory movement was successfully updated.' }
        format.json { render :show, status: :ok, location: @inventory_movement }
      else
        format.html { render :edit }
        format.json { render json: @inventory_movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory_movements/1
  # DELETE /inventory_movements/1.json
  def destroy
    @inventory_movement.destroy
    respond_to do |format|
      format.html { redirect_to inventory_movements_url, notice: 'Inventory movement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def download_putaway_grn_item
    filename = "putaway_grn_item.csv"
    copy_command = <<~SQL.squish
    \\copy (
      select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id),
      case
         when ii.good is true then 'good'
         when ii.good is false then 'bad'
         else null
      end as inventory_type
      from inventory_items ii
      inner join putaway_items pi on ii.putaway_item_id = pi.id
      inner join putaways p on pi.putaway_id = p.id
      where created_on between \'#{@putaway_start_date}\' and \'#{@putaway_end_date}\'
      and putaway_type = 0
      group by pi.id, p.id, ii.sku_id, ii.good
    ) TO '#{Rails.root}/public/putaway_grn_item.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    download_file(filename, copy_command)
  end

  def download_putaway_returned_by_customer
    filename = "putaway_returned_by_customer.csv"
    copy_command= <<~SQL.squish
    \\copy (
      select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id),
      case 
         when ii.good is true then 'good'
         when ii.good is false then 'bad'
         else null
      end as inventory_type
      from putaway_items pi
      inner join inventory_items ii on pi.id = ii.putaway_item_id
      inner join putaways p on pi.putaway_id = p.id
      where created_on between \'#{@putaway_start_date}\' and \'#{@putaway_end_date}\'
      and ii.putaway_type = 1
      and ii.organisation_id = 46
      group by pi.id, p.id, ii.sku_id, ii.good
    ) TO '#{Rails.root}/public/putaway_returned_by_customer.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    download_file(filename, copy_command)
  end

  def download_gatepasses
    filename = "gatepasses.csv"
    copy_command = <<~SQL.squish
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
      ii.sku_id, count(distinct ii.id),
      case 
        when ii.good is true then 'good'
        when ii.good is false then 'bad'
        else null
      end as inventory_type
      from inventory_items ii
      inner join gatepass_items gi on ii.usage_type = 'GatepassItem' and ii.usage_id = gi.id
      inner join gatepasses g on gi.gatepass_id = g.id
      where ii.used_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
      and ii.organisation_id = 1
      and g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
      and g.status = 1
      and g.origin_id = 1
      group by gi.id, g.id, ii.sku_id, ii.good
    ) TO '#{Rails.root}/public/gatepasses.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    download_file(filename, copy_command)
  end

  def download_sold
    filename = "sold.csv"
    copy_command= <<~SQL.squish
    \\copy (
      select o.id, o.created_at, ii.sku_id, o.aasm_state as "order_status",
      oi.status as "order_item_status",count(distinct ii.id),
      s.actual_dispatch_date, s.id as "shipment_id"
      from inventory_items ii
      inner join shipment_items si on ii.usage_type = 'ShipmentItem' and ii.usage_id = si.id
      inner join shipments s on si.shipment_id = s.id
      inner join orders o on s.order_id = o.id
      inner join order_items oi on si.order_item_id = oi.id
      where ii.used_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
      and ii.usage_type = 'ShipmentItem'
      group by ii.sku_id, o.id, oi.id, s.id
    ) TO '#{Rails.root}/public/sold.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
    SQL
    download_file(filename, copy_command)
  end

  def download_file(filename, copy_command)
    config = Wms::Application.config.database_configuration[::Rails.env]
    dbhost, dbuser, dbname, dbpassword = config['host'], config['username'], config['database'], config['password']
    sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
    Rails.logger.error("SQL command is: #{sql_command}")
    output = `#{sql_command}`
    Rails.logger.error("SQL output is: #{output}")
    send_file(
      "#{Rails.root}/public/#{filename}",
      filename: filename,
    )
  end

  def download_all_reports
  filename_command_hash = {}
 
filename = "putaway_grn_item.csv"
copy_command = <<~SQL.squish
 \\copy (
   select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
   from inventory_items ii
   inner join putaway_items pi on ii.putaway_item_id = pi.id
   inner join putaways p on pi.putaway_id = p.id
   where created_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
   and putaway_type = 0
   group by pi.id, p.id, ii.sku_id
 ) TO '#{Rails.root}/public/putaway_grn_item.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   config = Wms::Application.config.database_configuration[::Rails.env]
   dbhost, dbuser, dbname, dbpassword = config['host'], config['username'], config['database'], config['password']
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )


filename = "putaway_grn_item_bad.csv"
copy_command = <<~SQL.squish
 \\copy (
   select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
   from inventory_items ii
   inner join putaway_items pi on ii.putaway_item_id = pi.id
   inner join putaways p on pi.putaway_id = p.id
   where created_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
   and putaway_type = 0
   and good is false
   group by pi.id, p.id, ii.sku_id
 ) TO '#{Rails.root}/public/putaway_grn_item_bad.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )


filename = "putaway_returned_by_customer.csv"
copy_command= <<~SQL.squish
\\copy (
  select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
  from putaway_items pi 
  inner join inventory_items ii on pi.id = ii.putaway_item_id
  inner join putaways p on pi.putaway_id = p.id
  where created_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
  and ii.putaway_type = 1
  and ii.organisation_id = 46
  and ii.good is true
  group by pi.id, p.id, ii.sku_id
) TO '#{Rails.root}/public/putaway_returned_by_customer.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )


filename = "putaway_returned_by_customer_bad.csv"
copy_command= <<~SQL.squish
\\copy (
  select pi.vendor_putaway_item_id, p.vendor_putaway_code, p.vendor_putaway_type, p.unicommerce_creation_at, pi.vendor_inventory_type, ii.sku_id, count(distinct ii.id)
  from inventory_items ii
  inner join putaway_items pi on ii.putaway_item_id = pi.id
  inner join putaways p on pi.putaway_id = p.id
  where created_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
  and ii.putaway_type = 1
  and ii.organisation_id = 46
  and ii.good is false
  group by pi.id, p.id, ii.sku_id
) TO '#{Rails.root}/public/putaway_returned_by_customer_bad.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )


filename = "gatepasses_good.csv"
copy_command = <<~SQL.squish
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
  where ii.used_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
  and ii.organisation_id = 1
  and ii.good is true
  and g.created_in_uniware_at between '2019-10-01 00:00:00' and '2020-07-06 23:59:59'
  and g.status = 1
  and g.origin_id = 1
  and g.for_bad_inventory is false
  group by gi.id, g.id, ii.sku_id
) TO '#{Rails.root}/public/gatepasses_good.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )


filename = "gatepasses_bad.csv"
copy_command = <<~SQL.squish
\\copy (
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
  where ii.used_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
  and ii.organisation_id = 1
  and ii.good is false
  group by gi.id, g.id, ii.sku_id
) TO '#{Rails.root}/public/gatepasses_bad.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )

filename = "sold.csv"
copy_command= <<~SQL.squish
\\copy (
  select o.id, o.created_at, ii.sku_id, o.aasm_state as "order_status",
  oi.status as "order_item_status",count(distinct ii.id),
  s.actual_dispatch_date, s.id as "shipment_id"
  from inventory_items ii 
  inner join shipment_items si on ii.usage_type = 'ShipmentItem' and ii.usage_id = si.id
  inner join shipments s on si.shipment_id = s.id
  inner join orders o on s.order_id = o.id
  inner join order_items oi on si.order_item_id = oi.id
  where ii.used_on between \'#{@all_reports_start_date}\' and \'#{@all_reports_end_date}\'
  and ii.usage_type = 'ShipmentItem'
  group by ii.sku_id, o.id, oi.id, s.id
) TO '#{Rails.root}/public/sold.csv' WITH (FORMAT CSV, header, FORCE_QUOTE *)
SQL
   sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
   Rails.logger.error("SQL command is: #{sql_command}")
   output = `#{sql_command}`
   Rails.logger.error("SQL output is: #{output}")
   send_file(
     "#{Rails.root}/public/#{filename}",
     filename: filename,
   )

#filename_command_hash.each do |filename, copy_command|
#   config = Wms::Application.config.database_configuration[::Rails.env]
#   dbhost, dbuser, dbname, dbpassword = config['host'], config['username'], config['database'], config['password']
#  sql_command = "PGPASSWORD=#{dbpassword} psql -h #{dbhost} -U #{dbuser} -d #{dbname} -c \"#{copy_command}\" 2>&1"
#  Rails.logger.error("SQL command is: #{sql_command}")
#  output = `#{sql_command}`
#  Rails.logger.error("SQL output is: #{output}")
#  send_file(
#    "#{Rails.root}/public/#{filename}",
#    filename: filename,
#  )
#end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_movement
      @inventory_movement = InventoryMovement.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def inventory_movement_params
      params.require(:inventory_movement).permit(:imr_start_date, :imr_end_date, :putaway_start_date, :putaway_end_date, :gatepass_start_date, :gatepass_end_date, :sale_order_start_date, :sale_order_end_date)
    end

    def set_default_date_params
      @initial_date = DateTime.new(2019, 10, 01).beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')

      @imr_start_date = params[:imr_start_date].blank? ? @initial_date : params[:imr_start_date].to_datetime.beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')
      @imr_end_date = params[:imr_end_date].blank? ? DateTime.now.end_of_day.strftime('%Y-%m-%d %H:%M:%S') : params[:imr_end_date].to_datetime.end_of_day.strftime('%Y-%m-%d %H:%M:%S')

      @putaway_start_date = params[:putaway_start_date].blank? ? @initial_date : params[:putaway_start_date].to_datetime.beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')
      @putaway_end_date = params[:putaway_end_date].blank? ? DateTime.now.end_of_day.strftime('%Y-%m-%d %H:%M:%S') : params[:putaway_end_date].to_datetime.end_of_day.strftime('%Y-%m-%d %H:%M:%S')

      @gatepass_start_date = params[:gatepass_start_date].blank? ? @initial_date : params[:gatepass_start_date].to_datetime.beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')
      @gatepass_end_date = params[:gatepass_end_date].blank? ? DateTime.now.end_of_day.strftime('%Y-%m-%d %H:%M:%S') : params[:gatepass_end_date].to_datetime.end_of_day.strftime('%Y-%m-%d %H:%M:%S')

      @sale_order_start_date = params[:sale_order_start_date].blank? ? @initial_date : params[:sale_order_start_date].to_datetime.beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')
      @sale_order_end_date = params[:sale_order_end_date].blank? ? DateTime.now.end_of_day.strftime('%Y-%m-%d %H:%M:%S') : params[:sale_order_end_date].to_datetime.end_of_day.strftime('%Y-%m-%d %H:%M:%S')

      @all_reports_start_date = params[:all_reports_start_date].blank? ? @initial_date : params[:all_reports_start_date].to_datetime.beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')
      @all_reports_end_date = params[:all_reports_end_date].blank? ? DateTime.now.end_of_day.strftime('%Y-%m-%d %H:%M:%S') : params[:all_reports_end_date].to_datetime.end_of_day.strftime('%Y-%m-%d %H:%M:%S')
    end
end
