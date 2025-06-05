
abstract type RustBCASputteringYieldDataBase end
struct RustBCADataBase{D} <: RustBCASputteringYieldDataBase
    data::D
end


load_rustbca_database(fp) = RustBCADataBase(read_db_file(fp))


basename_noext(f) = splitext(basename(f))[1]





function change_extension(filepath::String, new_extension::String)
    # Split the path into a tuple of (filename, extension)
    filename, _ = splitext(filepath)
    # Replace with the new extension
    return filename * "." * new_extension
end


"""
    RustBCAYieldData{V<:Matrix,U<:Vector} <: AbstractYieldEnergyAngleData

Structure to hold sputtering yield data obtained from RustBCA simulations.

# Fields
- `target::String`: Target material.
- `projectile::String`: Projectile species.
- `R_p::V`: Projectile range matrix (energy vs angle).
- `R_E::V`: Energy loss matrix (energy vs angle).
- `Y::V`: Sputtering yield matrix (energy vs angle).
- `E::U`: Energy vector.
- `θ::U`: Angle vector.
- `info::Dict`: Dictionary containing additional information.
"""

struct RustBCAYieldData{V<:Matrix,U<:Vector} <: YieldEnergyAngleData
    target::String
    projectile::String
    R_p::V
    R_E::V
    Y::V
    E::U
    θ::U
    info::Dict
end

get_pt(Y::RustBCAYieldData) = Y.projectile => Y.target



function RustBCAYieldData(data, target, projectile, npy_file)
    yields = data["Y"]
    @assert target in keys(yields)
    yields_target = yields[target]
    @assert projectile in keys(yields_target)
    yields_ = yields_target[projectile]
    if length(keys(yields_)) == 0
        println("cannot find $projectile -> $target")
        return missing
    end
    energy = yields_["energy"]
    theta = yields_["angle"]
    info = Dict("file" => npy_file)
    RustBCAYieldData(target, projectile, yields_["R_p"], yields_["R_E"], yields_["Y"], energy, theta, info)
end
function sputtering_yield(db::RustBCADataBase, pair::Pair;  kw...)
    out = []
    for v in db.data
        if get_pt(v) == pair
            push!(out, v)
        end
    end

    if length(out) == 1
        return sputtering_yield(out[1])
    else
        error("sputtering yield  for pair $pair not found in rustbca database!")
    end
end

function reflection_yield(db::RustBCADataBase, pair::Pair; kw...)
    out = []
    for v in db.data
        if get_pt(v) == pair
            push!(out, v)
        end
    end

    if length(out) == 1
        return reflection_yield(out[1])
    else
        error("sputtering yield  for pair $pair not found in rustbca database!")
    end
end






function read_rustbca_npy(npy_file::String)
    np = []
    try  
        np = pyimport("numpy")
    catch
        CondaPkg.add("numpy")
        np = pyimport("numpy")
    end
    data = Dict((k, v) for (k, v) in np.load(npy_file, allow_pickle=true)[].items())
end

function rustbca_npy2vec(npy_file::String)
    np = pyimport("numpy")
    data = Dict((k, v) for (k, v) in np.load(npy_file, allow_pickle=true)[].items())
    db = Vector{RustBCAYieldData}()
    for (target, projectile) in zip(data["target"], data["projectile"])
        if length(data["Y"][target][projectile]) == 0
            println("skipping $projectile -> $target in $(basename(npy_file))")
            continue
        end
        push!(db, RustBCAYieldData(data, target, projectile, npy_file))
    end
    return db
end

get_file_list(dir_path, ext) = joinpath.(dir_path, filter(x -> endswith(x, ext), readdir(dir_path)))

function parse_file(dir_path, ::Type{<:RustBCAYieldData})
    files = get_file_list(dir_path, ".npy")
    vcat([rustbca_npy2vec(file) for file in files]...)
end
sputtering_yield(p,t, yield::Float64) = Yield{:sputtering}(get_element(p), get_element(t), yield, yield, Dict())
sputtering_yield(yield::RustBCAYieldData; kx=2) = Yield{:sputtering}(get_element(yield.projectile), get_element(yield.target), yield, Dierckx.Spline2D(yield.E, yield.θ, yield.Y; kx=2), yield.info)
particlereflection_yield(yield::RustBCAYieldData; kx=2) = Yield{:particlereflection}(get_element(yield.projectile), get_element(yield.target), yield, Dierckx.Spline2D(yield.E, yield.θ, yield.Y; kx=2), yield.info)
particlereflection_yield(p, t, yield::Float64) = Yield{:particlereflection}(get_element(p), get_element(t), yield, yield, Dict())

get_E(Y::Yield) = get_E(Y.data)
get_E(Y::RustBCAYieldData) = Y.E

Base.show(io::IO, Y::Yield) = print(io, "Yield $(get_pt(Y))")
Base.show(io::IO, Y::RustBCAYieldData) = print(io, "rustbca yield $(Y.projectile) -> $(Y.target)")
Base.show(io::IO, ::MIME"text/plain",Y::RustBCAYieldData) = print(io, "rustbca yield $(Y.projectile) -> $(Y.target)")