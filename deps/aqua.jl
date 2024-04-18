push!(LOAD_PATH, ".")

using Aqua
using MCGraphs
Aqua.test_ambiguities([MCGraphs])
Aqua.test_all(MCGraphs; ambiguities = false, unbound_args = false, deps_compat = false, persistent_tasks = false)
