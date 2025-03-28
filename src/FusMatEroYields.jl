module FusMatEroYields

using FileIO
using Dates
using FusionSpecies
using Dierckx
using Interpolations
import FusionSpecies: dic_expo
using RecipesBase
using Format
using PyCall
include("yields.jl")
include("database/behrisch.jl")
include("database/rustbca.jl")
include("database.jl")
include("plot_recipes.jl")
include("io.jl")

export sputtering_yield
export get_yields_database, load_yields_database!
export make_yields_database!

end

