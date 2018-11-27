module Grably
  # Multi project support for grably builds.
  #
  # Projects are used to communicate between logical build modules and provide
  # needed artifacts to each other. Each project tree has top level project
  # which orchestrates all builds inside project tree. Here we will introduce
  # some definitions for later use.
  # "project tree" - is set of projects with common root
  # "top-level project" - is common root of project tree
  # "exports" - is all exposed artifacts with symbolic name to fetch them.
  #   Exports are used in terms of internal project dependencies, i.e. user can
  #   export only tasks and their combinations.
  # "dependencies" - set of artifacts needed for build. We expect only two types
  #   of dependencies: inner (exported) dependencies and outer dependencies.
  #   Outer dependencies are meant to be third party libraries or other
  #   artifacts build and managed by other tool or build by internal grably
  #   resolvers. Libraries fetched from maven repository is good example for
  #   that case.
  module Project
    # Describes project model. Every project may have exports, dependencies, and
    # name.
    # Name is usualy optional and can be easily guessed by folder name where
    # project resides.
    # Exports are list of exported tasks (or task combinations) bound to
    # symbolic name. Each export receives maven-like coordinates to reference it
    # in any other grably build. Coordinate consists of three parts joined with
    # ':': prject name, export name, profile name, e.g. for project
    # 'hello-world' and export named 'jar' with profile 'release' export
    # coordinates will be 'hello-world:jar:release'. Unlike tasks exports does
    # not have any defaults, i.e. there is no 'default' export and you should
    # explicitly define each export you will use. Though there always is default
    # profile for each export which fallbacks to 'default' if no profile
    # provided.
    class Model
      attr_reader :exports, :dependencies, :name
    end
  end
end
