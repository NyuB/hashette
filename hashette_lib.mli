module StringMap : sig
  type key = string
  type 'a t = 'a Hashtbl.Make(String).t
end

module StringSet : sig
  type elt = string
  type t = Set.Make(String).t
end

module Record : sig
  module type T = sig
    type t
    type h

    val record : t -> h -> string -> unit
    val create : unit -> t
  end

  module Make : functor (H : Digestif.S) -> sig
    type t = StringSet.t StringMap.t
    type h = H.t

    val record : t -> h -> string -> unit
    val create : unit -> t
  end

  module None : functor
      (Any : sig
         type t
       end)
      -> sig
    type t = unit
    type h = Any.t

    val record : t -> h -> string -> unit
    val create : unit -> t
  end
end

module Make : functor
    (H : Digestif.S)
    (R : sig
       type t
       type h = H.t

       val record : t -> h -> string -> unit
       val create : unit -> t
     end)
    -> sig
  type h = H.t

  val to_hex_lowercase : H.t -> string
  val hash_path : R.t -> Filesystem.t -> h
end
