Help summary
  $ hashette --help
  File hashing utility
  
    hashette SUBCOMMAND
  
  === subcommands ===
  
    group                      . Group files and folders by hash
    hash                       . Hash a single file or folder
    version                    . print version information
    help                       . explain a given subcommand (perhaps recursively)
  
  $ hashette help hash
  Hash a single file or folder
  
    hashette hash FILENAME
  
  If FILENAME is a folder, the hash will recursively include its children' names and content hashes.
  
  === flags ===
  
    [--algorithm algorithm], -a
                               . Hash algorithm to use (can be: blake2b, blake2s,
                                 md5, sha1, sha256, sha512)
    [--each], -e               . When hashing a folder, also print each of its
                                 children hash
    [-help], -?                . print this help text and exit
  
  $ hashette help group
  Group files and folders by hash
  
    hashette group FILENAME
  
  Intended to detect duplicated resources, prints a list of hashes followed by a list of file sharing this hash. Entries are sorted by number of files sharing the entry's hash.
  
  === flags ===
  
    [--algorithm algorithm], -a
                               . Hash algorithm to use (can be: blake2b, blake2s,
                                 md5, sha1, sha256, sha512)
    [-help], -?                . print this help text and exit
  

Single file
  $ hashette hash resources/a.txt
  cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358

Missing file
  $ hashette hash absent.txt
  Error parsing command line:
  
    failed to parse FILENAME value "absent.txt"
    (Failure "Not an existing file")
  
  For usage information, run
  
    hashette hash -help
  
  [1]

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

Print each file hash in a folder
  $ hashette hash --each resources/groups
  resources/groups/a.txt cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358
  resources/groups/b_with_a.txt cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358
  resources/groups/folder_one/a.txt cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358
  resources/groups/folder_one ce2ccf9dfaab921b0648f70777ed22303c0071598bd0052d24b9292d636ad203
  resources/groups/folder_three/a.txt cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358
  resources/groups/folder_three ce2ccf9dfaab921b0648f70777ed22303c0071598bd0052d24b9292d636ad203
  resources/groups/folder_two/b_with_a.txt cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358
  resources/groups/folder_two 93d93833fd18fae952c6d42204b23c506db5725149514ad51f8d3f7ef3ad26bd
  resources/groups 5436b40aaaf4b4b54633058af3108ca481562764ec548c95627f032998451067

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

Use various hash algorithms
  $ hashette hash --algorithm blake2b resources
  a4d1449a6f3e844a87647543d250e776fae6a03c2a29a8f90392ef72b2433f3deff06daeb06b078e0b5d91cbf80b46852526efac5755afb45bb3026ddff840cb
  $ hashette hash --algorithm blake2s resources
  5d11f32b3579999be734f9416a31a7a8fbf76e9b9148fc9aca8e2c5b9d5b2967
  $ hashette hash --algorithm md5 resources
  ebd0282c666d989b31bf1384e6fa9af7
  $ hashette hash --algorithm sha1 resources
  2729f50a7e30aff8d98607370eb2373d6c2dc8c4
  $ hashette hash --algorithm sha256 resources
  20b831270438847a360ce6c8e8cbbc48e998ce245a06a64e1ce49275e96d22c0
  $ hashette hash --algorithm sha512 resources
  ef2671413955bcf8f7f871291bbddeaddbdba1d86a40215de674b5c67ef2424ebd1390e4a429d0e9d401cbeb3c1a8964b800324ea18505c300cb26d6daa314d0
