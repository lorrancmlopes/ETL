open Types

(** Filters a list of orders based on the given parameters
    @param orders List of orders to filter
    @param params Filter parameters (status and origin)
    @return Filtered list of orders that match the parameters
*)
let filter_by_params orders params =
  List.filter (fun order ->
    let { id = _; client_id = _; order_date = _; status; origin } = order in
    
    (match params.status with
     | None -> true
     | Some s -> s = status)
    &&
    (match params.origin with
     | None -> true
     | Some o -> o = origin)
  ) orders
