open Types

(* Create a Map module for integer keys *)
module IntMap = Map.Make(struct
  type t = int
  let compare = compare
end)

(** Type representing a record after joining orders and order_items *)
type joined_record = {
  order_id: int;
  status: string;
  origin: string;
  item_amount: float;
  item_tax: float;
}

(** Performs a join operation between orders and order_items
    @param orders List of orders
    @param order_items List of order items
    @return List of records joined via inner join
*)
let join_orders_and_items (orders : order list) (order_items : order_item list) : joined_record list =
  let orders_map = List.fold_left (fun map order ->
    IntMap.add order.id order map
  ) IntMap.empty orders in

  List.fold_left (fun (acc : joined_record list) (item : order_item) ->
    match IntMap.find_opt item.order_id orders_map with
    | Some order -> 
        { order_id = order.id;
          status = order.status;
          origin = order.origin;
          item_amount = item.price *. float_of_int item.quantity;
          item_tax = item.tax *. float_of_int item.quantity;
        } :: acc
    | None -> acc
  ) [] order_items
  |> List.rev

(** Creates an order summary from joined records
    @param joined_records List of records from the same order after joining
    @return Order summary
*)
let create_order_summary_from_joined joined_records =
  match joined_records with
  | [] -> None
  | first :: _ ->
      let total_amount = ref 0.0 in
      let total_taxes = ref 0.0 in
      
      List.iter (fun record ->
        total_amount := !total_amount +. record.item_amount;
        total_taxes := !total_taxes +. record.item_tax;
      ) joined_records;
      
      Some {
        order_id = first.order_id;
        total_amount = !total_amount;
        total_taxes = !total_taxes;
      }

(** Main transformation function using join
    @param orders List of orders
    @param order_items List of order items
    @param status Optional status filter
    @param origin Optional origin filter
    @return List of order summaries
*)
let transform_with_join ~orders:(orders:order list) ~order_items:(order_items:order_item list) ?status ?origin () : order_summary list =
  let joined = join_orders_and_items orders order_items in
  
  let filtered = joined |> List.filter (fun record ->
    (match status with
     | None -> true
     | Some s -> record.status = s)
    &&
    (match origin with
     | None -> true
     | Some o -> record.origin = o)
  ) in
  
  let grouped = List.fold_left (fun map record ->
    let current = match IntMap.find_opt record.order_id map with
      | Some records -> record :: records
      | None -> [record]
    in
    IntMap.add record.order_id current map
  ) IntMap.empty filtered in
  
  IntMap.fold (fun _order_id records acc ->
    match create_order_summary_from_joined records with
    | Some summary -> summary :: acc
    | None -> acc
  ) grouped []
  |> List.rev

(** Calculates summaries by period (month/year)
    @param summaries List of order summaries
    @param orders List of original orders
    @return List of period summaries
*)
let calculate_period_summaries (summaries: order_summary list) (orders: order list) : period_summary list =
  let period_map = List.fold_left (fun (acc: (int * float * float) IntMap.t) (summary: order_summary) ->
    let order = List.find (fun o -> o.id = summary.order_id) orders in
    let date_parts = String.split_on_char '-' order.order_date in
    let year = int_of_string (List.nth date_parts 0) in
    let month = int_of_string (List.nth date_parts 1) in
    let period_key = (year * 100) + month in
    match IntMap.find_opt period_key acc with
    | Some (count, total_revenue, total_taxes) ->
        IntMap.add period_key (count + 1, total_revenue +. summary.total_amount, total_taxes +. summary.total_taxes) acc
    | None ->
        IntMap.add period_key (1, summary.total_amount, summary.total_taxes) acc
  ) IntMap.empty summaries in
  
  IntMap.fold (fun period_key (count, total_revenue, total_taxes) acc ->
    let year = period_key / 100 in
    let month = period_key mod 100 in
    {
      year;
      month;
      avg_revenue = total_revenue /. float_of_int count;
      avg_taxes = total_taxes /. float_of_int count;
      total_orders = count;
    } :: acc
  ) period_map []