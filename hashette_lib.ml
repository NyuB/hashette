module StringMap : sig
  type key = string
  type 'a t = 'a Hashtbl.Make(String).t

  val find_opt : 'a t -> key -> 'a option
  val add : 'a t -> key -> 'a -> unit
  val replace : 'a t -> key -> 'a -> unit
  val create : int -> 'a t
end =
  Hashtbl.Make (String)

module StringSet : sig
  type elt = string
  type t = Set.Make(String).t

  val add : elt -> t -> t
  val singleton : elt -> t
end =
  Set.Make (String)

module Record = struct
  module type T = sig
    type t
    type h

    val record : t -> h -> string -> unit
    val create : unit -> t
  end

  module Make (H : Digestif.S) :
    T with type h = H.t and type t = StringSet.t StringMap.t = struct
    type t = StringSet.t StringMap.t
    type h = H.t

    let record (t : t) (h : H.t) (path : string) : unit =
      let key = H.to_hex h in
      match StringMap.find_opt t key with
      | None -> StringMap.add t key (StringSet.singleton path)
      | Some set -> StringMap.replace t key (StringSet.add path set)
    ;;

    let create () : t = StringMap.create 50
  end

  module None (Any : sig
      type t
    end) : T with type h = Any.t and type t = unit = struct
    type t = unit
    type h = Any.t

    let record () _ _ = ()
    let create () = ()
  end
end

module Make (H : Digestif.S) (R : Record.T with type h = H.t) = struct
  type h = H.t

  let to_hex_lowercase h = String.lowercase_ascii (H.to_hex h)
  let hash_single_file f : h = H.digest_bytes (Filesystem.read_bytes f)
  let compare_child_entries (a, _) (b, _) = String.compare a b

  let rec hash_path (r : R.t) (file_or_dir : Filesystem.t) : h =
    let recorded v =
      let () = R.record r v (Filesystem.file_as_path file_or_dir) in
      v
    in
    match file_or_dir with
    | File f -> recorded @@ hash_single_file f
    | Dir d ->
      Filesystem.children d
      |> List.sort compare_child_entries
      |> List.fold_left
           (fun hctx (name, f) ->
             let h_name = H.feed_string hctx name in
             hash_path r f |> H.to_raw_string |> H.feed_string h_name)
           H.empty
      |> H.get
      |> recorded
  ;;
end
