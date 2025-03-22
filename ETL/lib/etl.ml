open Types
open Reader
open Helper
open Filter
open Transform
open Writer

let run_etl ~orders_file ~order_items_file ~output_file ~status ~origin =
  let filter_params = { status; origin } in
  
  (* Extração (E) - CSV → Reader → string *)
  let orders_rows = read_orders orders_file in
  let order_items_rows = read_order_items order_items_file in
  
  (* string → helper → Record *)
  let orders = csv_to_orders orders_rows in
  let order_items = csv_to_order_items order_items_rows in
  
  (* Record → filtro → Record *)
  let filtered_orders = filter_by_params orders filter_params in
  
  (* Transformação (T) *)
  let summaries = orders_to_summaries filtered_orders order_items in
  
  (* Load (L) - escrita em CSV *)
  write_summaries output_file summaries;
  
  (* Retornar o num de registros processados *)
  List.length summaries
