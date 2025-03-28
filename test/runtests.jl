using FusMatEroYields
using Test

@testset "FusMatEroYields.jl" begin
    load_yields_database!(; remake_database=true)
    Y_CrCr = sputtering_yield(:Cr, :Cr, :rust_bca)
    return true
end
