(lang dune 3.16)

(name hashette)

(generate_opam_files true)

(source
 (github NyuB/hashette))

(authors "NyuB")

(maintainers "NyuB")

(license LICENSE)

(documentation https://github.com/NyuB/hashette)

(package
 (name hashette)
 (synopsis "File hashing utility")
 (description "File hashing utility")
 (depends (ocaml (>= 5.1.1)) dune digestif (ocamlformat :with-test))
 (tags ()))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
