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

let file_or_dir_arg_type =
  Core.Command.Arg_type.create (fun f ->
    match Filesystem.path_as_file f with
    | Some f -> f
    | None -> failwith "Not an existing file")
;;

let hash_method_arg_type =
  let method_to_modules : (string * (module Digestif.S)) list =
    [ "blake2b", (module Digestif.BLAKE2B)
    ; "blake2s", (module Digestif.BLAKE2S)
    ; "md5", (module Digestif.MD5)
    ; "sha1", (module Digestif.SHA1)
    ; "sha256", (module Digestif.SHA256)
    ; "sha512", (module Digestif.SHA512)
    ]
  in
  Core.Command.Arg_type.of_alist_exn method_to_modules
;;

let sub_command_arg_type =
  Core.Command.Arg_type.of_alist_exn @@ List.map (fun a -> a, a) [ "hash"; "group" ]
;;

let flag = Core.Command.Param.flag ~full_flag_required:()

let method_param =
  flag
    "--method"
    ~aliases:[ "-m" ]
    ~doc:"algorithm Hash algorithm to use"
    (Core.Command.Param.optional_with_default
       (module Digestif.SHA256 : Digestif.S)
       hash_method_arg_type)
;;

let filename_param =
  let open Core.Command.Param in
  anon ("filename" %: file_or_dir_arg_type)
;;

let sub_command_param =
  let open Core.Command.Param in
  anon ("sub-command" %: sub_command_arg_type)
;;

module Command_Let_Syntax = struct
  include Core.Command.Let_syntax

  let ( let+ ) t f = t >>| f
  let ( and+ ) a b = Core.Command.Param.map2 a b ~f:(fun a b -> a, b)
end

let hashette =
  let open Command_Let_Syntax in
  let+ hash_method = method_param
  and+ command = sub_command_param
  and+ file = filename_param in
  fun () ->
    match command with
    | "hash" -> hash hash_method file
    | "group" -> group hash_method file
    | any -> print_endline @@ Printf.sprintf "Unknown command %s" any
;;

let () =
  let command =
    let open Core in
    Command.basic
      ~summary:"Hash files or folders"
      ~readme:(fun () ->
        "SUB-COMMAND:\n\
         \thash: hash a single file or folder\n\
         \tgroup: group files or folders having the same hash")
      hashette
  in
  Command_unix.run ~version:"0.0.2" command
;;
