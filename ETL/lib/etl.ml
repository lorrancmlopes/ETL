open Reader
open Helper
open Transform
open Writer
open Db 

(** Expose the Types module *)
module Types = Types

(** Expose the Helper module *)
module Helper = Helper

(** Expose the Filter module *)
module Filter = Filter

(** Expose the Transform module *)
module Transform = Transform

(** Executes the ETL process with join operation
    @param orders_file CSV file containing orders
    @param order_items_file CSV file containing order items
    @param output_file Output CSV file for results
    @param period_output_file Optional CSV file for period summary output
    @param status Optional status filter
    @param origin Optional origin filter
    @param db_file Optional database file path
    @return Number of processed summaries
*)
let run_etl ~orders_file ~order_items_file ~output_file ?period_output_file ?status ?origin ?db_file () =
    let orders_csv = read_orders orders_file in
    let order_items_csv = read_order_items order_items_file in
    
    let orders = csv_to_orders orders_csv in
    let order_items = csv_to_order_items order_items_csv in
    
    let summaries = transform_with_join ~orders ~order_items ?status ?origin () in
    
    write_summaries output_file summaries;
    
    (match period_output_file with
    | Some file ->
        let period_summaries = calculate_period_summaries summaries orders in
        write_period_summaries file period_summaries;
        Printf.printf "Period summaries saved to %s\n" file
    | None -> ());
    
    match db_file with
    | Some db -> 
        let count = save_summaries_to_db db summaries in
        Printf.printf "Saved %d summaries to database\n" count;
        List.length summaries
    | None -> List.length summaries