using FusMatEroYields
using Plots
plotly()

targets = [:Cr]
# projectiles = Dict(:D => 1.0)
# c_idx = Dict(p => i for (i, p) in enumerate(unique(keys(projectiles))))
# β = [1.0, 2.0, 4.0, 6.0]
# Tₑ = 10 .^ LinRange(0:0.05:3)

Y_DCr = sputtering_yield(:D, :Cr, :rust_bca)
plot(Y_CrCr, θ=0.0, size=(600,400))

E =10.0 #eV
θ =45.0 #deg
@show Y_DCr(E, θ)
