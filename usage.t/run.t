Single file
  $ hashette hash resources/a.txt
  cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358

Missing file
  $ hashette hash absent.txt
  Fatal error: exception Failure("File absent.txt does not exist")
  [2]

Folders with the same contents have the same hash
  $ hashette hash resources/folder_a
  7d72da89e2fc75cbc9c590648494982f1b883f11e3afa5ca0b93d06608ca24b8
  $ hashette hash resources/folder_a_copy
  7d72da89e2fc75cbc9c590648494982f1b883f11e3afa5ca0b93d06608ca24b8

Folders' children' names are treated differently from their content
  $ hashette hash resources/tricky.txt
  ccf8b2c1266d8799cc720aca6013ef370ee4ecd39ab7c36c2dd0f0e3cf4a75d3
  $ hashette hash resources/tricky_folder
  18c00f0264da56e2a9280636b862f4520134ed2e00af242e2add7b5376575e5b

Group files by hash
  $ hashette group resources/groups
  cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358
      resources/groups/a.txt
      resources/groups/b_with_a.txt
      resources/groups/folder_one/a.txt
      resources/groups/folder_three/a.txt
      resources/groups/folder_two/b_with_a.txt
  ce2ccf9dfaab921b0648f70777ed22303c0071598bd0052d24b9292d636ad203
      resources/groups/folder_one
      resources/groups/folder_three
  5436b40aaaf4b4b54633058af3108ca481562764ec548c95627f032998451067
      resources/groups
  93d93833fd18fae952c6d42204b23c506db5725149514ad51f8d3f7ef3ad26bd
      resources/groups/folder_two

Use various hasj methods
  $ hashette hash --method=sha256 resources
  20b831270438847a360ce6c8e8cbbc48e998ce245a06a64e1ce49275e96d22c0
  $ hashette hash --method=sha1 resources
  2729f50a7e30aff8d98607370eb2373d6c2dc8c4
  $ hashette hash --method=md5 resources
  ebd0282c666d989b31bf1384e6fa9af7
