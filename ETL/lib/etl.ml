open Reader
open Helper
open Transform
open Writer
open Db 

(** Executa o processo ETL com join
    @param orders_file Arquivo CSV de pedidos
    @param order_items_file Arquivo CSV de itens de pedidos
    @param output_file Arquivo CSV de saída
    @param status Filtro opcional de status
    @param origin Filtro opcional de origem
    @param db_file Arquivo opcional do banco de dados
    @return Número de resumos processados
*)
let run_etl ~orders_file ~order_items_file ~output_file ?status ?origin ?db_file () =
    (* Ler os arquivos CSV *)
    let orders_csv = read_orders orders_file in
    let order_items_csv = read_order_items order_items_file in
    
    (* Converter CSV para tipos apropriados *)
    let orders = csv_to_orders orders_csv in
    let order_items = csv_to_order_items order_items_csv in
    
    (* Realizar a transformação *)
    let summaries = transform_with_join ~orders ~order_items ?status ?origin () in
    
    (* Salvar no arquivo CSV *)
    write_summaries output_file summaries;
    
    (* Se um arquivo de banco de dados foi especificado, salvar nele também *)
    match db_file with
    | Some db -> 
        let count = save_summaries_to_db db summaries in
        Printf.printf "Salvos %d resumos no banco de dados\n" count;
        List.length summaries  (* Retornar o número de resumos processados *)
    | None -> List.length summaries  (* Retornar o número de resumos processados *)