open OUnit2

(** Test Helper module functions *)
let test_helper_string_to_int _ =
  assert_equal 123 (Etl.Helper.string_to_int "123");
  assert_equal 0 (Etl.Helper.string_to_int "0");
  assert_equal (-456) (Etl.Helper.string_to_int "-456");
  assert_raises (Failure "Could not convert to int: abc") (fun () -> Etl.Helper.string_to_int "abc");
  assert_raises (Failure "Could not convert to int: 123.45") (fun () -> Etl.Helper.string_to_int "123.45")

let test_helper_string_to_float _ =
  assert_equal 123.0 (Etl.Helper.string_to_float "123");
  assert_equal 123.45 (Etl.Helper.string_to_float "123.45");
  assert_equal 0.0 (Etl.Helper.string_to_float "0");
  assert_equal (-456.78) (Etl.Helper.string_to_float "-456.78");
  assert_raises (Failure "Could not convert to float: abc") (fun () -> Etl.Helper.string_to_float "abc")

let test_helper_row_to_order _ =
  let row = ["1"; "101"; "2023-01-01"; "Complete"; "O"] in
  let expected = { Etl.Types.id = 1; client_id = 101; order_date = "2023-01-01"; status = "Complete"; origin = "O" } in
  assert_equal expected (Etl.Helper.row_to_order row);
  
  (* Test invalid formats *)
  let invalid_row1 = ["abc"; "101"; "2023-01-01"; "Complete"; "O"] in
  assert_raises (Failure "Invalid format for order: abc,101,2023-01-01,Complete,O") 
    (fun () -> Etl.Helper.row_to_order invalid_row1);
    
  let invalid_row2 = ["1"; "101"] in  (* Too few elements *)
  assert_raises (Failure "Invalid format for order: 1,101") 
    (fun () -> Etl.Helper.row_to_order invalid_row2)

(** Test fixtures for transform tests *)
let sample_orders = [
  { Etl.Types.id = 1; client_id = 101; order_date = "2023-01-15"; status = "Complete"; origin = "O" };
  { Etl.Types.id = 2; client_id = 102; order_date = "2023-01-20"; status = "Pending"; origin = "P" };
  { Etl.Types.id = 3; client_id = 103; order_date = "2023-02-05"; status = "Complete"; origin = "P" }
]

let sample_order_items = [
  { Etl.Types.order_id = 1; product_id = 201; quantity = 2; price = 10.0; tax = 0.5 };
  { Etl.Types.order_id = 1; product_id = 202; quantity = 1; price = 20.0; tax = 1.0 };
  { Etl.Types.order_id = 2; product_id = 201; quantity = 3; price = 10.0; tax = 0.5 };
  { Etl.Types.order_id = 3; product_id = 203; quantity = 1; price = 30.0; tax = 1.5 }
]

(** Test Transform module functions *)
let test_transform_join_orders_and_items _ =
  let result = Etl.Transform.join_orders_and_items sample_orders sample_order_items in
  
  (* Check total count *)
  assert_equal 4 (List.length result);
  
  (* Check first joined record *)
  let first = List.nth result 0 in
  assert_equal 1 first.Etl.Transform.order_id;
  assert_equal "Complete" first.status;
  assert_equal "O" first.origin;
  assert_equal 20.0 first.item_amount;
  assert_equal 1.0 first.item_tax;
  
  (* Test with non-matching order_id *)
  let non_matching_items = [{ Etl.Types.order_id = 999; product_id = 201; quantity = 2; price = 10.0; tax = 0.5 }] in
  let result_empty = Etl.Transform.join_orders_and_items sample_orders non_matching_items in
  assert_equal 0 (List.length result_empty)
  
let test_transform_create_order_summary _ =
  (* Test with multiple records for same order *)
  let joined_records = [
    { Etl.Transform.order_id = 1; status = "Complete"; origin = "O"; item_amount = 20.0; item_tax = 1.0 };
    { Etl.Transform.order_id = 1; status = "Complete"; origin = "O"; item_amount = 30.0; item_tax = 1.5 }
  ] in
  
  let result = Etl.Transform.create_order_summary_from_joined joined_records in
  (* Use assert_bool instead of match with assert_failure *)
  assert_bool "Expected Some summary, got None" (result <> None);
  
  (* Now extract the summary knowing it's not None *)
  let summary = match result with
  | Some s -> s
  | None -> failwith "This should not happen as we already checked result <> None"
  in
  
  assert_equal 1 summary.Etl.Types.order_id;
  assert_equal 50.0 summary.total_amount;
  assert_equal 2.5 summary.total_taxes;
  
  (* Test with empty list *)
  let empty_result = Etl.Transform.create_order_summary_from_joined [] in
  assert_equal None empty_result

let test_transform_with_join _ =
  let result = Etl.Transform.transform_with_join ~orders:sample_orders ~order_items:sample_order_items () in
  
  (* Check count of order summaries *)
  assert_equal 3 (List.length result);
  
  (* Check first order summary *)
  let first = List.find (fun s -> s.Etl.Types.order_id = 1) result in
  assert_equal 1 first.Etl.Types.order_id;
  assert_equal 40.0 first.total_amount;
  assert_equal 2.0 first.total_taxes;
  
  (* Test with status filter *)
  let status_result = Etl.Transform.transform_with_join ~orders:sample_orders ~order_items:sample_order_items 
                      ~status:"Complete" () in
  assert_equal 2 (List.length status_result);
  assert_bool "Order 1 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 1) status_result);
  assert_bool "Order 3 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 3) status_result)

let test_calculate_period_summaries _ =
  (* Create sample order summaries *)
  let order_summaries = [
    { Etl.Types.order_id = 1; total_amount = 40.0; total_taxes = 2.0 };
    { Etl.Types.order_id = 2; total_amount = 30.0; total_taxes = 1.5 };
    { Etl.Types.order_id = 3; total_amount = 30.0; total_taxes = 1.5 }
  ] in
  
  let result = Etl.Transform.calculate_period_summaries order_summaries sample_orders in
  
  (* Check count - should be 2 periods (Jan and Feb 2023) *)
  assert_equal 2 (List.length result);
  
  (* Find January period *)
  let jan_period = List.find (fun p -> p.Etl.Types.year = 2023 && p.month = 1) result in
  assert_equal 2023 jan_period.Etl.Types.year;
  assert_equal 1 jan_period.month;
  assert_equal 35.0 jan_period.avg_revenue;  (* (40 + 30) / 2 *)
  assert_equal 1.75 jan_period.avg_taxes;    (* (2 + 1.5) / 2 *)
  assert_equal 2 jan_period.total_orders;
  
  (* Find February period *)
  let feb_period = List.find (fun p -> p.Etl.Types.year = 2023 && p.month = 2) result in
  assert_equal 2023 feb_period.Etl.Types.year;
  assert_equal 2 feb_period.month;
  assert_equal 30.0 feb_period.avg_revenue;  (* 30 / 1 *)
  assert_equal 1.5 feb_period.avg_taxes;     (* 1.5 / 1 *)
  assert_equal 1 feb_period.total_orders

(** Test Filter module functions *)
let test_filter_by_params _ =
  let sample_orders = [
    { Etl.Types.id = 1; client_id = 101; order_date = "2023-01-01"; status = "Complete"; origin = "O" };
    { Etl.Types.id = 2; client_id = 102; order_date = "2023-01-02"; status = "Pending"; origin = "P" };
    { Etl.Types.id = 3; client_id = 103; order_date = "2023-01-03"; status = "Complete"; origin = "P" };
    { Etl.Types.id = 4; client_id = 104; order_date = "2023-01-04"; status = "Cancelled"; origin = "O" }
  ] in
  
  (* Test no filter *)
  let params1 = { Etl.Types.status = None; origin = None } in
  let result1 = Etl.Filter.filter_by_params sample_orders params1 in
  assert_equal 4 (List.length result1);
  assert_equal sample_orders result1;
  
  (* Test status filter *)
  let params2 = { Etl.Types.status = Some "Complete"; origin = None } in
  let result2 = Etl.Filter.filter_by_params sample_orders params2 in
  assert_equal 2 (List.length result2);
  assert_equal 1 (List.nth result2 0).Etl.Types.id;
  assert_equal 3 (List.nth result2 1).Etl.Types.id;
  
  (* Test origin filter *)
  let params3 = { Etl.Types.status = None; origin = Some "P" } in
  let result3 = Etl.Filter.filter_by_params sample_orders params3 in
  assert_equal 2 (List.length result3);
  assert_equal 2 (List.nth result3 0).Etl.Types.id;
  assert_equal 3 (List.nth result3 1).Etl.Types.id;
  
  (* Test combined filter *)
  let params4 = { Etl.Types.status = Some "Complete"; origin = Some "P" } in
  let result4 = Etl.Filter.filter_by_params sample_orders params4 in
  assert_equal 1 (List.length result4);
  assert_equal 3 (List.nth result4 0).Etl.Types.id

let () =
  run_test_tt_main (
    "Etl tests" >:::
    [
      "helper_string_to_int" >:: test_helper_string_to_int;
      "helper_string_to_float" >:: test_helper_string_to_float;
      "helper_row_to_order" >:: test_helper_row_to_order;
      "filter_by_params" >:: test_filter_by_params;
      "transform_join_orders_and_items" >:: test_transform_join_orders_and_items;
      "transform_create_order_summary" >:: test_transform_create_order_summary;
      "transform_with_join" >:: test_transform_with_join;
      "calculate_period_summaries" >:: test_calculate_period_summaries;
    ]
  )
