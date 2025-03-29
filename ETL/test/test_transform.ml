open OUnit2

(** Test fixtures - sample orders and order_items for testing *)
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

(** Test join_orders_and_items function *)
let test_join_orders_and_items _ =
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
  
  (* Check second joined record *)
  let second = List.nth result 1 in
  assert_equal 1 second.Etl.Transform.order_id;
  assert_equal "Complete" second.status;
  assert_equal "O" second.origin;
  assert_equal 20.0 second.item_amount;
  assert_equal 1.0 second.item_tax;
  
  (* Test with non-matching order_id *)
  let non_matching_items = [{ Etl.Types.order_id = 999; product_id = 201; quantity = 2; price = 10.0; tax = 0.5 }] in
  let result_empty = Etl.Transform.join_orders_and_items sample_orders non_matching_items in
  assert_equal 0 (List.length result_empty)

(** Test create_order_summary_from_joined function *)
let test_create_order_summary_from_joined _ =
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

(** Test transform_with_join function *)
let test_transform_with_join_no_filter _ =
  let result = Etl.Transform.transform_with_join ~orders:sample_orders ~order_items:sample_order_items () in
  
  (* Check count of order summaries *)
  assert_equal 3 (List.length result);
  
  (* Check first order summary *)
  let first = List.find (fun s -> s.Etl.Types.order_id = 1) result in
  assert_equal 1 first.Etl.Types.order_id;
  assert_equal 40.0 first.total_amount;
  assert_equal 2.0 first.total_taxes;
  
  (* Check second order summary *)
  let second = List.find (fun s -> s.Etl.Types.order_id = 2) result in
  assert_equal 2 second.Etl.Types.order_id;
  assert_equal 30.0 second.total_amount;
  assert_equal 1.5 second.total_taxes

let test_transform_with_join_with_filters _ =
  (* Filter by status *)
  let status_result = Etl.Transform.transform_with_join ~orders:sample_orders ~order_items:sample_order_items 
                        ~status:"Complete" () in
  assert_equal 2 (List.length status_result);
  assert_bool "Order 1 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 1) status_result);
  assert_bool "Order 3 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 3) status_result);
  
  (* Filter by origin *)
  let origin_result = Etl.Transform.transform_with_join ~orders:sample_orders ~order_items:sample_order_items 
                        ~origin:"P" () in
  assert_equal 2 (List.length origin_result);
  assert_bool "Order 2 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 2) origin_result);
  assert_bool "Order 3 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 3) origin_result);
  
  (* Filter by both status and origin *)
  let combined_result = Etl.Transform.transform_with_join ~orders:sample_orders ~order_items:sample_order_items 
                          ~status:"Complete" ~origin:"P" () in
  assert_equal 1 (List.length combined_result);
  assert_bool "Order 3 should be in results" 
    (List.exists (fun s -> s.Etl.Types.order_id = 3) combined_result)

(** Test calculate_period_summaries function *)
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

(** Test suite *)
let () =
  run_test_tt_main (
    "Transform module tests" >::: [
      "test_join_orders_and_items" >:: test_join_orders_and_items;
      "test_create_order_summary_from_joined" >:: test_create_order_summary_from_joined;
      "test_transform_with_join_no_filter" >:: test_transform_with_join_no_filter;
      "test_transform_with_join_with_filters" >:: test_transform_with_join_with_filters;
      "test_calculate_period_summaries" >:: test_calculate_period_summaries;
    ]
  ) 