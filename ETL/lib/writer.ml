open Types

let summary_to_row summary =
  [
    string_of_int summary.order_id;
    Printf.sprintf "%.2f" summary.total_amount;
    Printf.sprintf "%.2f" summary.total_taxes;
  ]

let write_summaries filename summaries =
  try
    let channel = open_out filename in
    let csv = Csv.to_channel channel in
    
    (* cabeçalho *)
    Csv.output_record csv ["order_id"; "total_amount"; "total_taxes"];
    
    List.iter (fun summary ->
      Csv.output_record csv (summary_to_row summary)
    ) summaries;
    
    Csv.close_out csv;
    close_out channel
  with
  | Sys_error msg -> failwith ("Erro ao criar arquivo de saída: " ^ msg)
  | e -> 
      Printf.eprintf "Erro ao escrever arquivo CSV: %s\n" 
        (Printexc.to_string e);
      raise e
