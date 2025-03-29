open OUnit2

(** Test helper functions for string conversions *)
let test_string_to_int _ =
  assert_equal 123 (Etl.Helper.string_to_int "123");
  assert_equal 0 (Etl.Helper.string_to_int "0");
  assert_equal (-456) (Etl.Helper.string_to_int "-456");
  assert_raises (Failure "Could not convert to int: abc") (fun () -> Etl.Helper.string_to_int "abc");
  assert_raises (Failure "Could not convert to int: 123.45") (fun () -> Etl.Helper.string_to_int "123.45")

let test_string_to_float _ =
  assert_equal 123.0 (Etl.Helper.string_to_float "123");
  assert_equal 123.45 (Etl.Helper.string_to_float "123.45");
  assert_equal 0.0 (Etl.Helper.string_to_float "0");
  assert_equal (-456.78) (Etl.Helper.string_to_float "-456.78");
  assert_raises (Failure "Could not convert to float: abc") (fun () -> Etl.Helper.string_to_float "abc")

(** Test CSV row conversion functions *)
let test_row_to_order _ =
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

let test_row_to_order_item _ =
  let row = ["1"; "201"; "2"; "10.99"; "0.05"] in
  let expected = { Etl.Types.order_id = 1; product_id = 201; quantity = 2; price = 10.99; tax = 0.05 } in
  assert_equal expected (Etl.Helper.row_to_order_item row);
  
  (* Test invalid formats *)
  let invalid_row1 = ["1"; "abc"; "2"; "10.99"; "0.05"] in
  assert_raises (Failure "Invalid format for order item: 1,abc,2,10.99,0.05") 
    (fun () -> Etl.Helper.row_to_order_item invalid_row1);
    
  let invalid_row2 = ["1"; "201"; "2"] in  (* Too few elements *)
  assert_raises (Failure "Invalid format for order item: 1,201,2") 
    (fun () -> Etl.Helper.row_to_order_item invalid_row2)

let test_csv_to_orders _ =
  let rows = [
    ["1"; "101"; "2023-01-01"; "Complete"; "O"];
    ["2"; "102"; "2023-01-02"; "Pending"; "P"]
  ] in
  let expected = [
    { Etl.Types.id = 1; client_id = 101; order_date = "2023-01-01"; status = "Complete"; origin = "O" };
    { Etl.Types.id = 2; client_id = 102; order_date = "2023-01-02"; status = "Pending"; origin = "P" }
  ] in
  assert_equal expected (Etl.Helper.csv_to_orders rows)

let test_csv_to_order_items _ =
  let rows = [
    ["1"; "201"; "2"; "10.99"; "0.05"];
    ["1"; "202"; "1"; "15.50"; "0.07"]
  ] in
  let expected = [
    { Etl.Types.order_id = 1; product_id = 201; quantity = 2; price = 10.99; tax = 0.05 };
    { Etl.Types.order_id = 1; product_id = 202; quantity = 1; price = 15.50; tax = 0.07 }
  ] in
  assert_equal expected (Etl.Helper.csv_to_order_items rows)

(** Test suite *)
let () =
  run_test_tt_main (
    "Helper module tests" >::: [
      "test_string_to_int" >:: test_string_to_int;
      "test_string_to_float" >:: test_string_to_float;
      "test_row_to_order" >:: test_row_to_order;
      "test_row_to_order_item" >:: test_row_to_order_item;
      "test_csv_to_orders" >:: test_csv_to_orders;
      "test_csv_to_order_items" >:: test_csv_to_order_items;
    ]
  ) 