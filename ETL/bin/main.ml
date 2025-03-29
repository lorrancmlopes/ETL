open Arg
open Etl

(** CLI entry point for the ETL application.
    This module parses command line arguments and calls the ETL processing function.
*)

(** Path to the orders CSV file *)
let orders_file = ref ""

(** Path to the order items CSV file *)
let order_items_file = ref ""

(** Path to the output CSV file *)
let output_file = ref ""

(** Optional path to period summary output file *)
let period_output_file = ref None

(** Optional status filter *)
let status = ref None

(** Optional origin filter *)
let origin = ref None

(** Optional database file path *)
let db_file = ref None

(** List of command line argument specifications *)
let speclist = [
  ("--input-orders", Set_string orders_file, "CSV file containing orders");
  ("--input-items", Set_string order_items_file, "CSV file containing order items");
  ("--output", Set_string output_file, "Output CSV file");
  ("--period-output", String (fun s -> period_output_file := Some s), "Optional CSV file for period summary output");
  ("--status", String (fun s -> status := Some s), "Filter by status (Complete, Pending, Cancelled)");
  ("--origin", String (fun s -> origin := Some s), "Filter by origin (P or O)");
  ("--db-file", String (fun s -> db_file := Some s), "Optional SQLite database file");
]

(** Usage message for the command line interface *)
let usage_msg = "ETL - Order Processing\n\nUsage: etl [options]\n\nOptions:"

(** Helper function to ensure output paths are in the data directory *)
let ensure_data_dir path =
  if String.length path > 0 && 
     (path.[0] = '/' || path.[0] = '.' || 
      (String.length path > 1 && path.[1] = ':') ||
      String.contains path '/') then
    path
  else
    "data/" ^ path

(** Main entry point *)
let () =
  parse speclist (fun _ -> ()) usage_msg;
  
  if !orders_file = "" then (
    Printf.eprintf "Error: --input-orders is required\n";
    exit 1
  );
  if !order_items_file = "" then (
    Printf.eprintf "Error: --input-items is required\n";
    exit 1
  );
  if !output_file = "" then (
    Printf.eprintf "Error: --output is required\n";
    exit 1
  );
  
  (* Ensure output paths are in the data directory *)
  output_file := ensure_data_dir !output_file;
  period_output_file := Option.map ensure_data_dir !period_output_file;
  db_file := Option.map ensure_data_dir !db_file;
  
  Printf.printf "\nConfiguration:\n";
  Printf.printf "Orders file: %s\n" !orders_file;
  Printf.printf "Order items file: %s\n" !order_items_file;
  Printf.printf "Output file: %s\n" !output_file;
  (match !period_output_file with
   | Some file -> Printf.printf "Period output file: %s\n" file
   | None -> ());
  (match !status with
   | Some s -> Printf.printf "Status filter: %s\n" s
   | None -> ());
  (match !origin with
   | Some o -> Printf.printf "Origin filter: %s\n" o
   | None -> ());
  (match !db_file with
   | Some db -> Printf.printf "Database file: %s\n" db
   | None -> ());
  Printf.printf "\n";
  
  let processed_count = run_etl 
    ~orders_file:!orders_file 
    ~order_items_file:!order_items_file 
    ~output_file:!output_file 
    ?period_output_file:!period_output_file
    ?status:!status 
    ?origin:!origin 
    ?db_file:!db_file
    () in
  
  Printf.printf "Processed %d summaries\n" processed_count