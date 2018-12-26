assemblyOption in ThisBuild / assembly := (assemblyOption in assembly).value
  .copy(includeScala = false, includeDependency = false)

test in ThisBuild / assembly := {}
