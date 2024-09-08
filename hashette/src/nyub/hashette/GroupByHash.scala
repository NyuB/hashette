package nyub.hashette

import java.nio.file.Path
import nyub.hashette.Hashette.Hash

class GroupByHash() extends Hashette.Listener:
    def groups = map.toMap
    private val map = scala.collection.concurrent.TrieMap[Hashette.Hash, Set[Path]]()
    override def send(p: Path, h: Hash): Unit =
        val _ = map.updateWith(h):
            case None          => Some(Set(p))
            case Some(already) => Some(already + p)
