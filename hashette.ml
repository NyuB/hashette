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

let hash file =
  let module R = Hashette_lib.Record.None (Digestif.SHA256) in
  let module H = Hashette_lib.Make (Digestif.SHA256) (R) in
  let h = H.hash_path () file in
  print_endline @@ H.to_hex_lowercase h
;;

let group file =
  let module R = Hashette_lib.Record.Make (Digestif.SHA256) in
  let module H = Hashette_lib.Make (Digestif.SHA256) (R) in
  let record = R.create () in
  let _ = H.hash_path record file in
  print_record record
;;

let () =
  let command = Sys.argv.(1) in
  let file_path = Sys.argv.(2) in
  let file =
    match Filesystem.path_as_file file_path with
    | None -> failwith @@ Printf.sprintf "File %s does not exist" file_path
    | Some f -> f
  in
  match command with
  | "hash" -> hash file
  | "group" -> group file
  | any -> print_endline @@ Printf.sprintf "Unknown command %s" any
;;
