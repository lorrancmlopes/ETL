open Types

(** Functions for SQLite database operations *)

(** Initializes the SQLite database by creating the necessary table.
    @param db_file Path to the database file
    @return True if initialization is successful
*)
let init_db db_file =
  let db = Sqlite3.db_open db_file in
  
  let create_table_sql = "
    CREATE TABLE IF NOT EXISTS order_summaries (
      order_id INTEGER PRIMARY KEY,
      total_amount REAL NOT NULL,
      total_taxes REAL NOT NULL
    );
  " in
  
  let rc = Sqlite3.exec db create_table_sql in
  
  match rc with
  | Sqlite3.Rc.OK -> 
      Printf.printf "Table created successfully\n";
      Sqlite3.db_close db |> ignore;
      true
  | _ -> 
      Printf.eprintf "Error creating table: %s\n" (Sqlite3.errmsg db);
      Sqlite3.db_close db |> ignore;
      false

(** Inserts an order summary into the database.
    @param db Database connection
    @param summary Order summary to be inserted
    @return True if the insertion is successful
*)
let insert_summary db summary =
  let stmt = Sqlite3.prepare db "
    INSERT OR REPLACE INTO order_summaries (order_id, total_amount, total_taxes)
    VALUES (?, ?, ?);
  " in
  
  Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int summary.order_id)) |> ignore;
  Sqlite3.bind stmt 2 (Sqlite3.Data.FLOAT summary.total_amount) |> ignore;
  Sqlite3.bind stmt 3 (Sqlite3.Data.FLOAT summary.total_taxes) |> ignore;
  
  let rc = Sqlite3.step stmt in
  Sqlite3.finalize stmt |> ignore;
  
  match rc with
  | Sqlite3.Rc.DONE -> true
  | _ -> 
      Printf.eprintf "Error inserting summary: %s\n" (Sqlite3.errmsg db);
      false

(** Saves a list of order summaries to the SQLite database.
    @param db_file Path to the database file
    @param summaries List of order summaries to be saved
    @return Number of summaries saved successfully
*)
let save_summaries_to_db db_file summaries =
  if not (init_db db_file) then 
    0
  else
    let db = Sqlite3.db_open db_file in
    
    (* Transaction for better performance with multiple inserts *)
    Sqlite3.exec db "BEGIN TRANSACTION;" |> ignore;
    
    let success_count = List.fold_left (fun count summary ->
      if insert_summary db summary then
        count + 1
      else
        count
    ) 0 summaries in
    
    Sqlite3.exec db "COMMIT;" |> ignore;
    Sqlite3.db_close db |> ignore;
    
    success_count