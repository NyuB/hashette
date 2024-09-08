package nyub.hashette

import java.nio.file.Path
import java.security.MessageDigest
import java.nio.file.Files
import scala.collection.immutable.ArraySeq
import java.util.HexFormat
import nyub.hashette.Hashette.Hash

class Hashette(
    private val method: Hashette.Method,
    private val cache: Hashette.Cache,
    private val listener: Hashette.Listener
):
    def hashPath(path: Path): Hash = Hashette.hashPath(path, method, cache, listener)
    def hashString(s: String): Hash =
        Hashette.hashString(s, method)

object Hashette:
    opaque type Hash = ByteWrap
    extension (h: Hash) def toHex: String = hexFormat.formatHex(h.bytes.toArray)
    def fromHex(hex: String): Hash = hexFormat.parseHex(hex).wrapped

    trait Cache:
        def get(p: Path): Option[Hash]
        def put(p: Path, h: Hash): Unit

    object NoCache extends Cache:
        override def get(p: Path): Option[Hash] = None
        override def put(p: Path, h: Hash): Unit = ()

    trait Listener:
        def send(p: Path, h: Hash): Unit

    object NoListener extends Listener:
        override def send(p: Path, h: Hash): Unit = ()

    private case class ByteWrap(val bytes: Seq[Byte]):
        override def toString(): String =
            hexFormat.formatHex(bytes.toArray)

    enum Method(private[Hashette] val id: String):
        case SHA_1 extends Method("SHA-1")
        case SHA_256 extends Method("SHA-256")
        case MD_5 extends Method("MD5")
        def initMd: MessageDigest = MessageDigest.getInstance(id)

    private def hashPath(path: Path, method: Method, cache: Cache, listener: Listener): Hash =
        cache
            .get(path)
            .getOrElse:
                val res =
                    if path.toFile().isFile() then hashSingleFile(path, method)
                    else if path.toFile().isDirectory() then
                        val md = method.initMd
                        path.toFile()
                            .listFiles()
                            .sortBy(_.getName())
                            .foreach: f =>
                                md.update(f.getName().getBytes())
                                md.update(hashPath(f.toPath(), method, cache, listener).bytes.toArray)
                        md.digest().wrapped
                    else throw IllegalArgumentException(s"$path is not a file or directory")
                cache.put(path, res)
                listener.send(path, res)
                res

    private def hashString(s: String, method: Method): Hash = method.initMd.digest(s.getBytes()).wrapped

    extension (bytes: Array[Byte]) private def wrapped = ByteWrap(ArraySeq.unsafeWrapArray(bytes))
    private def hashSingleFile(path: Path, method: Method): Hash =
        method.initMd.digest(Files.readAllBytes(path)).wrapped

    private val hexFormat = HexFormat.of()

end Hashette
