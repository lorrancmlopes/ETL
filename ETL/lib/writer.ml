open Types

(** Converts an order summary to a CSV row
    @param summary Order summary record
    @return List of strings representing a CSV row
*)
let summary_to_row summary =
  [
    string_of_int summary.order_id;
    Printf.sprintf "%.2f" summary.total_amount;
    Printf.sprintf "%.2f" summary.total_taxes;
  ]

(** Converts an order summary to a CSV string
    @param summary Order summary record
    @return Comma-separated string representation
*)
let summary_to_csv summary =
  Printf.sprintf "%d,%.2f,%.2f" 
    summary.order_id 
    summary.total_amount 
    summary.total_taxes

(** Converts a period summary to a CSV string
    @param summary Period summary record
    @return Comma-separated string representation
*)
let period_summary_to_csv summary =
  Printf.sprintf "%d,%d,%.2f,%.2f,%d" 
    summary.year 
    summary.month 
    summary.avg_revenue 
    summary.avg_taxes 
    summary.total_orders

(** Writes order summaries to a CSV file
    @param filename Output file path
    @param summaries List of order summaries to write
    @raise Failure if the file cannot be created or written
*)
let write_summaries filename summaries =
  try
    let channel = open_out filename in
    let csv = Csv.to_channel channel in
    
    Csv.output_record csv ["order_id"; "total_amount"; "total_taxes"];
    
    List.iter (fun summary ->
      Csv.output_record csv (summary_to_row summary)
    ) summaries;
    
    Csv.close_out csv;
    close_out channel
  with
  | Sys_error msg -> failwith ("Error creating output file: " ^ msg)
  | e -> 
      Printf.eprintf "Error writing CSV file: %s\n" 
        (Printexc.to_string e);
      raise e

(** Writes period summaries to a CSV file
    @param filename Output file path
    @param summaries List of period summaries to write
*)
let write_period_summaries filename summaries =
  let oc = open_out filename in
  output_string oc "year,month,avg_revenue,avg_taxes,total_orders\n";
  List.iter (fun summary ->
    output_string oc (period_summary_to_csv summary ^ "\n")
  ) summaries;
  close_out oc
