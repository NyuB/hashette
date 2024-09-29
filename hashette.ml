module FileSystem : sig
  type file
  type dir

  type t =
    | File of file
    | Dir of dir

  val path_as_file : string -> t option
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

module Hashette (H : Digestif.S) = struct
  type h = H.t

  let _to_hex_uppercase h = String.uppercase_ascii (H.to_hex h)
  let to_hex_lowercase h = String.lowercase_ascii (H.to_hex h)
  let hash_single_file f : h = H.digest_bytes (FileSystem.read_bytes f)

  let rec hash_path (file_or_dir : FileSystem.t) : h =
    match file_or_dir with
    | File f -> hash_single_file f
    | Dir d ->
      children d
      |> List.sort compare_child_entries
      |> List.fold_left
           (fun hctx (name, f) ->
             let h_name = H.feed_string hctx name in
             hash_path f |> H.to_raw_string |> H.feed_string h_name)
           H.empty
      |> H.get
  ;;
end

let () =
  let file_path = Sys.argv.(1) in
  let file =
    match FileSystem.path_as_file file_path with
    | None -> failwith @@ Printf.sprintf "File %s does not exist" file_path
    | Some f -> f
  in
  let module H = Hashette (Digestif.SHA256) in
  let h = H.hash_path file in
  print_endline @@ H.to_hex_lowercase h
;;
