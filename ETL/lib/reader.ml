(* Função para ler um arquivo CSV e retornar um array de strings *)
let read_csv_file filename =
  try
    let channel = open_in filename in
    let csv = Csv.of_channel ~has_header:true channel in
    let rows = Csv.input_all csv in
    close_in channel;
    rows
  with
  | Sys_error msg -> 
      Printf.eprintf "Erro ao abrir arquivo %s: %s\n" filename msg;
      []
  | e -> 
      Printf.eprintf "Erro ao processar arquivo %s: %s\n" 
        filename (Printexc.to_string e);
      []

(* Usando aplicação parcial para criar leitores específicos *)
let read_orders = read_csv_file
let read_order_items = read_csv_file
