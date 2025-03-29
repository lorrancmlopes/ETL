open Etl

(** Ponto de entrada principal do programa ETL *)
let () =
  let usage = "etl [--status STATUS] [--origin ORIGIN] [--input-orders FILE] [--input-items FILE] [--output FILE] [--db-file FILE]" in

  (* Valores padrão para os parâmetros *)
  let orders_file = ref "./data/order.csv" in
  let order_items_file = ref "./data/order_item.csv" in
  let output_file = ref "./data/order_summary.csv" in
  let db_file = ref None in  
  let status = ref None in
  let origin = ref None in
  
  (* Especificação dos argumentos de linha de comando *)
  let specs = [
    ("--status", Arg.String (fun s -> status := Some s), "Filtrar por status (complete, pending, cancelled)");
    ("--origin", Arg.String (fun s -> origin := Some s), "Filtrar por origem (P para físico, O para online)");
    ("--input-orders", Arg.Set_string orders_file, "Arquivo CSV de entrada para ordens ou URL (http://...)");
    ("--input-items", Arg.Set_string order_items_file, "Arquivo CSV de entrada para itens ou URL (http://...)");
    ("--output", Arg.Set_string output_file, "Arquivo CSV de saída");
    ("--db-file", Arg.String (fun s -> db_file := Some s), "Arquivo de banco de dados SQLite para salvar os dados (opcional)");
  ] in
  
  (* Parsear os argumentos de linha de comando *)
  Arg.parse specs (fun _ -> ()) usage;

  (* Exibir informações sobre o processamento que será realizado *)
  Printf.printf "==== Configuração do ETL ====\n";
  Printf.printf "Arquivo de ordens: %s\n" !orders_file;
  Printf.printf "Arquivo de itens: %s\n" !order_items_file;
  Printf.printf "Arquivo de saída: %s\n" !output_file;
  
  (match !db_file with
   | Some file -> Printf.printf "Banco de dados SQLite: %s\n" file
   | None -> Printf.printf "Sem banco de dados SQLite\n");
  
  (match !status with
   | Some s -> Printf.printf "Filtrando por status: %s\n" s
   | None -> Printf.printf "Sem filtro de status\n");
   
  (match !origin with
   | Some o -> Printf.printf "Filtrando por origem: %s\n" o
   | None -> Printf.printf "Sem filtro de origem\n");
  
  Printf.printf "============================\n\n";
  
  (* Executar o processo ETL *)
  let processed_count = run_etl 
    ~orders_file:!orders_file 
    ~order_items_file:!order_items_file 
    ~output_file:!output_file 
    ?status:!status 
    ?origin:!origin 
    ?db_file:!db_file
    () in
  
  (* Exibir resultado do processamento *)
  Printf.printf "\nProcessamento concluído. Foram processados %d pedidos.\n" processed_count