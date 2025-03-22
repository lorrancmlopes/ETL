open Etl

let () =
  let usage = "etl [--status STATUS] [--origin ORIGIN] [--input-orders FILE] [--input-items FILE] [--output FILE]" in

  let orders_file = ref "./data/order.csv" in
  let order_items_file = ref "./data/order_item.csv" in
  let output_file = ref "./data/order_summary.csv" in
  let status = ref None in
  let origin = ref None in
  
  let specs = [
    ("--status", Arg.String (fun s -> status := Some s), "Filtrar por status (complete, pending, cancelled)");
    ("--origin", Arg.String (fun s -> origin := Some s), "Filtrar por origem (P para físico, O para online)");
    ("--input-orders", Arg.Set_string orders_file, "Arquivo CSV de entrada para ordens ou URL (http://...)");
    ("--input-items", Arg.Set_string order_items_file, "Arquivo CSV de entrada para itens ou URL (http://...)");
    ("--output", Arg.Set_string output_file, "Arquivo CSV de saída");
  ] in
  
  Arg.parse specs (fun _ -> ()) usage;

  Printf.printf "Iniciando processamento ETL...\n";
  Printf.printf "Arquivo de ordens: %s\n" !orders_file;
  Printf.printf "Arquivo de itens: %s\n" !order_items_file;
  Printf.printf "Arquivo de saída: %s\n" !output_file;
  
  (match !status with
   | Some s -> Printf.printf "Filtrando por status: %s\n" s
   | None -> Printf.printf "Sem filtro de status\n");
   
  (match !origin with
   | Some o -> Printf.printf "Filtrando por origem: %s\n" o
   | None -> Printf.printf "Sem filtro de origem\n");
  
  let processed_count = run_etl 
    ~orders_file:!orders_file 
    ~order_items_file:!order_items_file 
    ~output_file:!output_file 
    ~status:!status 
    ~origin:!origin in
  
  Printf.printf "Processamento concluído. Foram processados %d pedidos.\n" processed_count
