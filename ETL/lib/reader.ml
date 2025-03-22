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



let download_url url =
  let result = Buffer.create 16384 in
  let curl = Curl.init () in
  Curl.set_url curl url;
  Curl.set_writefunction curl
    (fun data ->
        Buffer.add_string result data;
        String.length data);
  Curl.perform curl;
  let code = Curl.get_responsecode curl in
  Curl.cleanup curl;
  if code >= 200 && code < 300 then
    Some (Buffer.contents result)
  else begin
    Printf.eprintf "Erro ao baixar URL %s: código HTTP %d\n" url code;
    None
  end

let read_csv_from_string str =
  try
    let input = Csv.of_string ~has_header:true str in
    Csv.input_all input
  with e ->
    Printf.eprintf "Erro ao processar CSV da string: %s\n" 
      (Printexc.to_string e);
    []

let read_csv_from_url url =
  match download_url url with
  | None -> []
  | Some content -> read_csv_from_string content

let read_csv_file_or_url source =
  if String.length source >= 7 && 
      (String.sub source 0 7 = "http://" || 
      String.sub source 0 8 = "https://") then
    read_csv_from_url source
  else
    read_csv_file source

let read_orders = read_csv_file_or_url
let read_order_items = read_csv_file_or_url
