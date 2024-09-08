package nyub.hashette.app

import java.nio.file.Path
import nyub.hashette.GroupByHash
import nyub.hashette.Hashette
import nyub.hashette.Hashette.Method
import nyub.hashette.Hashette.NoCache
import java.nio.file.Paths
import nyub.hashette.Hashette.NoListener

type ExitCode = Int
val OK: ExitCode = 0
val KO: ExitCode = 1
type Args = Seq[String]
trait Command:
    def parse(args: Args): (Command, Args)
    final def parseAll(args: Args): Command =
        if args.isEmpty then this
        else
            val (cmd, rest) = parse(args)
            if rest.size == args.size then throw IllegalStateException("Infinite arg parsing")
            cmd.parseAll(rest)

    def run: ExitCode

class App(method: Option[Method] = None) extends Command:
    override def parse(args: Args): (Command, Args) =
        args match
            case "help" :: Nil             => Help(false) -> Seq.empty
            case "group" :: rest           => Group(Seq.empty, method.getOrElse(Method.SHA_1)) -> rest
            case "hash" :: rest            => Hash(Seq.empty, method.getOrElse(Method.SHA_1)) -> rest
            case "--method=sha1" :: rest   => App(method = Some(Method.SHA_1)) -> rest
            case "--method=sha256" :: rest => App(method = Some(Method.SHA_256)) -> rest
            case "--method=md5" :: rest    => App(method = Some(Method.MD_5)) -> rest
            case _                         => Help(true) -> Seq.empty

    override def run: ExitCode = Help(true).run

case class Group(private val paths: Seq[Path], private val method: Method) extends Command:
    override def parse(args: Args): (Command, Args) =
        if args.isEmpty then this -> Seq.empty
        else
            val path = Paths.get(args(0))
            copy(paths = paths :+ path) -> args.tail

    override def run: ExitCode =
        val groupByHash = GroupByHash()
        val hashette = Hashette(method, NoCache, groupByHash)
        paths.foreach(hashette.hashPath(_))
        groupByHash.groups.toList
            .sortWith((a, b) => a._2.size > b._2.size)
            .foreach: (h, paths) =>
                println(s"$h {")
                paths.foreach(p => println(s"\t$p"))
                println("}")
        OK

case class Hash(private val paths: Seq[Path], private val method: Method, private val each: Boolean = false)
    extends Command:
    override def parse(args: Args): (Command, Args) =
        args match
            case Nil              => this -> Seq.empty
            case "--each" :: rest => copy(each = true) -> rest
            case "--help" :: rest => Help(false) -> rest
            case arg :: rest      => copy(paths = paths :+ Paths.get(arg)) -> rest

    override def run: ExitCode =
        val listener: Hashette.Listener =
            if each then
                new:
                    override def send(p: Path, h: Hashette.Hash) = println(s"$p => $h")
            else NoListener
        val hashette = Hashette(method, NoCache, listener)
        paths.foreach: p =>
            val h = hashette.hashPath(p)
            if each then () else println(s"$p => $h")
        OK

    class Help(private val becauseInvalid: Boolean) extends Command:
        override def parse(args: Args): (Command, Args) = Help(true) -> Seq.empty
        override def run: ExitCode =
            println("Usage: hash [paths...]")
            println("Outputs the hashes of the given files or folder")
            print("Options:")
            print("\t--each: recursively outputs each children hash if one of the given [paths...] is a folder")
            if becauseInvalid then KO else OK

class Help(val becauseInvalid: Boolean) extends Command:
    override def parse(args: Args) = Help(true) -> Seq.empty
    override def run: ExitCode =
        println("Usage: hashette <command>")
        println("Where command is one of:")
        println("\tgroup\n\thash\n\thelp")
        println("Shared options:")
        println("\t--method={sha1|sha256|md5}: the hash method to use (default is sha1)")
        if becauseInvalid then KO else OK

@main def main(args: String*): Unit =
    val code = App().parseAll(args).run
    System.exit(code)
