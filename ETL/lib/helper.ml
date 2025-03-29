open Types

(** Converts a string to an integer
    @param s String to convert
    @return Parsed integer value
    @raise Failure if the string cannot be converted
*)
let string_to_int s = 
  try int_of_string (String.trim s) 
  with _ -> failwith ("Could not convert to int: " ^ s)

(** Converts a string to a float
    @param s String to convert
    @return Parsed float value
    @raise Failure if the string cannot be converted
*)
let string_to_float s = 
  try float_of_string (String.trim s) 
  with _ -> failwith ("Could not convert to float: " ^ s)

(** Converts a CSV row to an order record
    @param row CSV row as a list of strings
    @return Order record
    @raise Failure if the row has an invalid format
*)
let row_to_order row =
  try
    let id = string_to_int (List.nth row 0) in
    let client_id = string_to_int (List.nth row 1) in
    let order_date = List.nth row 2 in
    let status = List.nth row 3 in
    let origin = List.nth row 4 in
    { id; client_id; order_date; status; origin }
  with _ -> 
    failwith ("Invalid format for order: " ^ String.concat "," row)

(** Converts a CSV row to an order item record
    @param row CSV row as a list of strings
    @return Order item record
    @raise Failure if the row has an invalid format
*)
let row_to_order_item row =
  try
    let order_id = string_to_int (List.nth row 0) in
    let product_id = string_to_int (List.nth row 1) in
    let quantity = string_to_int (List.nth row 2) in
    let price = string_to_float (List.nth row 3) in
    let tax = string_to_float (List.nth row 4) in
    { order_id; product_id; quantity; price; tax }
  with _ -> 
    failwith ("Invalid format for order item: " ^ String.concat "," row)

(** Converts a list of CSV rows to a list of orders
    @param rows List of CSV rows
    @return List of order records
*)
let csv_to_orders rows = List.map row_to_order rows

(** Converts a list of CSV rows to a list of order items
    @param rows List of CSV rows
    @return List of order item records
*)
let csv_to_order_items rows = List.map row_to_order_item rows
