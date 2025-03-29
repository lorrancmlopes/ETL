open OUnit2

(** Test fixtures - sample orders for testing *)
let sample_orders = [
  { Etl.Types.id = 1; client_id = 101; order_date = "2023-01-01"; status = "Complete"; origin = "O" };
  { Etl.Types.id = 2; client_id = 102; order_date = "2023-01-02"; status = "Pending"; origin = "P" };
  { Etl.Types.id = 3; client_id = 103; order_date = "2023-01-03"; status = "Complete"; origin = "P" };
  { Etl.Types.id = 4; client_id = 104; order_date = "2023-01-04"; status = "Cancelled"; origin = "O" }
]

(** Test filter_by_params function with different filter parameters *)
let test_filter_by_params_no_filter _ =
  let params = { Etl.Types.status = None; origin = None } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 4 (List.length result);
  assert_equal sample_orders result

let test_filter_by_params_status_only _ =
  (* Filter by Complete status *)
  let params = { Etl.Types.status = Some "Complete"; origin = None } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 2 (List.length result);
  assert_equal 1 (List.nth result 0).Etl.Types.id;
  assert_equal 3 (List.nth result 1).Etl.Types.id;
  
  (* Filter by Pending status *)
  let params = { Etl.Types.status = Some "Pending"; origin = None } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 1 (List.length result);
  assert_equal 2 (List.nth result 0).Etl.Types.id;
  
  (* Filter by non-existent status *)
  let params = { Etl.Types.status = Some "NonExistent"; origin = None } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 0 (List.length result)

let test_filter_by_params_origin_only _ =
  (* Filter by origin O (online) *)
  let params = { Etl.Types.status = None; origin = Some "O" } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 2 (List.length result);
  assert_equal 1 (List.nth result 0).Etl.Types.id;
  assert_equal 4 (List.nth result 1).Etl.Types.id;
  
  (* Filter by origin P (physical) *)
  let params = { Etl.Types.status = None; origin = Some "P" } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 2 (List.length result);
  assert_equal 2 (List.nth result 0).Etl.Types.id;
  assert_equal 3 (List.nth result 1).Etl.Types.id;
  
  (* Filter by non-existent origin *)
  let params = { Etl.Types.status = None; origin = Some "X" } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 0 (List.length result)

let test_filter_by_params_both_filters _ =
  (* Filter by Complete status and O origin *)
  let params = { Etl.Types.status = Some "Complete"; origin = Some "O" } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 1 (List.length result);
  assert_equal 1 (List.nth result 0).Etl.Types.id;
  
  (* Filter by Complete status and P origin *)
  let params = { Etl.Types.status = Some "Complete"; origin = Some "P" } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 1 (List.length result);
  assert_equal 3 (List.nth result 0).Etl.Types.id;
  
  (* Filter by non-matching combination *)
  let params = { Etl.Types.status = Some "Cancelled"; origin = Some "P" } in
  let result = Etl.Filter.filter_by_params sample_orders params in
  assert_equal 0 (List.length result)

(** Test suite *)
let () =
  run_test_tt_main (
    "Filter module tests" >::: [
      "test_filter_by_params_no_filter" >:: test_filter_by_params_no_filter;
      "test_filter_by_params_status_only" >:: test_filter_by_params_status_only;
      "test_filter_by_params_origin_only" >:: test_filter_by_params_origin_only;
      "test_filter_by_params_both_filters" >:: test_filter_by_params_both_filters;
    ]
  ) 