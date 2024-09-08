package nyub.hashette

trait AssertExtensions extends munit.Assertions:
    extension [A](a: A)
        infix def `is equal to`(other: A): Unit = assertEquals(a, other)
        infix def `is not equal to`(other: A): Unit = assertNotEquals(a, other)
