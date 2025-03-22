type order = {
  id: int;
  client_id: int;
  order_date: string;
  status: string;
  origin: string;
}

type order_item = {
  order_id: int;
  product_id: int;
  quantity: int;
  price: float;
  tax: float;
}

type order_summary = {
  order_id: int;
  total_amount: float;
  total_taxes: float;
}

type filter_params = {
  status: string option;
  origin: string option;
}
