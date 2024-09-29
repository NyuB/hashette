module StringMap = Hashtbl.Make (String)
module StringSet = Set.Make (String)

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

let hash (module H : Digestif.S) file =
  let module R = Hashette_lib.Record.None (H) in
  let module Hashette = Hashette_lib.Make (H) (R) in
  let h = Hashette.hash_path () file in
  print_endline @@ Hashette.to_hex_lowercase h
;;

let group (module H : Digestif.S) file =
  let module R = Hashette_lib.Record.Make (H) in
  let module Hashette = Hashette_lib.Make (H) (R) in
  let record = R.create () in
  let _ = Hashette.hash_path record file in
  print_record record
;;

type options = { hash_method : (module Digestif.S) }

let hash_method_of_arg arg : (module Digestif.S) option =
  match arg with
  | "--method=blake2b" -> Some (module Digestif.BLAKE2B)
  | "--method=blake2s" -> Some (module Digestif.BLAKE2S)
  | "--method=md5" -> Some (module Digestif.MD5)
  | "--method=sha1" -> Some (module Digestif.SHA1)
  | "--method=sha256" -> Some (module Digestif.SHA256)
  | "--method=sha512" -> Some (module Digestif.SHA512)
  | _ -> None
;;

let parse_args args =
  let rec aux acc opts = function
    | [] -> List.rev acc |> Array.of_list, opts
    | arg :: t when String.starts_with ~prefix:"--method=" arg ->
      (match hash_method_of_arg arg with
       | Some hash_method -> aux acc { hash_method } t
       | None -> aux (arg :: acc) opts t)
    | arg :: t -> aux (arg :: acc) opts t
  in
  aux [] { hash_method = (module Digestif.SHA256) } (Array.to_list args)
;;

let () =
  let args, options = parse_args Sys.argv in
  let command = args.(1)
  and file_path = args.(2) in
  let file =
    match Filesystem.path_as_file file_path with
    | None -> failwith @@ Printf.sprintf "File %s does not exist" file_path
    | Some f -> f
  in
  match command with
  | "hash" -> hash options.hash_method file
  | "group" -> group options.hash_method file
  | any -> print_endline @@ Printf.sprintf "Unknown command %s" any
;;
