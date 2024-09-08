import mill._, scalalib._

object Versions {
    val scala = "3.5.0"
    val munit = "1.0.0"
}

trait SharedConfiguration extends ScalaModule {
    override def scalaVersion: T[String] = Versions.scala
    override def scalacOptions: T[Seq[String]] =
        Seq(
          "-deprecation",
          "-Werror",
          "-Wimplausible-patterns",
          "-Wnonunit-statement",
          "-WunstableInlineAccessors",
          "-Wunused:all",
          "-Wvalue-discard"
        )

    trait Tests extends ScalaTests with TestModule.Munit {
        override def ivyDeps = super.ivyDeps() ++ Agg(
          ivy"org.scalameta::munit:${Versions.munit}"
        )

    }

}

object hashette extends ScalaModule with SharedConfiguration {
    object test extends Tests
    object app extends ScalaModule with SharedConfiguration {
        override def moduleDeps = Seq(hashette)
        def cpJar = T {
            val dest = millSourcePath / os.up / os.up / "hashette.jar"
            os.copy(
              assembly().path,
              dest,
              replaceExisting = true
            )
            PathRef(dest)
        }

    }

}
