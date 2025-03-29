(** Data types used in the ETL process *)
module Types : sig
  (** Represents an order in the system *)
  type order = {
    id: int;                 (** Unique identifier for the order *)
    client_id: int;          (** Client identifier *)
    order_date: string;      (** Order date in ISO format *)
    status: string;          (** Order status: 'Complete', 'Pending' or 'Cancelled' *)
    origin: string;          (** Order origin: 'P' (physical store) or 'O' (online) *)
  }

  (** Represents an item within an order *)
  type order_item = {
    order_id: int;           (** Identifier of the order this item belongs to *)
    product_id: int;         (** Product identifier *)
    quantity: int;           (** Product quantity *)
    price: float;            (** Unit price of the product *)
    tax: float;              (** Tax rate for the product *)
  }

  (** Summary of the financial information for an order *)
  type order_summary = {
    order_id: int;           (** Identifier of the summarized order *)
    total_amount: float;     (** Total value of the order *)
    total_taxes: float;      (** Total taxes for the order *)
  }

  (** Filter parameters for order queries *)
  type filter_params = {
    status: string option;   (** Optional status filter *)
    origin: string option;   (** Optional origin filter *)
  }

  (** Financial summary grouped by period (month/year) *)
  type period_summary = {
    year: int;               (** Year of the period *)
    month: int;              (** Month of the period (1-12) *)
    avg_revenue: float;      (** Average revenue of orders in the period *)
    avg_taxes: float;        (** Average taxes of orders in the period *)
    total_orders: int;       (** Total number of orders in the period *)
  }
end

(** Helper functions for data conversion *)
module Helper : sig
  (** Converts a string to an integer
      @param s String to convert
      @return Parsed integer value
      @raise Failure if the string cannot be converted
  *)
  val string_to_int : string -> int

  (** Converts a string to a float
      @param s String to convert
      @return Parsed float value
      @raise Failure if the string cannot be converted
  *)
  val string_to_float : string -> float

  (** Converts a CSV row to an order record
      @param row CSV row as a list of strings
      @return Order record
      @raise Failure if the row has an invalid format
  *)
  val row_to_order : string list -> Types.order

  (** Converts a CSV row to an order item record
      @param row CSV row as a list of strings
      @return Order item record
      @raise Failure if the row has an invalid format
  *)
  val row_to_order_item : string list -> Types.order_item

  (** Converts a list of CSV rows to a list of orders
      @param rows List of CSV rows
      @return List of order records
  *)
  val csv_to_orders : string list list -> Types.order list

  (** Converts a list of CSV rows to a list of order items
      @param rows List of CSV rows
      @return List of order item records
  *)
  val csv_to_order_items : string list list -> Types.order_item list
end

(** Functions for filtering data *)
module Filter : sig
  (** Filters a list of orders based on the given parameters
      @param orders List of orders to filter
      @param params Filter parameters (status and origin)
      @return Filtered list of orders that match the parameters
  *)
  val filter_by_params : Types.order list -> Types.filter_params -> Types.order list
end

(** Functions for data transformation *)
module Transform : sig
  (** Type representing a record after joining orders and order_items *)
  type joined_record = {
    order_id: int;
    status: string;
    origin: string;
    item_amount: float;
    item_tax: float;
  }

  (** Performs a join operation between orders and order_items
      @param orders List of orders
      @param order_items List of order items
      @return List of records joined via inner join
  *)
  val join_orders_and_items : Types.order list -> Types.order_item list -> joined_record list

  (** Creates an order summary from joined records
      @param joined_records List of records from the same order after joining
      @return Order summary
  *)
  val create_order_summary_from_joined : joined_record list -> Types.order_summary option

  (** Main transformation function using join
      @param orders List of orders
      @param order_items List of order items
      @param status Optional status filter
      @param origin Optional origin filter
      @return List of order summaries
  *)
  val transform_with_join : 
    orders:Types.order list -> 
    order_items:Types.order_item list -> 
    ?status:string -> 
    ?origin:string -> 
    unit -> 
    Types.order_summary list

  (** Calculates summaries by period (month/year)
      @param summaries List of order summaries
      @param orders List of original orders
      @return List of period summaries
  *)
  val calculate_period_summaries : 
    Types.order_summary list -> 
    Types.order list -> 
    Types.period_summary list
end

(** Executes the ETL process with join operation
    @param orders_file CSV file containing orders
    @param order_items_file CSV file containing order items
    @param output_file Output CSV file for results
    @param period_output_file Optional CSV file for period summary output
    @param status Optional status filter
    @param origin Optional origin filter
    @param db_file Optional database file path
    @return Number of processed summaries
*)
val run_etl : 
  orders_file:string ->
  order_items_file:string ->
  output_file:string ->
  ?period_output_file:string ->
  ?status:string ->
  ?origin:string ->
  ?db_file:string ->
  unit -> int 