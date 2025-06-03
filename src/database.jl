



abstract type AbstractSputteringYieldDataBase end

const yields_database = Dict(:sputtering => Dict(), :reflection_energy => Dict(), :reflection_particle => Dict(), :sputtered_distribution => Dict(), :loaded => false)

is_yield_db_loaded() = yields_database[:loaded]



const database_paths = Dict{Symbol,Any}()
function set_database_paths!(;src_dir=joinpath(@__DIR__, "../database/"), parsed_dir=joinpath(src_dir, "parsed/"))
    database_paths[:src_database_dir]= joinpath(src_dir, "src/")
    database_paths[:parsed_database_dir] = parsed_dir
    database_paths[:src_filepaths] = Dict()
    database_paths[:src_filepaths][:normal_behrisch] = joinpath(database_paths[:src_database_dir], "behrisch/behrisch_book_normal_incidence.txt")
    database_paths[:src_filepaths][:angular_behrisch] = joinpath(database_paths[:src_database_dir], "behrisch/behrisch_book_angular_dependency.txt")
    database_paths[:src_filepaths][:rustbca_dir] = joinpath(database_paths[:src_database_dir], "rustbca")
end

set_database_paths!()

parsed_check_file() = joinpath(database_paths[:parsed_database_dir], ".process")
is_yield_db_parsed() = isfile(parsed_check_file())
function write_process_file() 
    io = open(parsed_check_file(), "w")
    println(io, "process $(now())")
    close(io)
end


change_path_db(fp, dir; ext="jdl2") = joinpath(dir, splitext(basename(fp))[1] * "." * ext)

function get_filepaths(parsed_dir, src_filepaths)
    Dict(:parsed =>Dict{Symbol,String}(k => change_path_db(v, parsed_dir; ext="jld2") for (k, v) in src_filepaths),
        :src => src_filepaths
    )
end



function make_yields_database!(;src_filepaths = database_paths[:src_filepaths], parsed_dir = database_paths[:parsed_database_dir])
        fps = get_filepaths(parsed_dir, src_filepaths)
        save_db_file(fps[:parsed][:normal_behrisch], parse_file(fps[:src][:normal_behrisch]; parser=BehrischNormalIncidenceSputteringYieldData))
        save_db_file(fps[:parsed][:angular_behrisch], parse_file(fps[:src][:angular_behrisch]; parser=BehrischAngularSputteringYieldData))
        save_db_file(fps[:parsed][:rustbca_dir], parse_file(fps[:src][:rustbca_dir], ; parser=RustBCAYieldData))
        write_process_file()
end



function load_yields_database!(; remake_database=false, force_reload=false, src_filepaths=database_paths[:src_filepaths], parsed_dir=database_paths[:parsed_database_dir])
    if (!is_yield_db_loaded() || remake_database || force_reload)
        fps = get_filepaths(parsed_dir, src_filepaths)
        println("Loading yield database ... ")
        (!is_yield_db_parsed() || remake_database) ? make_yields_database!(;src_filepaths, parsed_dir) : nothing
        yields_database[:sputtering][:angular_behrisch] = AngularBerischDataBase(fps[:parsed][:angular_behrisch])
        yields_database[:sputtering][:normal_behrisch] = NormalBerischDataBase(fps[:parsed][:normal_behrisch])
        yields_database[:sputtering][:rustbca] = load_rustbca_database(fps[:parsed][:rustbca_dir])
        yields_database[:reflection_particle][:rustbca] = load_rustbca_database(fps[:parsed][:rustbca_dir])
        yields_database[:reflection_energy][:rustbca] = load_rustbca_database(fps[:parsed][:rustbca_dir])
        yields_database[:loaded] = true
    end
end

function get_yields_database(; kw...)
    load_yields_database!(;kw...)
    return yields_database
end


sputtering_yield(p::Pair{Symbol,Symbol}, args...; kw...) = sputtering_yield(p[1], p[2], args...; kw...)

function sputtering_yield(projectile::Symbol, target::Symbol, database::Symbol; kw...)
    p = FusionSpecies.get_element(projectile) 
    t = FusionSpecies.get_element(target)
    sputtering_yield(p, t, database; kw...)
end
sputtering_yield(p::Species, t::Element, database; kw...) = sputtering_yield(p.element, t, database; kw...)
function sputtering_yield(p::Union{Element}, t::Union{Element}, database::Symbol; value=missing, kw...)
    !ismissing(value) && return sputtering_yield(p, t, value; kw...)

    pair = lowercase(p.name) => lowercase(t.name)
    println("looking for sputtering yield `$pair` into database `$database`")
    db = get_yields_database()[:sputtering]
    @assert database ∈ keys(db) "database `$database` not found in sputtering databases ... Available databases: $(keys(db))"
    return sputtering_yield(db[database], pair; kw...)
end

no_sputtering_yield(p::Union{Element,AbstractSpecies}, t::Union{Element,AbstractSpecies}, args...; kw...) = Yield{:sputtering,Missing,Missing}(get_element(p), get_element(t), missing, missing, Dict())

function no_sputtering_yield(projectile::Symbol, target::Symbol, args...; kw...)
    p = FusionSpecies.get_element(projectile) 
    t = FusionSpecies.get_element(target)
    no_sputtering_yield(p, t, args...; kw...)
end


particlereflection_yield(p::Pair{Symbol,Symbol}, args...; kw...) = particlereflection_yield(p[1], p[2], args...; kw...)

function particlereflection_yield(projectile::Symbol, target::Symbol, database::Symbol; kw...)
    p = FusionSpecies.get_element(projectile)
    t = FusionSpecies.get_element(target)
    particlereflection_yield(p, t, database; kw...)
end
particlereflection_yield(p::Species, t::Element, database; kw...) = particlereflection_yield(p.element, t, database; kw...)
function particlereflection_yield(p::Union{Element}, t::Union{Element}, database::Symbol; value=missing, kw...)
    !ismissing(value) && return particlereflection_yield(p, t, value; kw...)
    pair = lowercase(p.name) => lowercase(t.name)
    println("looking for sputtering yield `$pair` into database `$database`")
    db = get_yields_database()[:particlereflection]
    @assert database ∈ keys(db) "database `$database` not found in sputtering databases ... Available databases: $(keys(db))"
    particlereflection_yield(db[database], pair; kw...)
end

no_particlereflection_yield(p::Union{Element,AbstractSpecies}, t::Union{Element,AbstractSpecies}, args...; kw...) = Yield{:particlereflection,Missing,Missing}(get_element(p), get_element(t), missing, missing, Dict())

function no_particlereflection_yield(projectile::Symbol, target::Symbol, args...; kw...)
    p = FusionSpecies.get_element(projectile)
    t = FusionSpecies.get_element(target)
    no_particlereflection_yield(p, t, args...; kw...)
end