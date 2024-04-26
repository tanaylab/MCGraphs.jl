using Test

using Daf.GenericFunctions
using Daf.GenericTypes
using MCGraphs
using NestedTests

test_prefixes(ARGS)
abort_on_first_failure(true)

include("validations.jl")
include("renderers.jl")
