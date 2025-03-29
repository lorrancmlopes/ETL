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
