#=
Author: Jerome Guterl (guterlj@fusion.gat.com)
 Company: General Atomics
 sputtering_yields.jl (c) 2024=#
abstract type AbstractYield{T} end
abstract type Sputtering end 
abstract type ReflectionParticle end
abstract type ReflectionEnergy end

# SputteringYield = AbstractYield{Sputtering}
# ReflectionParticleYield = AbstractYield{ReflectionParticle}
# ReflectionEnergyYield = AbstractYield{ReflectionEnergy}

abstract type YieldData end
abstract type YieldEnergyData <: YieldData end
abstract type YieldEnergyAngleData <: YieldData end

"""
    Yield{T,D<:YieldData,V} <: AbstractYield{T}

A struct representing a yield curve for a specific projectile-target combination.

# Fields
- `projectile::Symbol`: The projectile element symbol.
- `target::Symbol`: The target element symbol.
- `data::D`: The yield data, which must be a subtype of `YieldData`.
- `interp::V`: The interpolation object used to evaluate the yield at arbitrary energies.
- `label::String`: A label for the yield curve.
- `info::Dict`: A dictionary containing additional information about the yield curve.
"""

struct Yield{T,D<:YieldData,V} <: AbstractYield{T}
    projectile::Symbol
    target::Symbol
    data::D
    interp::V
    info::Dict
end

Yield{T}(p, t, d::D, v::V, i) where {T,D,V} = Yield{T,D,V}(p,t,d,v, i)
#get_pt(Y::Yield) = "$(Y.projectile) → $(Y.target)"
get_pt(Y::Yield) = Y.projectile => Y.target
function (sp::Yield{T,D,V})(E::Float64, θ::Float64) where {T,D<:YieldEnergyAngleData,V}
    out = Dierckx.evaluate(sp.interp, E, θ)
    return out < 0 ? 0.0 : out
end

function (sp::Yield{T,D,V})(E::U, θ::U) where {T,D<:YieldEnergyAngleData,V,U<:Array}
    out = Dierckx.evaluate(sp.interp, E, θ)
    out[out.<0] .= 0.0
    return out
end
#(sp::SputteringYield{D,V})(E::T) where {D<:SputteringYieldEnergyData,V,T} = sp(E)
function (sp::Yield{T,D,V})(E::Float64) where {T,D<:YieldEnergyData,V}
    out = Dierckx.evaluate(sp.interp, E)
    return out < 0 ? 0.0 : out
end

function (sp::Yield{T,D,V})(E::Array) where {T,D<:YieldEnergyData,V}
    out = Dierckx.evaluate(sp.interp, E)
    out[out.<0] .= 0.0
    return out
end

