include("Struct.jl")
include("Param.jl")
include("Initialisation.jl")

include("InterrupterFunctions.jl")
include("Single_MC_info_return_Functions.jl")
include("SubSamplerFunctions.jl")

include("UnavailabilitySimulator.jl")
include("ElectricitySimulator.jl")
include("RiskModule.jl")

#=
The "checkInput" function checks if the input given by the solver respects the input format; if not, it prints an error message
=#
function checkInput(input)
    if length(input) == 28
        for i in [1, 3, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]
            if abs(round(input[i]) - input[i]) >= 0.001
                @error "The $(i)th input is supposed to be an Int but is not an Int"
            end
            if input[i] <= 0 
                @error "The $(i)th input is supposed to be positive but is non positive"
            end
        end
        for i in [2, 4, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 28]
            if input[i] <= 0 
                @error "The $(i)th input is supposed to be positive but is non positive"
            end
        end
    elseif length(input) == 15
        for i in 1:15
            if input[i] <= 0 
                @error "The $(i)th input is is suppose to be positive but is non positive"
            end
        end
    elseif length(input) == 13
        for i in [1, 3, 5, 7, 9, 11]
            if abs(round(input[i]) - input[i]) >= 0.001
                @error "The $(i)th input is supposed to be an Int but is not an Int"
            end
            if input[i] <= 0 
                @error "The $(i)th input is supposed to be positive but is non-positive"
            end
        end
        for i in [2, 4, 6, 8, 10, 12, 13]
            if input[i] <= 0 
                @error "The $(i)th input is supposed to be positive but is non-positive"
            end
        end
    end
end

#=
The "logTime" function is used to print the time required for a call of the black box, the time written in the file is 
"time2Log" and it is written only if asked (loggingTime != false)
=#
function logTime(time2Log, loggingTime)
    if loggingTime == "true"
        dir = @__DIR__
        splitDir = split(dir, "/") 
        newSplitDir = Vector{SubString}(undef, length(splitDir) - 1)
        for i in 1:(length(splitDir) - 1)
            newSplitDir[i] = splitDir[i]
        end
        newDir = join(newSplitDir, "/")
        io = open("$newDir/timeLog.txt", "a")
        write(io, "$time2Log\n")
        close(io)
    elseif loggingTime == "false"
    else
        if loggingTime[end] == "/"
            io = open("$(loggingTime)timeLog.txt", "a")
        elseif loggingTime[end - 3:end] == ".txt"
            io = open("$loggingTime", "a")
        else
            io = open("$(loggingTime)/timeLog.txt", "a")
        end
        write(io, "$time2Log\n")
        close(io)
    end
end

#=
The "logN" function is used to print the number of Monte Carlo trials required for a call of the black box, the number written in the file is 
"N2Log" and it is written only if asked (loggingN != false)
=#
function logN(N2Log, loggingN)
     if loggingN == "true"
        dir = @__DIR__
        splitDir = split(dir, "/") 
        newSplitDir = Vector{SubString}(undef, length(splitDir) - 1)
        for i in 1:(length(splitDir) - 1)
            newSplitDir[i] = splitDir[i]
        end
        newDir = join(newSplitDir, "/")
        io = open("$newDir/NLog.txt", "a")
        write(io, "$N2Log\n")
        close(io)
    elseif loggingN == "false"
    else
        if loggingN[end] == "/"
            io = open("$(loggingN)NLog.txt", "a")
        elseif loggingN[end - 3:end] == ".txt"
            io = open("$loggingN", "a")
        else
            io = open("$(loggingN)/NLog.txt", "a")
        end
        write(io, "$N2Log\n")
        close(io)
    end
end

#=
The "logPhi" function is used to print the fidelity of the black box required for a call of the black box, the fidelity written in the file is 
"phi2Log" and it is written only if asked (loggingPhi != false)
=#
function logPhi(phi2Log, loggingPhi)
     if loggingPhi == "true"
        dir = @__DIR__
        splitDir = split(dir, "/") 
        newSplitDir = Vector{SubString}(undef, length(splitDir) - 1)
        for i in 1:(length(splitDir) - 1)
            newSplitDir[i] = splitDir[i]
        end
        newDir = join(newSplitDir, "/")
        io = open("$newDir/phiLog.txt", "a")
        write(io, "$phi2Log\n")
        close(io)
    elseif loggingPhi == "false"
    else
        if loggingPhi[end] == "/"
            io = open("$(loggingPhi)phiLog.txt", "a")
        elseif loggingPhi[end - 3:end] == ".txt"
            io = open("$loggingPhi", "a")
        else
            io = open("$(loggingPhi)/phiLog.txt", "a")
        end
        write(io, "$phi2Log\n")
        close(io)
    end
end

#=
The "MicroPRIAD" function is the heart of the black box, it links the processing blocks to take a maintenance  periodicity vector "x" and return the objective function value and the constraints values "FFC".

######################################################## Input ###########################################################
@Param ϕ: is the blackbox fidelity and is contained from 0 to 1.
@Param seed: is the black box random seed used for the Monte Carlo samples
@Param Interrupter: is the function that controls the intermediate return of the function and the constraints, it is initialized to "basicInterrupter" if not specified
@Param AnyParamForContinueEvalFunction: is a string that can be used to give any parameter to the "Interrupter" function, it is initialized to an empty string if not specified
@Param PG: argument indicates which instance is used to initialize the network; it can be set either to an instance [s, r, u, t]
@Param loggingTime: argument indicates if the user wants the program to print a "timeLog.txt" file with the running time of each itterations.
@Param N: is the total number of Monte Carlo trial done to evluate Micro-PRIAD when ϕ = 1.0, it is set to 10000 by default
@Param eta: is the number of time each intermediate return and subsampler is called, (umber of itteration of the loop) it is set to 10 by default
@Param s: is the number of Monte Carlo trials done at each intermediate return of the blackbox, it is set to 1000 by default
@Param availInterrupter: is a boolean that indicates if there is an additional intermediate return when half of the MC constraints are computed. 
    It is set to true by default, because between the first half and the second half of the constraints evaluation, there is a lot of time spent. It is even more true when s is high.
@Param single_MC_info_return: argument indicates if the user wants the program to print every single Monte Carlo trial in a .txt file
@Param AnyParamForSingle_MC_Info_ReturnFunction: is a string that can be used to give any parameter to the "single_MC_info_return" function, it is initialized to an empty string if not specified
@Param SubSampler: is the function used to do the SubSampler if needed, it is initialized to "basicSubSampler" if not specified
@Param AnyParamForSubSampler: is a string that can be used to give any parameter to the "SubSampler" function, it is initialized to an empty string if not specified
@Param first_s_to_one : make the first MC loop do a sample of size 1.
@Param x: is the maintenance's periodicity, the coordinate that the solver can interact with, it is defined as follows:

for 28 inputs : for 15 inputs : for 13 inputs :
     X[1]     :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for prod/HV transformators : of the prod/HV transformation stations : for the failure mechanisme of the radiator obstruction
     X[2]     :     X[1]      :               : Float64 : maintenance periodicity                                                                         : for prod/HV transformators : of the prod/HV transformation stations : for the failure mechanisme of the ground wire theft
     X[3]     :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for HV insulators          : of the prod/HV transformation stations : for the failure mechanisme of the de la corrosion
     X[4]     :     X[2]      :               : Float64 : maintenance periodicity                                                                         : for HV insulators          : of the prod/HV transformation stations : for the failure mechanisme of the copper theft
     X[5]     :     X[3]      :               : Float64 : maintenance periodicity                                                                         : for HV cables              : of the HV transporting lines           : for the failure mechanisme of the lines obstruction by the growth of tree          
     X[6]     :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for HV insulators          : of the HV transporting lines           : for the failure mechanisme of the de la corrosion 
     X[7]     :     X[4]      :               : Float64 : maintenance periodicity                                                                         : for HV insulators          : of the HV transporting lines           : for the failure mechanisme of the copper theft 
     X[8]     :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for HV/MV transformators   : of the HV/MV transformation stations   : for the failure mechanisme of the radiator obstruction             
     X[9]     :     X[5]      :               : Float64 : maintenance periodicity                                                                         : for HV/MV transformators   : of the HV/MV transformation stations   : for the failure mechanisme of the ground wire theft              
     X[10]    :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for HV disconnectors       : of the HV/MV transformation stations   : for the failure mechanisme of the de la corrosion 
     X[11]    :     X[6]      :               : Float64 : maintenance periodicity                                                                         : for HV disconnectors       : of the HV/MV transformation stations   : for the failure mechanisme of the copper theft
     X[12]    :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for HV breakers            : of the HV/MV transformation stations   : for the failure mechanisme of the de la corrosion
     X[13]    :     X[7]      :               : Float64 : maintenance periodicity                                                                         : for HV breakers            : of the HV/MV transformation stations   : for the failure mechanisme of the copper theft
     X[14]    :               :               : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for HV insulators          : of the HV/MV transformation stations   : for the failure mechanisme of the de la corrosion
     X[15]    :     X[8]      :               : Float64 : maintenance periodicity                                                                         : for HV insulators          : of the HV/MV transformation stations   : for the failure mechanisme of the copper theft
     X[16]    :               :     X[1]      : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for MV cables              : of the MV transporting lines           : for the failure mechanisme of the lines obstruction            
     X[17]    :     X[9]      :     X[2]      : Float64 : maintenance periodicity                                                                         : for MV cables              : of the MV transporting lines           : for the failure mechanisme of the copper theft            
     X[18]    :               :     X[3]      : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for MV insulators          : of the MV transporting lines           : for the failure mechanisme of the de la corrosion               
     X[19]    :     X[10]     :     X[4]      : Float64 : maintenance periodicity                                                                         : for MV insulators          : of the MV transporting lines           : for the failure mechanisme of the copper theft                
     X[20]    :               :     X[5]      : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for MV/LV transformators   : of the MV/LV transformation stations   : for the failure mechanisme of the radiator obstruction          
     X[21]    :     X[11]     :     X[6]      : Float64 : maintenance periodicity                                                                         : for MV/LV transformators   : of the MV/LV transformation stations   : for the failure mechanisme of the ground wire theft          
     X[22]    :               :     X[7]      : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for MV disconnectors       : of the MV/LV transformation stations   : for the failure mechanisme of the de la corrosion                 
     X[23]    :     X[12]     :     X[8]      : Float64 : maintenance periodicity                                                                         : for MV disconnectors       : of the MV/LV transformation stations   : for the failure mechanisme of the copper theft                  
     X[24]    :               :     X[9]      : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for MV breakers            : of the MV/LV transformation stations   : for the failure mechanisme of the de la corrosion                 
     X[25]    :     X[13]     :     X[10]     : Float64 : maintenance periodicity                                                                         : for MV breakers            : of the MV/LV transformation stations   : for the failure mechanisme of the copper theft                  
     X[26]    :               :     X[11]     : Int64   : maintenance periodicity depending on the next periodicity in the maintenance periodicity vector : for MV insulators          : of the MV/LV transformation stations   : for the failure mechanisme of the de la corrosion                
     X[27]    :     X[14]     :     X[12]     : Float64 : maintenance periodicity                                                                         : for MV insulators          : of the MV/LV transformation stations   : for the failure mechanisme of the copper theft                
     X[28]    :     X[15]     :     X[13]     : Float64 : maintenance periodicity                                                                         : for LV cables              : of the LV transporting lines           : for the failure mechanisme of the copper theft        
###########################################################################################################################
######################################################## Output ###########################################################
@Return FFC: is a string that represents a vector, it is defined as that : [count_eval, f, C1, C2,...,C9], the string formatting does not include the brackets nor the comma, it's the needed formatting for NOMAD, each element of the vector is defined as follows:    FFC[1]  : count_eval : is a flag that indicat if the solver need to count this evaluation, in the case where an a priori constraints is violated, the eval is not couted ant this flag take the value 0 and the black box evaluation is stoped.
    FFC[2]  : f          : is the objective function value that represent the monatary cost caused by the choice of "x"
    FFC[3]  : C1         : is an analytical a priori constraint that controls the number of maintenance over the 40 years
    FFC[4]  : C2         : is an analytical a priori constraint that controls the number of hours of planned maintenance over the 40 years
    FFC[5]  : C3         : is a constraint that controls the sum of the failure probability of each type of failure
    FFC[6]  : C4         : is a constraint that controls the failure probability of each type of failure on which the probability is weighted to make sure nothing goes over 10% and that most of them are below 5%
    FFC[7]  : C5         : is a constraint that controls the failure probability of each type of equipment on which the probability is weighted to make sure nothing goes over 10% and that most of them are below 5%
    FFC[8]  : C6         : is a constraint that controls the total time of service interruption
    FFC[9]  : C7         : is a constraint that controls the number of houres of unplanned maintenance over 40 years
    FFC[10] : C8         : is a constraint that controls the total number of undelivered energy over 40 years
    FFC[11] : C9         : is a constraint that controls the amount of undelivered energy to hospitals over 40 years
###########################################################################################################################
=#
function MicroPRIAD(input::Union{Vector{Float64}, Vector{Int64}, String}; ϕ::Float64 = 1.0, seed::Int64 = 0, Interrupter::Function = basicInterrupter, PG::Union{Int64, Char, String} = "s", loggingTime::String = "false", loggingN::String = "false", loggingPhi::String = "false", s::Union{Int64, Float64} = -1, eta::Union{Int64, Float64} = -1, availInterrupter::Bool = true, N::Union{Int64, Float64} = -1, AnyParamForInterrupter = "", single_MC_info_return::Function = basic_single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction = "", SubSampler::Function = basicSubSampler, AnyParamForSubSampler = "", first_s_to_one::Bool = false)                        
    timer = 0.0
    clk = time()

###################### checking for errors, and formating the problem depending on the input length #######################
    if typeof(input) == String
        input = split(input)
        input = parse.(Float64, input)
    end

    FFC = [Inf for i in 1:11]
    x = Vector{Float64}(undef, 28)

    if length(input) == 28                
        checkInput(input)
        x = input 
        C1_2_3_4_6_7_8_9multiplier = 1.0
    elseif length(input) == 15
        checkInput(input)
        x = [2, input[1], 2, input[2], input[3], 2, input[4], 2, input[5], 2, input[6], 2, input[7], 2, input[8], 2, input[9], 2, input[10], 2, input[11], 2, input[12], 2, input[13], 2, input[14], input[15]]
        C1_2_3_4_6_7_8_9multiplier = 1.0
    elseif length(input) == 13
        checkInput(input)
        x = [Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, Inf64, input[1], input[2], input[3], input[4], input[5], input[6], input[7], input[8], input[9], input[10], input[11], input[12], input[13]]
        C1_2_3_4_6_7_8_9multiplier = 28/13
    else
        @error "The input vector must be of length 28, 15 or 13"
        return nothing
    end

    if ϕ != trunc(ϕ, digits=4)
        ϕ = trunc(ϕ, digits=4)
        @warn "The fidelity ϕ was truncated to the 4th digits after the comma, ϕ = $ϕ"
    end

    if (SubSampler != basicSubSampler)
        if single_MC_info_return == print_single_MC_info_return
            @warn "The single_MC_info_return function cannot be used with a SubSampler function, the single_MC_info_return function will be set to print_single_MC_info_return_for_subSampling, that is compatible with the SubSampler function. its output is:\nf C8 C9\n"
            single_MC_info_return = print_single_MC_info_return_for_subSampling
        elseif s == 1
            @warn "The s parameter cannot be set to 1 because no SubSampler could be done. The s parameter will be set to 1000 by default.\n"
            s = 1000
        end
    elseif single_MC_info_return != basic_single_MC_info_return
        if single_MC_info_return == print_single_MC_info_return_for_subSampling
            @warn "The print_single_MC_info_return_for_subSampling function is curently without a SubSampler function, it only returns (f C8 and C9)"
        elseif s != 1
            @warn "The s parameter is given $s, but the constraint C6 and C7 cannot be returned correctly with this value. Use print_single_MC_info_return_for_subSampling or set s to 1. It has been set to 1 to avoid problems.\n"
            s = 1
        end
    end

    if s == 1 && first_s_to_one == true
        @warn "s=1 and first_s_to_one == true are redundant, first_s_to_one is set to false"
        first_s_to_one = false
    end

    println("N = $N, s = $s, eta = $eta")


    if s == -1 && N == -1 # eta défini
        N = 10000
        s = ceil(10000/eta)
    elseif eta == -1 && s == -1 # N defini
        if N > 1000
            s = 1000
        else
            s = N
        end
    elseif eta == -1 && N == -1 # s defini
        if s < 10000
            N = 10000
        else
            N = s
        end
    elseif s == -1 # s non défini
        s = ceil(N/eta)
    elseif N == -1 # N non défini
        N = eta * s
    elseif eta == -1 # eta non défini
        # ok        
    else
        if N != eta * s
            @warn "eta was ignored because the equality N = eta * s is not respected"
        end
    end
    
    if N < s
        @warn "N < s, the default value are used because we must have N >= s"
        N = 10000
        s = 1000
    elseif N < eta
        @warn "N < eta, the default value are used because we must have N >= eta"
        N = 10000
        s = 1000
    end

    N = Int64(N)
    s = Int64(s)
    
###########################################################################################################################

    nbVec = nbParam(PG)
    T = periodicityCalculator(x)
    requiredTimeForMaintenances = MaintenancesParam(PG)

####### C1 and C2 ########
    FFC[3:4] = [-500, -500]
    for i in 1:28
        FFC[3] += C1_2_3_4_6_7_8_9multiplier * 40/(T[i]) * 1.4
        FFC[4] += C1_2_3_4_6_7_8_9multiplier * requiredTimeForMaintenances[i] * 40/T[i] * 0.715
    end
    
    if (FFC[3] > 0 || FFC[4] > 0) || ϕ == 0.0 # A PRIORI Constraints check
        FFC[1] = 0.0
        
        #uncomment the one you need
        #return FFC             # return a vector [count_eval, f, [C]]
        str = join(FFC, " ")
        return str             # return the same vector but as a string without "[", "]" or "," (used for NOMAD solver)
    end
#########################

    FFC[1] = 1.0

    failureList = FailureList(T)

####### C3 and C4 ########
    FFC[5:6] = [-500, -500]
    for i in 1:28
        if failureList[i].DegradationProbability != Inf64
            FFC[5] += C1_2_3_4_6_7_8_9multiplier^0.728 * failureList[i].DegradationProbability * 225
        end
    end

    for i in 1:28
        if failureList[i].DegradationProbability == Inf64
        elseif failureList[i].DegradationProbability > 0.1
            FFC[6] += C1_2_3_4_6_7_8_9multiplier^0.5 * (failureList[i].DegradationProbability)^0.25 * 72.8
        elseif failureList[i].DegradationProbability > 0.05
            FFC[6] += C1_2_3_4_6_7_8_9multiplier^0.5 * (failureList[i].DegradationProbability)^0.5 * 67.6
        else
            FFC[6] += C1_2_3_4_6_7_8_9multiplier^0.5 * failureList[i].DegradationProbability * 62.4
        end
    end
#########################

    stations = EquipmentInitialisation(T, nbVec, requiredTimeForMaintenances)
######## C5 ########
    FFC[7] = -500
    for s in stations
        for e in s.Equipments
            for f in e.Failure
                λ = 0 
                λ += f.DegradationProbability
                if λ > 0.1
                    FFC[7] += λ^0.25 * 1100/(e.EquipmentRedondancy^0.75 * nbVec[18])
                elseif λ > 0.05
                    FFC[7] += λ^0.5 * 1000/(e.EquipmentRedondancy^0.75 * nbVec[18])
                else
                    FFC[7] += λ * 900/(e.EquipmentRedondancy^0.75 * nbVec[18])
                end
            end
        end
    end
####################                
    FFCT = UnavailSimulator(FFC, stations, ϕ, x, seed, Interrupter, timer, clk, C1_2_3_4_6_7_8_9multiplier, PG, nbVec, s, availInterrupter, N, AnyParamForInterrupter, single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler, AnyParamForSubSampler, first_s_to_one)   

    FFC = FFCT[1:11]
    timer = FFCT[12]
    N = FFCT[13]
    ϕ = FFCT[14]           
    logTime(timer, loggingTime)
    logN(N, loggingN)
    logPhi(ϕ, loggingPhi)

    #uncomment the one you need
    #return FFC             # return a vector [count_eval, f, [C]]
    str = join(FFC, " ")
    return str              # return the same vector but as a string without "[", "]" or "," (used for NOMAD solver)
end

GC.gc()
