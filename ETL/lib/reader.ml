(** Reads a CSV file from disk
    @param filename Path to the CSV file
    @return List of CSV rows
*)
let read_csv_file filename =
  try
    let channel = open_in filename in
    let csv = Csv.of_channel ~has_header:true channel in
    let rows = Csv.input_all csv in
    close_in channel;
    rows
  with
  | Sys_error msg -> 
      Printf.eprintf "Error opening file %s: %s\n" filename msg;
      []
  | e -> 
      Printf.eprintf "Error processing file %s: %s\n" 
        filename (Printexc.to_string e);
      []

(** Downloads content from a URL
    @param url The URL to download from
    @return Some content if successful, None otherwise
*)
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
    Printf.eprintf "Error downloading URL %s: HTTP code %d\n" url code;
    None
  end

(** Parses CSV from a string
    @param str String containing CSV data
    @return List of CSV rows
*)
let read_csv_from_string str =
  try
    let input = Csv.of_string ~has_header:true str in
    Csv.input_all input
  with e ->
    Printf.eprintf "Error processing CSV from string: %s\n" 
      (Printexc.to_string e);
    []

(** Reads CSV data from a URL
    @param url URL pointing to CSV data
    @return List of CSV rows
*)
let read_csv_from_url url =
  match download_url url with
  | None -> []
  | Some content -> read_csv_from_string content

(** Reads CSV from either a file path or a URL
    @param source File path or URL to read from
    @return List of CSV rows
*)
let read_csv_file_or_url source =
  if String.length source >= 7 && 
      (String.sub source 0 7 = "http://" || 
      String.sub source 0 8 = "https://") then
    read_csv_from_url source
  else
    read_csv_file source

(** Reads orders from a file or URL
    @param source File path or URL containing order data
    @return List of CSV rows representing orders
*)
let read_orders = read_csv_file_or_url

(** Reads order items from a file or URL
    @param source File path or URL containing order item data
    @return List of CSV rows representing order items
*)
let read_order_items = read_csv_file_or_url
