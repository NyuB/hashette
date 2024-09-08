package nyub.hashette

import munit.internal.io.PlatformIO.Paths
import nyub.hashette.Hashette.NoCache
import nyub.hashette.Hashette.NoListener
import java.nio.file.Path

class GroupByHashSuite extends munit.FunSuite with AssertExtensions:
    private val method = Hashette.Method.SHA_256

    test("group same files"):
        val hashA = hash(Paths.get("hashette/test/resources/a.txt"))
        val groupByHash = GroupByHash()
        val _ = Hashette(method, NoCache, groupByHash).hashPath(Paths.get("hashette/test/resources/groups"))
        groupByHash.groups(hashA) `is equal to` Set(
          "hashette/test/resources/groups/a.txt",
          "hashette/test/resources/groups/b_with_a.txt",
          "hashette/test/resources/groups/folder_one/a.txt",
          "hashette/test/resources/groups/folder_two/b_with_a.txt",
          "hashette/test/resources/groups/folder_three/a.txt"
        ).map(Paths.get(_))

    test("group same folders with same files AND same names"):
        val hashFolderOne = hash(Paths.get("hashette/test/resources/groups/folder_one"))
        val hashFolderTwo = hash(Paths.get("hashette/test/resources/groups/folder_two"))
        val groupByHash = GroupByHash()
        val _ = Hashette(method, NoCache, groupByHash).hashPath(Paths.get("hashette/test/resources/groups"))
        groupByHash.groups(hashFolderOne) `is equal to` Set(
          "hashette/test/resources/groups/folder_one",
          "hashette/test/resources/groups/folder_three"
        ).map(Paths.get(_))
        groupByHash.groups(hashFolderTwo) `is equal to` Set(
          "hashette/test/resources/groups/folder_two"
        ).map(Paths.get(_))

    private def hash(path: Path) = Hashette(method, NoCache, NoListener).hashPath(path)

end GroupByHashSuite
