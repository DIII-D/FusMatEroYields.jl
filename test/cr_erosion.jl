
using Plots
plotly()
using FusMatEroYields
targets = [:Cr]
# projectiles = Dict(:D => 1.0)
# c_idx = Dict(p => i for (i, p) in enumerate(unique(keys(projectiles))))
# β = [1.0, 2.0, 4.0, 6.0]
# Tₑ = 10 .^ LinRange(0:0.05:3)

Y_DCr = sputtering_yield(:D, :Cr, :rustbca)
plot(Y_DCr, θ=0.0, size=(600,400))

E =10.0 #eV
θ =45.0 #deg
@show Y_DCr(E, θ)
# D->Cr  from Table 1 in Sugiyama, K., K. Schmid, and W. Jacob. "Sputtering of iron, chromium and tungsten by energetic deuterium ion bombardment." Nuclear Materials and Energy 8 (2016): 1-7.

v = [0.06,2.92e-3,1.08e-3,
0.1, 6.46e-3, 9.56e-3,
0.2, 0.0435,0.0297 ,
0.3,  0.0546,0.0373 ,
0.5,  0.0422,0.0549 ,
0.7 , 0.0381,0.0626 ,
1.0 , 0.0466,0.0680,
1.5 , 0.0538,0.0689,
2.0 , 0.0489, 0.0584]


E_exp = v[1:3:end]* 1000
Y_DCr_exp_WL = v[2:3:end]
Y_DCr_exp_RBS = v[3:3:end]
scatter!(E_exp, Y_DCr_exp_WL)
scatter!(E_exp, Y_DCr_exp_RBS)