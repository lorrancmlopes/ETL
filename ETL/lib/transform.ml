open Types

(* Criar um módulo Map para chaves inteiras *)
module IntMap = Map.Make(struct
  type t = int
  let compare = compare
end)

(** Tipo para representar um registro após o join entre orders e order_items *)
type joined_record = {
  order_id: int;
  status: string;
  origin: string;
  item_amount: float;
  item_tax: float;
}

(** Realiza o join entre orders e order_items
    @param orders Lista de pedidos
    @param order_items Lista de itens de pedidos
    @return Lista de registros unidos via inner join
*)
let join_orders_and_items (orders : order list) (order_items : order_item list) : joined_record list =
  (* Criar um map de order_id -> order para acesso mais eficiente *)
  let orders_map = List.fold_left (fun map order ->
    IntMap.add order.id order map
  ) IntMap.empty orders in

  (* Para cada item, encontrar o pedido correspondente e criar um joined_record *)
  List.fold_left (fun (acc : joined_record list) (item : order_item) ->
    match IntMap.find_opt item.order_id orders_map with
    | Some order -> 
        { order_id = order.id;
          status = order.status;
          origin = order.origin;
          item_amount = item.price *. float_of_int item.quantity;  (* Calcular o valor total do item *)
          item_tax = item.tax *. float_of_int item.quantity;  (* Calcular o imposto total do item *)
        } :: acc
    | None -> acc
  ) [] order_items
  |> List.rev  (* Reverter a lista para manter a ordem original *)

(** Cria um resumo de pedido a partir dos registros unidos
    @param joined_records Lista de registros do mesmo pedido após o join
    @return Resumo do pedido
*)
let create_order_summary_from_joined joined_records =
  match joined_records with
  | [] -> None
  | first :: _ ->
      let total_amount = ref 0.0 in
      let total_taxes = ref 0.0 in
      
      List.iter (fun record ->
        total_amount := !total_amount +. record.item_amount;
        total_taxes := !total_taxes +. record.item_tax;
      ) joined_records;
      
      Some {
        order_id = first.order_id;
        total_amount = !total_amount;
        total_taxes = !total_taxes;
      }

(** Transforma os dados unidos em resumos de pedidos
    @param joined_records Lista de todos os registros unidos
    @return Lista de resumos de pedidos
*)
let joined_records_to_summaries joined_records =
  (* Agrupar registros pelo order_id *)
  let grouped = List.fold_left (fun map record ->
    let current = match IntMap.find_opt record.order_id map with
      | Some records -> record :: records
      | None -> [record]
    in
    IntMap.add record.order_id current map
  ) IntMap.empty joined_records in
  
  (* Criar resumos para cada grupo *)
  IntMap.fold (fun _order_id records acc ->
    match create_order_summary_from_joined records with
    | Some summary -> summary :: acc
    | None -> acc
  ) grouped []
  |> List.rev

(** Função principal de transformação que utiliza o join
    @param orders Lista de pedidos
    @param order_items Lista de itens de pedidos
    @param status Filtro opcional de status
    @param origin Filtro opcional de origem
    @return Lista de resumos de pedidos
*)
let transform_with_join ~orders:(orders:order list) ~order_items:(order_items:order_item list) ?status ?origin () =
  let joined = join_orders_and_items orders order_items in
  
  (* Aplicar filtros nos registros unidos *)
  let filtered = joined |> List.filter (fun record ->
    (match status with
     | None -> true
     | Some s -> record.status = s)
    &&
    (match origin with
     | None -> true
     | Some o -> record.origin = o)
  ) in
  
  joined_records_to_summaries filtered