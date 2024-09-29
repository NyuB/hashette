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
