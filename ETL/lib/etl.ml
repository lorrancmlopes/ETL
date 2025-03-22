open Types
open Reader
open Helper
open Filter
open Transform
open Writer
open Db 

(** Função principal que orquestra o processo ETL completo.
    @param orders_file Caminho ou URL para o arquivo CSV de pedidos
    @param order_items_file Caminho ou URL para o arquivo CSV de itens de pedido
    @param output_file Caminho para o arquivo CSV de saída
    @param db_file Caminho opcional para o arquivo de banco de dados SQLite
    @param status Filtro opcional por status
    @param origin Filtro opcional por origem
    @return Número de pedidos processados
*)
let run_etl ~orders_file ~order_items_file ~output_file ~db_file ~status ~origin =
  Printf.printf "Iniciando processo ETL...\n";
  
  (* Criar parâmetros de filtro *)
  let filter_params = { status; origin } in
  
  (* EXTRAÇÃO (E) *)
  Printf.printf "Extraindo dados...\n";
  let orders_rows = read_orders orders_file in
  let order_items_rows = read_order_items order_items_file in
  
  (* Conversão para records *)
  Printf.printf "Convertendo dados para formato interno...\n";
  let orders = csv_to_orders orders_rows in
  let order_items = csv_to_order_items order_items_rows in
  
  (* TRANSFORMAÇÃO (T) - Parte 1: Filtragem *)
  Printf.printf "Aplicando filtros...\n";
  let filtered_orders = filter_by_params orders filter_params in
  Printf.printf "Após filtragem: %d pedidos\n" (List.length filtered_orders);
  
  (* TRANSFORMAÇÃO (T) - Parte 2: Cálculos *)
  Printf.printf "Calculando totais...\n";
  let summaries = orders_to_summaries filtered_orders order_items in
  
  (* CARGA (L) - Parte 1: Salvar em arquivo CSV *)
  Printf.printf "Salvando resultados em CSV: %s\n" output_file;
  write_summaries output_file summaries;
  
  (* CARGA (L) - Parte 2: Salvar em banco de dados SQLite (se especificado) *)
  (match db_file with
   | Some file -> 
       Printf.printf "Salvando resultados em banco de dados SQLite: %s\n" file;
       let saved_count = save_summaries_to_db file summaries in
       Printf.printf "Salvos %d registros no banco de dados SQLite\n" saved_count
   | None -> 
       Printf.printf "Nenhum banco de dados SQLite especificado, pulando...\n");
  
  (* Retornar o número de registros processados *)
  List.length summaries