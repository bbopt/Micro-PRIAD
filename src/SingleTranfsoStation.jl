using Distributions

import Base.isless

struct Indisponibilite
    eq_index::Int                  # Index de l'équipement   
    mec_index::Int                 # Index du mécanisme de défaillance
    temps_maint::Float64           # Dans combien de temps est la prochaine maintenance planifiée
    temps_fail::Float64            # Dans combien de temps la prochaine defaillance aurait lieu sans maintenance
    moment::Float64                # Moment auquel les temps ont été tirés
    moment_indispo::Float64        # Moment auquel il est prévu que l'équipement sera indispo
end

function Indisponibilite(eq_index::Int, mec_index::Int, temps_maint::Float64, temps_fail::Float64, moment::Float64)
    return Indisponibilite(eq_index, mec_index, temps_maint, temps_fail, moment, moment + min(temps_maint, temps_fail))
end

function isless(in1::Indisponibilite, in2::Indisponibilite)
    return in1.moment_indispo < in2.moment_indispo
end

function isless(in1::Indisponibilite, t::Int)
    return in1.moment_indispo < t
end

function picopriad_plages(x::Vector{Vector{Float64}}; nb_tirages::Int=1, seed::Union{Nothing,Int}=nothing)
    rng = seed === nothing ? Random.GLOBAL_RNG : MersenneTwister(seed)
 
    # Constantes
    μ = 1.0                                     # Normale réparation
    σ = 0.5                                     # Normale réparation
    k = 2                                       # Weibull défaillance
    H = 40*12                                   # Horizon temporel en mois

    I = 3                                       # Nombre d'équipements
    nb_meca = [1, 2, 1]                         # Nombre de mécanismes de défaillance. Ceux-ci sont réparés et maintenus de façon indépendante
    combos_défaillance = [(1,2), (2,3)]         # Combinaisons tels que dès que ces deux équipements sont en N-2, il faut une simulation électrique
    λ_constante = [[20], [30,30], [40]]         # Constante de résiliance
    cout_rep = [[15], [30,40], [20]]            # Coût de réparation
    cout_maint = [[8], [16,24], [12]]           # Coût de maintenance planifiée
    temps_maint = [[0.5], [0.5,0.5], [0.5]]     # Temps de maintenance planifiée

    for i in 1:I
        (length(x[i]) != nb_meca[i]) && (error("La taille de x[$i] ne correspond pas au nombre de mécanismes de défaillance."))
        for j in 1:nb_meca[i]
            (x[i][j] < 0) && (error("La valeur de x[$i] est négative."))
        end
    end

    # Asset behaviour model et maintenance planifiée
    λ = λ_constante #[[λ_constante[i][j] / x[i][j]^(1/3) for j in 1:nb_meca[i]] for i in 1:I] #Ya dequoi que je ne comprend pas le Asset behaviour model de PRIAD. En altérant les λ ET en simulant les indispoinibilités, on compte 2 fois l'avantage de faire de la maintenance. Ici, j'enlève un de ces deux mécanismes.
    cout_maintenance_planifiee = 0
    for i in 1:I
        for j in 1:nb_meca[i]
            cout_maintenance_planifiee += cout_maint[i][j] * H / x[i][j]
        end
    end

    # Plages d'indispoinibilité
    duree_combos = Vector{Dict{Vector{Int},Float64}}(undef, nb_tirages)
    cout_maintenance_reel = zeros(nb_tirages)
    cout_reparation = zeros(nb_tirages)
    for fleche in 1:nb_tirages
        plage = [Vector{Float64}[] for i in 1:I]
        stack = Indisponibilite[]
        for i in 1:I
            for j in 1:nb_meca[i]
                next_indispo = Indisponibilite(i, j, x[i][j], rand(rng, Weibull(k, λ[i][j])), 0.0)
                (next_indispo < H) && push!(stack, next_indispo)
            end
        end
        while !isempty(stack)
            sort!(stack)
            indispo = popfirst!(stack)
            moment_fail = indispo.moment + indispo.temps_fail
            moment_maint = indispo.moment + indispo.temps_maint
            moment_maint_resedule = re_sedule_maint(moment_maint, temps_maint, combos_défaillance, indispo.eq_index, indispo.mec_index, plage)
            delais = moment_maint_resedule - moment_maint
            if delais > 0
                push!(stack, Indisponibilite(indispo.eq_index, indispo.mec_index, indispo.temps_maint + delais, indispo.temps_fail, indispo.moment))
            else
                if min(moment_fail, moment_maint) < H
                    local fin::Float64
                    if moment_fail >= moment_maint
                        fin = min(moment_maint + temps_maint[indispo.eq_index][indispo.mec_index], H)
                        push!(plage[indispo.eq_index], [moment_maint, Float64(indispo.mec_index), fin])
                        cout_maintenance_reel[fleche] += cout_maint[indispo.eq_index][indispo.mec_index]
                    else
                        repair_time = rand(rng, LogNormal(μ, σ))
                        fin = min(moment_fail + repair_time, H)
                        (!isempty(plage[indispo.eq_index]) && plage[indispo.eq_index][end][3] > moment_fail) && (plage[indispo.eq_index][end][3] = moment_fail)
                        push!(plage[indispo.eq_index], [moment_fail, -1*Float64(indispo.mec_index), fin])
                        cout_reparation[fleche] += cout_rep[indispo.eq_index][indispo.mec_index]
                    end
                    push!(stack, Indisponibilite(indispo.eq_index, indispo.mec_index, x[indispo.eq_index][indispo.mec_index], rand(rng, Weibull(k, λ[indispo.eq_index][indispo.mec_index])), fin))
                end
            end
        end

        # Découpage en segments uniques
        omni_plage = Tuple{Float64,Vector{Int}}[]
        separateurs = [0.0]
        for i in 1:I
            for (debut, type, fin) in plage[i]
                push!(separateurs, debut)
                push!(separateurs, fin)
            end
        end
        separateurs = unique(sort(separateurs))
        current_event = [isempty(plage[i]) ? [H+1.0, 0.0, H+1.0] : popfirst!(plage[i]) for i in 1:I]
        for sep in separateurs[1:end-1]
            eq_dispo = trues(I)
            for i in 1:I
                while current_event[i][end] <= sep
                    current_event[i] = isempty(plage[i]) ? [H+1.0, 0.0, H+1.0] : popfirst!(plage[i])
                end
                if current_event[i][1] <= sep
                    eq_dispo[i] = false
                end
            end
            push!(omni_plage, (sep, findall(x -> !x, eq_dispo)))
        end
        push!(omni_plage, (H, Int[]))

        # Aggrégation des temps pertinents
        temps_totaux = Dict{Vector{Int},Float64}()
        for (s,sep) in enumerate(omni_plage)
            if any([combo[1] ∈ sep[2] && combo[2] ∈ sep[2] for combo in combos_défaillance])
                temps_totaux[sep[2]] = get(temps_totaux, sep[2], 0.0) + omni_plage[s+1][1] - sep[1]
            end
        end
        duree_combos[fleche] = temps_totaux
    end
    return duree_combos, cout_maintenance_reel, cout_reparation, H
end

function picopriad_sims(duree_combos::Vector{Dict{Vector{Int},Float64}}, cout_maintenance_reel::Vector{Float64}, cout_reparation::Vector{Float64}, H::Int)
    nb_tirages = length(duree_combos)
    cout_MWhi = zeros(nb_tirages)
    fs = Vector{Float64}(undef, nb_tirages)

    for fleche in 1:nb_tirages
        for (equipements, duree) in duree_combos[fleche]
            cout_MWhi[fleche] += duree == 0 ? 0 : ((duree+1)^(length(equipements))) * 100
        end
        fs[fleche] = cout_maintenance_reel[fleche] + cout_reparation[fleche] + cout_MWhi[fleche]
    end

    return mean(fs)
end

function re_sedule_maint(moment_maint::Float64, temps_maint::Vector{Vector{Float64}}, combos_défaillance::Vector{Tuple{Int,Int}}, equipement::Int, mecanisme::Int, plage::Vector{Vector{Vector{Float64}}})
    valid = false
    combo_friends = Int[]
    for (e1, e2) in combos_défaillance
        if e1 == equipement
            push!(combo_friends, e2)
        elseif e2 == equipement
            push!(combo_friends, e1)
        end
    end

    while !valid
        valid = true
        if !isempty(plage[equipement]) && moment_maint < plage[equipement][end][3]
            valid = false
            moment_maint = plage[equipement][end][3]
        elseif any([(moment_maint >= debut && moment_maint < fin) || (moment_maint+temps_maint[equipement][mecanisme] > debut && moment_maint+temps_maint[equipement][mecanisme] <= fin) for i in eachindex(combo_friends) for (debut, type, fin) in plage[combo_friends[i]]])
            valid = false
            for friend in combo_friends
                for (debut, type, fin) in plage[friend]
                    if (moment_maint >= debut && moment_maint < fin) || (moment_maint+temps_maint[equipement][mecanisme] > debut && moment_maint+temps_maint[equipement][mecanisme] <= fin)
                        moment_maint = fin
                    end
                end
            end
        end
    end
    return moment_maint
end

function singleTransfoStation(x::Vector{Float64}, N::Int, seed::Int, SubSampler::Function, AnyParamForSubSampler::String)
    x = [[x[1]*12], [x[2]*12, x[3]*12], [x[4]*12]]
    (typeof(seed) == Int) && (seed = round(Int, sum([prod(xi) for xi in x])) + seed)

    duree_combos, cout_maintenance_reel, cout_reparation, H = picopriad_plages(x; nb_tirages=N, seed=seed)
    moy_cout_maintenance_reel = mean(cout_maintenance_reel)
    moy_cout_reparation = mean(cout_reparation)
    
    Ys = Vector{Vector{Float64}}(undef, N)
    for i in 1:N
        y = duree_combos[i]
        (collect(keys(y)) ⊆ [[1,2], [2,3], [1,2,3]]) || error("Unexpected keys in y : $(keys(y))")
        Ys[i] = [get(y, [1,2], 0.0), get(y, [2,3], 0.0), get(y, [1,2,3], 0.0)]
    end

    Yss = SubSampler(Ys, AnyParamForSubSampler)
    Yss = Ys[Yss]
    t = length(Yss)
    sub_duree_combos = [Dict([1,2] => Yss[i][1], [2,3] => Yss[i][2], [1,2,3] => Yss[i][3]) for i in 1:t]

    f = picopriad_sims(sub_duree_combos, [moy_cout_maintenance_reel for i in 1:t], [moy_cout_reparation for i in 1:t], H)
    nb_tirages = size(unique(Yss, dims=1), 1)
    return f
end