module FileSystem : sig
  type file
  type dir

  type t =
    | File of file
    | Dir of dir

  val path_as_file : string -> t option
  val file_as_path : t -> string
  val read_bytes : file -> bytes
  val children : dir -> (string * t) list
end = struct
  type file = string
  type dir = string

  type t =
    | File of file
    | Dir of dir

  let path_as_file path =
    if not @@ Sys.file_exists path
    then None
    else if Sys.is_directory path
    then Some (Dir path)
    else if Sys.is_regular_file path
    then Some (File path)
    else None
  ;;

  let file_as_path = function
    | File p | Dir p -> p
  ;;

  let children dir =
    Sys.readdir dir
    |> Array.to_list
    |> List.filter_map (fun name ->
      path_as_file @@ dir ^ Filename.dir_sep ^ name |> Option.map (fun full -> name, full))
  ;;

  let read_bytes (file : file) =
    let ic = open_in_bin file in
    try
      let buffer = Bytes.make 255 '\000' in
      let res = ref Bytes.empty in
      let over = ref false in
      while not !over do
        let read = input ic buffer 0 255 in
        res := Bytes.cat !res @@ Bytes.sub buffer 0 read;
        if read = 0 then over := true
      done;
      !res
    with
    | err ->
      close_in ic;
      raise err
  ;;
end

open FileSystem

let compare_child_entries (a, _) (b, _) = String.compare a b

module StringMap = Hashtbl.Make (String)
module StringSet = Set.Make (String)

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

module Hashette (H : Digestif.S) (R : Record.T with type h = H.t) = struct
  type h = H.t

  let _to_hex_uppercase h = String.uppercase_ascii (H.to_hex h)
  let to_hex_lowercase h = String.lowercase_ascii (H.to_hex h)
  let hash_single_file f : h = H.digest_bytes (FileSystem.read_bytes f)

  let rec hash_path (r : R.t) (file_or_dir : FileSystem.t) : h =
    let recorded v =
      let () = R.record r v (file_as_path file_or_dir) in
      v
    in
    match file_or_dir with
    | File f -> recorded @@ hash_single_file f
    | Dir d ->
      children d
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

let print_record_entry (h, paths) =
  print_endline (Printf.sprintf "%s" h);
  StringSet.to_seq paths |> Seq.iter (fun s -> print_endline @@ Printf.sprintf "    %s" s)
;;

let size_desc_then_string (ha, sa) (hb, sb) =
  let ic = Int.compare (StringSet.cardinal sb) (StringSet.cardinal sa) in
  if ic = 0 then String.compare ha hb else ic
;;

let sorted_in_place by arr =
  let () = Array.sort by arr in
  arr
;;

let print_record record =
  record
  |> StringMap.to_seq
  |> Array.of_seq
  |> sorted_in_place size_desc_then_string
  |> Array.iter print_record_entry
;;

let hash file =
  let module R = Record.None (Digestif.SHA256) in
  let module H = Hashette (Digestif.SHA256) (R) in
  let h = H.hash_path () file in
  print_endline @@ H.to_hex_lowercase h
;;

let group file =
  let module R = Record.Make (Digestif.SHA256) in
  let module H = Hashette (Digestif.SHA256) (R) in
  let record = R.create () in
  let _ = H.hash_path record file in
  print_record record
;;

let () =
  let command = Sys.argv.(1) in
  let file_path = Sys.argv.(2) in
  let file =
    match FileSystem.path_as_file file_path with
    | None -> failwith @@ Printf.sprintf "File %s does not exist" file_path
    | Some f -> f
  in
  match command with
  | "hash" -> hash file
  | "group" -> group file
  | any -> print_endline @@ Printf.sprintf "Unknown command %s" any
;;
