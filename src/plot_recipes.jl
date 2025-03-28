
width = 10
get_label(data::T) where {T<:BehrischAngularSputteringYieldData} = "$(data.projectile) → $(data.target) | E_0 = $(data.E0) eV [Behrisch]"
get_label(sp::T, θ::Float64) where {T<:Yield{<:BehrischAngularSputteringYields,<:Any}} = "$(sp.projectile) → $(sp.target) | θ = $(format(θ,;precision=0)) deg [Behrisch]"
get_label(sp::T, θ::Float64) where {T<:Yield{<:BehrischNormalIncidenceSputteringYieldData,<:Any}} = "$(sp.projectile) → $(sp.target) [Behrisch normal]"
get_label(sp::T, θ::Float64) where {T<:Yield{Sputtering,<:RustBCAYieldData,<:Any}} = "Y_sputt $(sp.projectile) → $(sp.target) | θ = $(format(θ,;precision=0)) deg [rustbca]"
# get_label(sp::IntegratedYield{T,D,V}, θ::Float64) where {T<:Yield{Sputtering,<:RustBCAYieldData,<:Any},D,V} = "∫Y_sputt(E,θ)dE $(get_pt(sp)) | θ = $(format(θ,;precision=0)) deg [rustbca:$(basename(sp.yield.data.label))]"

# @recipe function f(data::T; θ=collect(range(0.0, 80.0, 9))) where {T<:BehrischAngularSputteringYield}
#     seriestype := :path
#     linestyle := :solid
#     label := get_label(data)
#     linewidth := 2.0
#     xlabel := "θ [deg]"
#     ylabel := "Sputtering yield"
#     θ = collect(LinRange(0, 90, 100))
#     θ, Y_angular_Eckstein(data, θ)
# end

@recipe function f(sp::T; θ=collect(range(0.0, 80.0, 9)), Y_min=1e-8) where {T<:Yield}
    E = get_E(sp)
    if θ isa Float64
        θ = [θ]
    end
    for θ_ in θ
        @series begin
            seriestype := :path
            linestyle --> :solid
            label := get_label(sp, θ_)
            yscale --> :log10
            xscale --> :log10
            linewidth := 2.0
            xlabel := "E [eV]"
            ylim := [1e-5, 1]
            ylabel := "Sputtering yield"
            E, sp.(E, θ_ .+ 0 .* E) .+ Y_min
        end
    end
end

# @recipe function f(sp::IntegratedYield{Y,D,V}; θ=collect(range(0.0, 80.0, 9)), Y_min=1e-8) where {Y,D<:AcceleratedMaxwellianEnergyDistribution,V}
#     E = get_E(sp)
#     if θ isa Float64
#         θ = [θ]
#     end
#     for θ_ in θ
#         @series begin
#             seriestype := :path
#             linestyle --> :solid
#             label := get_label(sp, θ_)
#             yscale --> :log10
#             xscale --> :log10
#             linewidth := 2.0
#             xlabel := "Te [eV]"
#             ylim --> [1e-6, 1]
#             ylabel := "<Y>"
#             E, sp.(E, θ_ .+ 0 .* E) .+ Y_min
#         end
#     end
# end


# @recipe function g(f::AbstractDistribution)
#     seriestype := :path
#     linestyle := :solid
#     label --> get_label(f)
#     linewidth := 2.0
#     xlabel := "E [eV]"
#     ylabel := "PDF"
#     f.f.E, f.f.f
# end



plot_Y(data) = plot.([v for v in values(data)])

