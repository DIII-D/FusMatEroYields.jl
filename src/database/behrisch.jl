

abstract type BerischSputteringYieldDataBase end 
struct BehrischNormalIncidenceSputteringYieldData <: YieldEnergyData
    projectile::Symbol
    target::Symbol
    λ::Float64
    q::Float64
    μ::Float64
    Eth::Float64
    ε0::Float64
    Esb::Float64
    Esb_γ::Float64
end

struct BehrischAngularSputteringYieldData <: YieldEnergyAngleData
    projectile::Symbol
    target::Symbol
    E0::Float64
    f::Float64
    b::Float64
    c::Float64
    Y0::Float64
    Esp::Float64
    θ_prime::Float64
    θ_0m::Float64
end

struct BehrischAngularSputteringYields
    E0::Vector{Float64}
    data::Vector{BehrischAngularSputteringYieldData}
end

struct NormalBerischDataBase{D} <: BerischSputteringYieldDataBase
    data::D
end
NormalBerischDataBase(filepath::String) = NormalBerischDataBase(read_db_file(filepath))

struct AngularBerischDataBase{D} <: BerischSputteringYieldDataBase
    data::D
end
AngularBerischDataBase(filepath::String) = AngularBerischDataBase(read_db_file(filepath))



get_targets(db; kw...) = keys(db)
function show_targets(db::Dict; type=:behrisch, kw...)
    for t in get_targets(db[:behrisch]; kw...)
        println(t)
    end
end
# function get_targets(db::BerischDataBase; field=:angular)
#     @assert field == :normal || field == :angular
#     collect(keys(getfield(db, field)))
# end
Base.keys(db::BerischSputteringYieldDataBase) = keys(db.data)
Base.getindex(db::BerischSputteringYieldDataBase, s) = getindex(db.data, s)
get_projectiles(database, target) = keys(database[target])
function get_sputtering_yield(db::BerischSputteringYieldDataBase, projectile::Symbol, target::Symbol; kw...)

    @assert target ∈ keys(db) "target material $target is not in behrisch database. \n Available targets: $(get_targets(db))"
    @assert projectile ∈ keys(db[target]) "projectile material $projectile for target $target not available in behrisch database. \n  Available projectiles for target $target are $(get_projectiles(db,target))  "

    data = db[target][projectile]
    values = Y_interpolator(data; kw...)
    label = "Sputtering yield $projectile -> $target from database: Behrisch/E/θ"
    SputteringYield(projectile, target, data, values, label)
end

function Y_interpolator(data::BehrischNormalIncidenceSputteringYieldData; E::Vector{Float64}=10 .^ collect(LinRange(1, 5, 10000)))
    @assert all(E .> 0.0)
    ε = E / data.ε0
    sn_KrC = @. (0.5 * log(1.0 + 1.2288 * ε)) / (ε + (0.1728 * sqrt(ε)) + (0.008 * (ε .^ 0.1504)))
    η = E / data.Eth
    η[E.<data.Eth] .= 1.0
    Y_phys = @. data.q * sn_KrC * (η - 1.0)^data.μ ./ (data.λ + (η - 1.0)^data.μ)
    Y_phys[E.<data.Eth] .= 0.0
    return Dierckx.Spline1D(E, Y_phys)
end

meshgrid(x, y) = first.(Base.Iterators.product(x, y)), last.(Base.Iterators.product(x, y))

function Y_interpolator(data::BehrischAngularSputteringYields; nθ=91)
    print("here")
    E0 = copy(data.E0)
    θ = collect(LinRange(0, 90, nθ))
    Y = zeros(length(E0) + 1, length(θ))
    for (i, j) in Base.Iterators.product(eachindex(E0), eachindex(θ))

        Y[i+1, j] = Y_angular_Eckstein(data.data[i], θ[j])
    end
    insert!(E0, 1, 0.0) # extend manually interpolant to zero
    Y[1, :] .= 0.0
    return Dierckx.Spline2D(E0, θ, Y; kx=1)
end




Y_normal_Eckstein(data::BehrischNormalIncidenceSputteringYieldData, E::Float64) = behrisch_Y_interpolator(data, [E])[1]


# (sp::SputteringYield{D,V})(E::T, θ::U) where {D<:BehrischNormalIncidenceSputteringYield,V,T<:Vector,U} = Y_normal_Eckstein(sp.data, E)[1]



#get_E(sp::SputteringYield; kw...) = get_E(sp.data; kw...)
get_E(::BehrischNormalIncidenceSputteringYieldData; E::Vector{Float64}=10 .^ collect(LinRange(1, 5, 1000))) = E
get_E(s::BehrischAngularSputteringYields) = s.E0
function Y_angular_Eckstein(θ::Vector{Float64}, Y0::Float64, f::Float64, b::Float64, c::Float64, θ_prime::Float64)
    @assert all(0.0 .<= θ .<= θ_prime)
    η = @. abs(cos((pi / 2.0 * θ / θ_prime)^c))
    @assert all(@. Y0 * η^(-f) * exp(b * (1.0 - 1.0 / η)) >= 0.0)
    return @. Y0 * η^(-f) * exp(b * (1.0 - 1.0 / η))
end

Y_angular_Eckstein(data::BehrischAngularSputteringYieldData, θ::Vector{Float64}) = Y_angular_Eckstein(θ, data.Y0, data.f, data.b, data.c, data.θ_prime)
Y_angular_Eckstein(data::BehrischAngularSputteringYieldData, θ::Float64) = Y_angular_Eckstein(data, [θ])[1]



"""
    parse_file(filepath::String)

TBW
"""

parse_file(filepath::String; parser=missing) = parse_file(filepath, parser)
function parse_file(filepath::String, parser::Type{<:Union{BehrischNormalIncidenceSputteringYieldData,BehrischAngularSputteringYieldData}})
    data = Vector{parser}()
    open(filepath) do f

        # line_number
        line = 0

        # read till end of file
        while !eof(f)

            # read a new / next line for every iteration          
            s = readline(f)
            if !isempty(s)
                push!(data, parse_line(s, parser))
            end
            line += 1
            #println("line $line")
        end
    end
    return todict(data)
end

function parse_line(line::String, parser)
    strs = split(line, " ")
    #println("--- ", strs)
    parser(convert_species(strs[1]), convert_species(strs[2]), parse.(Float64, strs[3:end])...)
end



convert_species(s::AbstractString) = Symbol(join(reverse(split(s, r"(?<=\d)(?=\D)|(?<=\D)(?=\d)")), "_"))


function todict(v::Vector{<:BehrischNormalIncidenceSputteringYieldData})
    dic = Dict(s.target => Dict() for s in v)
    for s in v
        dic[s.target][s.projectile] = s
    end
    return dic
end

function todict(v::Vector{<:BehrischAngularSputteringYieldData})
    dic = Dict(s.target => Dict() for s in v)
    dic_ = Dict(s.target => Dict() for s in v)
    for s in v
        if s.projectile ∉ keys(dic_[s.target])
            dic_[s.target][s.projectile] = Dict()
        end
        dic_[s.target][s.projectile][s.E0] = s
    end

    for t in keys(dic_)
        for p in keys(dic_[t])
            if p ∉ keys(dic[t])
                dic[t][p] = Dict()
            end
            E = [E0 for E0 in keys(dic_[t][p])]
            V = [s for s in values(dic_[t][p])]
            idx = sortperm(E)
            #println(idx)
            #println(E)
            #println(V)
            @assert length(E[idx]) == length(V[idx]) "ISSUE"
            dic[t][p] = BehrischAngularSputteringYields(E[idx], V[idx])
        end
    end
    return dic
end




# Base.getindex(b::AbstractBerischDataBase, s::Symbol) = getfield(b, s)

