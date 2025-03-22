open Types

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
