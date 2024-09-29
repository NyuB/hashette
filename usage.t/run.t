Single file
  $ hashette resources/a.txt
  cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358

Missing file
  $ hashette absent.txt
  Fatal error: exception Failure("File absent.txt does not exist")
  [2]

Folders with the same contents have the same hash
  $ hashette resources/folder_a
  7d72da89e2fc75cbc9c590648494982f1b883f11e3afa5ca0b93d06608ca24b8
  $ hashette resources/folder_a_copy
  7d72da89e2fc75cbc9c590648494982f1b883f11e3afa5ca0b93d06608ca24b8

Folders' children' names are treated differently from their content
  $ hashette resources/tricky.txt
  ccf8b2c1266d8799cc720aca6013ef370ee4ecd39ab7c36c2dd0f0e3cf4a75d3
  $ hashette resources/tricky_folder
  18c00f0264da56e2a9280636b862f4520134ed2e00af242e2add7b5376575e5b
