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

module Print_Each (H : Digestif.S) :
  Hashette_lib.Record.T with type t = unit and type h = H.t = struct
  type t = unit
  type h = H.t

  let record () h f = print_endline @@ Printf.sprintf "%s %s" f (H.to_hex h)
  let create () = ()
end

let hash (module H : Digestif.S) (each : bool) file =
  let module R =
    (val (if each then (module Print_Each (H)) else (module Hashette_lib.Record.None (H))
          : (module Hashette_lib.Record.T with type t = unit and type h = H.t)))
  in
  let module Hashette = Hashette_lib.Make (H) (R) in
  let h = Hashette.hash_path () file in
  if not each then print_endline @@ Hashette.to_hex_lowercase h
;;

let group (module H : Digestif.S) file =
  let module R = Hashette_lib.Record.Make (H) in
  let module Hashette = Hashette_lib.Make (H) (R) in
  let record = R.create () in
  let _ = Hashette.hash_path record file in
  print_record record
;;

let file_or_dir_arg_type =
  Core.Command.Arg_type.create (fun f ->
    match Filesystem.path_as_file f with
    | Some f -> f
    | None -> failwith "Not an existing file")
;;

let hash_algorithm_arg_type =
  let algorithm_to_module : (string * (module Digestif.S)) list =
    [ "blake2b", (module Digestif.BLAKE2B)
    ; "blake2s", (module Digestif.BLAKE2S)
    ; "md5", (module Digestif.MD5)
    ; "sha1", (module Digestif.SHA1)
    ; "sha256", (module Digestif.SHA256)
    ; "sha512", (module Digestif.SHA512)
    ]
  in
  Core.Command.Arg_type.of_alist_exn algorithm_to_module
;;

let flag = Core.Command.Param.flag ~full_flag_required:()

let algorithm_param =
  flag
    "--algorithm"
    ~aliases:[ "-a" ]
    ~doc:"algorithm Hash algorithm to use"
    (Core.Command.Param.optional_with_default
       (module Digestif.SHA256 : Digestif.S)
       hash_algorithm_arg_type)
;;

let each_param =
  flag
    "--each"
    ~aliases:[ "-e" ]
    Core.Command.Flag.no_arg
    ~doc:"When hashing a folder, also print each of its children hash"
;;

let filename_param =
  let open Core.Command.Param in
  anon ("filename" %: file_or_dir_arg_type)
;;

module Command_Let_Syntax = struct
  include Core.Command.Let_syntax

  let ( let+ ) t f = t >>| f
  let ( and+ ) a b = Core.Command.Param.map2 a b ~f:(fun a b -> a, b)
end

let hash_command =
  Core.Command.basic
    ~summary:"Hash a single file or folder"
    ~readme:(fun () ->
      "If FILENAME is a folder, the hash will recursively include its children' names \
       and content hashes.")
    (let open Command_Let_Syntax in
     let+ hash_algorithm = algorithm_param
     and+ each = each_param
     and+ file = filename_param in
     fun () -> hash hash_algorithm each file)
;;

let group_command =
  Core.Command.basic
    ~summary:"Group files and folders by hash"
    ~readme:(fun () ->
      "Intended to detect duplicated resources, prints a list of hashes followed by a \
       list of file sharing this hash. Entries are sorted by number of files sharing the \
       entry's hash.")
    (let open Command_Let_Syntax in
     let+ algorithm = algorithm_param
     and+ file = filename_param in
     fun () -> group algorithm file)
;;

let hashette =
  Command.group
    ~summary:"File hashing utility"
    [ "hash", hash_command; "group", group_command ]
;;

let () = Command_unix.run ~version:"0.0.2" hashette
