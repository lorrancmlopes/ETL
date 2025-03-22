open Types

let calculate_item_amount item =
  item.price *. float_of_int item.quantity

let calculate_item_tax item =
  let amount = calculate_item_amount item in
  amount *. (item.tax /. 100.0)

let create_order_summary order_id items =
  let total_amount_ref = ref 0.0 in
  let total_taxes_ref = ref 0.0 in
  
  List.iter (fun (item : order_item) ->
    if item.order_id = order_id then begin
      let item_amount = item.price *. float_of_int item.quantity in
      let item_tax = item_amount *. (item.tax /. 100.0) in
      total_amount_ref := !total_amount_ref +. item_amount;
      total_taxes_ref := !total_taxes_ref +. item_tax;
    end
  ) items;
  
  (* record de resumo *)
  { 
    order_id; 
    total_amount = !total_amount_ref; 
    total_taxes = !total_taxes_ref 
  }

let orders_to_summaries orders items =
  List.map (fun order -> 
    create_order_summary order.id items
  ) orders