type file
type dir

type t =
  | File of file
  | Dir of dir

val path_as_file : string -> t option
val file_as_path : t -> string
val read_bytes : file -> bytes
val children : dir -> (string * t) list
