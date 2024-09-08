package nyub.hashette

import nyub.hashette.Hashette.Hash
import java.nio.file.Path
import java.nio.file.Paths
import nyub.hashette.Hashette.Method
import nyub.hashette.Hashette.NoCache
import nyub.hashette.Hashette.NoListener

class HashetteSuite extends munit.FunSuite with AssertExtensions:
    private val aFile = Paths.get("hashette/test/resources/a.txt")
    private val (someFolder, someFolderCopy) =
        (Paths.get("hashette/test/resources/folder_a"), Paths.get("hashette/test/resources/folder_a_copy"))

    private val (trickyFolder, trickyFile) =
        (Paths.get("hashette/test/resources/tricky_folder"), Paths.get("hashette/test/resources/tricky.txt"))

    test("Single file (SHA256)"):
        Hashette(Method.SHA_256, NoCache, NoListener)
            .hashPath(aFile)
            .toHex `is equal to` "cb1ad2119d8fafb69566510ee712661f9f14b83385006ef92aec47f523a38358"

    test("Single file (SHA1)"):
        Hashette(Method.SHA_1, NoCache, NoListener)
            .hashPath(aFile)
            .toHex `is equal to` "606ec6e9bd8a8ff2ad14e5fade3f264471e82251"

    test("Single file (MD5)"):
        Hashette(Method.MD_5, NoCache, NoListener)
            .hashPath(aFile)
            .toHex `is equal to` "e1faffb3e614e6c2fba74296962386b7"

    test("Folders with the same contents have the same hash"):
        Hashette.Method.values.foreach: method =>
            val hashette = Hashette(method, NoCache, NoListener)
            hashette.hashPath(someFolder) `is equal to` hashette.hashPath(someFolderCopy)

    test("Folders' children names are treated differently from their content"):
        Hashette.Method.values.foreach: method =>
            val hashette = Hashette(method, NoCache, NoListener)
            hashette.hashPath(trickyFile) `is not equal to` hashette.hashPath(
              trickyFolder
            )

    test("hashPaths uses cache when present"):
        val pathToHash = Paths.get("hashette/test/resources/folder_a")
        Hashette.Method.values.foreach: method =>
            val spy = HashSpy()
            val cache = ReadOnlyCache(Map(pathToHash -> Hashette.fromHex("AA")))
            val hashette = Hashette(method, cache, spy)
            hashette.hashPath(pathToHash) `is equal to` Hashette
                .fromHex("AA")
            spy.called `is equal to` 0

    test("hashPaths computes hashes when cached hash is missing"):
        val pathToHash = Paths.get("hashette/test/resources/folder_a")
        Hashette.Method.values.foreach: method =>
            val spy = HashSpy()
            val cache = ReadOnlyCache(Map.empty)
            val hashette = Hashette(method, cache, spy)
            val hashetteRaw = Hashette(method, NoCache, NoListener)
            hashette.hashPath(pathToHash) `is equal to` hashetteRaw.hashPath(pathToHash)
            spy.called `is equal to` 3

    private class HashSpy extends Hashette.Listener:
        def called = _called
        private var _called = 0
        override def send(p: Path, h: Hash): Unit =
            _called += 1

    private class ReadOnlyCache(val map: Map[Path, Hashette.Hash]) extends Hashette.Cache:
        override def get(p: Path): Option[Hash] = map.get(p)
        override def put(p: Path, h: Hash): Unit = ()

end HashetteSuite
