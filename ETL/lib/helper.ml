open Types

(* Funções auxiliares para conversão de tipos *)
let string_to_int s = 
  try int_of_string (String.trim s) 
  with _ -> failwith ("Não foi possível converter para int: " ^ s)

let string_to_float s = 
  try float_of_string (String.trim s) 
  with _ -> failwith ("Não foi possível converter para float: " ^ s)

(* Helper para converter linha CSV em record de ordem *)
let row_to_order row =
  try
    let id = string_to_int (List.nth row 0) in
    let client_id = string_to_int (List.nth row 1) in
    let order_date = List.nth row 2 in
    let status = List.nth row 3 in
    let origin = List.nth row 4 in
    { id; client_id; order_date; status; origin }
  with _ -> 
    failwith ("Formato inválido para ordem: " ^ String.concat "," row)

(* Helper para converter linha CSV em record de item de pedido *)
let row_to_order_item row =
  try
    let order_id = string_to_int (List.nth row 0) in
    let product_id = string_to_int (List.nth row 1) in
    let quantity = string_to_int (List.nth row 2) in
    let price = string_to_float (List.nth row 3) in
    let tax = string_to_float (List.nth row 4) in
    { order_id; product_id; quantity; price; tax }
  with _ -> 
    failwith ("Formato inválido para item de pedido: " ^ String.concat "," row)

(* Funções para converter listas de strings em listas de records *)
let csv_to_orders rows = List.map row_to_order rows
let csv_to_order_items rows = List.map row_to_order_item rows
