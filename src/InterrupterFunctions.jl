using Printf

#################################################################################################################################################
#=  Note: This function can be replaced by the user's function, you can do whetever that you want with the information given to the function   =#
#=        to decide wether or not you continue the iteration or not. Each element of the vector ϕ corespond to the fidelity level at which the =#
#=        value of the associated constraint or objective function of the vector FC was evaluated.                                             =#
#################################################################################################################################################

function TEST_Interrupter(ϕ, FC, str)
    io = open(str, "a")
    println(io, "$ϕ")
    println(io, "$FC")
    close(io)
    return true
end     

#=
the "basicInterrupter" function take a fidelity level vector, the objective function value and the constraint values and always return true, it is call to avoid dynamic interuption of the BB
    @Param ϕ: is a vector of fidelity levels at which the objective function and the constraints where evaluated
    @Param FC: is a vector containing the objective function value and the constraints values
    @Param str: is an unused parameter in this function, it is here to respect the function signature required by MicroPRIAD
=#
function basicInterrupter(ϕ, FC, str)
    return true
end

#=
the "printInterReturnConinueEval" function take a fidelity level vector, the objective function value and the constraint values and print them in a file "interReturnLog.txt" located in the MicroPRIAD main directory
    @Param ϕ: is a vector of fidelity levels at which the objective function and the constraints where evaluated
    @Param FC: is a vector containing the objective function value and the constraints values
    @Param str: is a Sting that can contain the path to the file where to print the information or the path to a file where to read the decision to continue or not the BB iteration
        if str == "": the file "interReturnLog.txt" located in the MicroPRIAD main directory is used to print the information
        if str contains only one word:
            if str contains ".txt": the file located at the path given by str is used to print the information
            else: the file "interReturnLog.txt" located in the directory given by str is used to print the information
        if str contains two words:
            first word:
                if it contains ".txt": the file located at the path given by the first word is used to print the information
                else: the file "interReturnLog.txt" located in the directory given by the first word is used to print the information
            second word: is the path to a file where to read the decision to continue or not the BB iteration, this file must contain a single boolean value (true or false)
                after reading this value, the content of this file is cleared
=#
function printInterReturnConinueEval(ϕ, FC, str)
    if (str == "")
        dir = @__DIR__
        splitDir = split(dir, "/") 
        newSplitDir = Vector{SubString}(undef, length(splitDir) - 1)
        for i in 1:(length(splitDir) - 1)
            newSplitDir[i] = splitDir[i]
        end
        newDir = join(newSplitDir, "/")
        io = open("$newDir/interReturnLog.txt", "a")
    write(io, @sprintf(
        "f(%5.4f) = %7.6e     \tC1(%5.4f) = %7.5f    \tC2(%5.4f) = %7.5f    \tC3(%5.4f) = %7.5f    \tC4(%5.4f) = %7.5f    \tC5(%5.4f) = %7.5f    \tC6(%5.4f) = %7.5f    \tC7(%5.4f) = %7.5f    \tC8(%5.4f) = %7.5f    \tC9(%5.4f) = %7.5f\n",
        ϕ[1], FC[1],
        ϕ[2], FC[2],
        ϕ[3], FC[3],
        ϕ[4], FC[4],
        ϕ[5], FC[5],
        ϕ[6], FC[6],
        ϕ[7], FC[7],
        ϕ[8], FC[8],
        ϕ[9], FC[9],
        ϕ[10], FC[10]
    ))
        if (ϕ[1] == 1.0)
            write(io, "\n \n")
        end
        close(io)
        return true
    else
        decision = true
        splitStr = split(str)
        if (length(splitStr) == 1)
            if contains(str, ".txt")
                io = open("$(str)", "a")
            elseif str[end] == "/"
                io = open("$(str)interReturnLog.txt", "a")
            else
                io = open("$(str)/interReturnLog.txt", "a")
            end
            write(io, @sprintf(
                "f(%5.4f) = %7.6e     \tC1(%5.4f) = %7.5f    \tC2(%5.4f) = %7.5f    \tC3(%5.4f) = %7.5f    \tC4(%5.4f) = %7.5f    \tC5(%5.4f) = %7.5f    \tC6(%5.4f) = %7.5f    \tC7(%5.4f) = %7.5f    \tC8(%5.4f) = %7.5f    \tC9(%5.4f) = %7.5f\n",
                ϕ[1], FC[1],
                ϕ[2], FC[2],
                ϕ[3], FC[3],
                ϕ[4], FC[4],
                ϕ[5], FC[5],
                ϕ[6], FC[6],
                ϕ[7], FC[7],
                ϕ[8], FC[8],
                ϕ[9], FC[9],
                ϕ[10], FC[10]
            ))
            if (ϕ[1] == 1.0)
                write(io, "\n \n")
            end
            close(io)
            return true
        elseif (length(splitStr) == 2)
            if contains(splitStr[1], ".txt")
                io = open("$(splitStr[1])", "a")
            elseif splitStr[1][end] == "/"
                io = open("$(splitStr[1])interReturnLog.txt", "a")
            else
                io = open("$(splitStr[1])/interReturnLog.txt", "a")
            end
            write(io, @sprintf(
                "f(%5.4f) = %7.6e     \tC1(%5.4f) = %7.5f    \tC2(%5.4f) = %7.5f    \tC3(%5.4f) = %7.5f    \tC4(%5.4f) = %7.5f    \tC5(%5.4f) = %7.5f    \tC6(%5.4f) = %7.5f    \tC7(%5.4f) = %7.5f    \tC8(%5.4f) = %7.5f    \tC9(%5.4f) = %7.5f\n",
                ϕ[1], FC[1],
                ϕ[2], FC[2],
                ϕ[3], FC[3],
                ϕ[4], FC[4],
                ϕ[5], FC[5],
                ϕ[6], FC[6],
                ϕ[7], FC[7],
                ϕ[8], FC[8],
                ϕ[9], FC[9],
                ϕ[10], FC[10]
            ))
            while(true)
                io_decision = open("$(splitStr[2])", "r")
                decision_str = readlines(io_decision)
                close(io_decision)
                decision_str = String(decision[end])
                if (decision_str != "")
                    decision = "$(parse(Bool, decision_str))"

                    clear_io_decision = open("$(splitStr[2])", "w")
                    close(clear_io_decision)
                    break
                end
            end

            if (ϕ[1] == 1.0)
                write(io, "\n \n")
            end
            close(io)
            return decision
        end
    end
end

#=
the "DeterministicInfoInterrupter" function take a fidelity level vector, the objective function value and the constraint values and return false if one of the five deterministic constraints is violated, true otherwise
    @Param ϕ: is a vector of fidelity levels at which the objective function and the constraints where evaluated
    @Param FC: is a vector containing the objective function value and the constraints values
    @Param str: is an unused parameter in this function, it is here to respect the function signature required by MicroPRIAD
=#
function DeterministicInfoInterrupter(ϕ, FC, str)
    if any(FC[2:6] .> 0)
        return false
    end
    return true
end


#=
the "feasiblePtsFinderInterrupter" function take a fidelity level vector, the objective function value and the constraint values and decide to continue or not the BB iteration based on statistical analysis of the constraints values
        if the deterministic constraints are violated, the function return false
        if the number of samples is less than N_min, the function return true
        for each stochastic constraint, a confidence interval is computed at the confidence level 1 - α
        if the lower bound of one of these confidence intervals is greater than 0, the function return false
    otherwise, the function return true
    @Param ϕ: is a vector of fidelity levels at which the objective function and the constraints where evaluated
    @Param FC: is a vector containing the objective function value and the constraints values
    @Param str: is a Sting that can contain the path to the directory where to log the data and the confidence level α separated by a space
        if str == "": the current directory is used to log the data and α = 0.05
        if str contains only one word:
            if "/" ∈ str: the directory given by str is used to log the data and α = 0.05
            else: the current directory is used to log the data and α = parse(Float64, str)
        if str contains two words:
            first word: is the directory where to log the data
            second word: is α = parse(Float64, second word)
=#
function feasiblePtsFinderInterrupter(ϕ, FC, str)
    splitStr = split(str)
    if length(splitStr) == 0
        dir = @__DIR__
        α = 0.05
    elseif length(splitStr) == 1 && "/" ∈ splitStr[1]
        dir = splitStr[1]
        α = 0.05
    elseif length(splitStr) == 1 && !("/" ∈ splitStr[1])
        dir = @__DIR__
        α = parse(Float64, splitStr[1])
    elseif length(splitStr) == 2
        dir = splitStr[1]
        α = parse(Float64, splitStr[2])
    end

        
    ########################### static variables ########################################
    Zα  = Matrix{Float64}(undef, 2, 12)
    Zα[1, :] = [0.0001, 0.00025, 0.0005, 0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1,  0.15,  0.2]
    Zα[2, :] = [3.91,   3.66,    3.48,   3.29,  3.02,   2.81,  2.58, 2.24,  1.96, 1.65, 1.44, 1.28]
    global last_FC = Vector{Float64}(undef, 10)
    global N_MAX = 10000 
    global N_min = 30
    global data  = Matrix{Float64}(undef, N_MAX, 10)                                                                                       
    global Z_val = Zα[2, findfirst(x -> x == α, Zα[1, :])]
    #####################################################################################

    n =  Int64(round(ϕ[1]*10000))
    for i in 1:10
        if ϕ[i] == 0.0001
            data[1,i] = FC[i]
        else
            data[n,:] =  n*FC - (n-1)*last_FC
        end
    end
    global last_FC = FC

    cVec = FC[2:end]
    for c in 1:5
        if cVec[c] > 0

            io  = open("$dir/loggingData.txt", "a")
            strData = join(data[n,:], " ")
            write(io, "FFC = $(strData) at phi = $(ϕ[1])\n")
            close(io)


            return false
        end
    end

    if n < N_min
        return true
    end

    for c in 6:9
        mean_c = cVec[c]
        std_c = std(data[1:n, c])
        println("c[$c] ∈ [ $(mean_c - Z_val * (std_c / sqrt(n))) ; $(mean_c + Z_val * (std_c / sqrt(n))) ] at ϕ = $(ϕ[1])")
        if mean_c - Z_val * (std_c / sqrt(n)) > 0

            io  = open("$dir/loggingData.txt", "a")
            write(io, "$(data[1:n])\n")
            write(io, "$FC \n")
            close(io)

            return false
        end
    end
    return true
end

