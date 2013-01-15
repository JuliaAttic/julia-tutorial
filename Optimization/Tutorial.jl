require("Optim")

# f_i(x) = 0.5(x-i)^2
# returns subderivative in the form 
# (a,b) -> ax' + b = f'(x)*x' + (f(x)-x*f'(x)) (from f(x) + f'(x)(x'-x))
function f(input)
    x,i = input
    sleep(max(0.1,0.2+1*randn())) # simulate computation time
    return ((x-i),0.5(x-i)^2-x*(x-i))
end

function evalmodel(x, subderivatives::Vector{Vector{(Float64,Float64)}})
    N = length(subderivatives)
    if 0 <= x <= N
        modelval = 0.
        for i in 1:length(subderivatives) # for each f_i
            maxval = -Inf
            for (a,b) in subderivatives[i] # for each stored subderivative of f_i
                maxval = max(a*x+b,maxval)
            end
            modelval += maxval
        end
        return modelval
    elseif x < 0 # repel away from here
        return -100000x+100000
    else
        return 100000x
    end
end

function cpserial(N::Integer)
    cur = [1/2]
    println("Solving model with n = $N, initial solution: $cur")
    println("Optimal solutuon should be $((N+1)/2)")
    subderivatives = Array(Vector{(Float64,Float64)},N)
    for i in 1:N
        subderivatives[i] = Array((Float64,Float64),0)
    end
    niter = 0
    while abs(cur[1]-(N+1)/2) > 1e-4 # we're cheating because we know the answer
        results = map(f,[(cur[1],i) for i in 1:N])
        for i in 1:N
            push!(subderivatives[i],results[i])
        end
        modelresults = Optim.optimize(x->evalmodel(x[1],subderivatives),cur)
        println("Model minimizer: ", modelresults.minimum)
        cur = modelresults.minimum
        niter += 1
    end
    println("Converged in $niter iterations")

end

function asyncversion(N::Integer,asyncparam::Float64)
    np = nprocs() 
    cur = [1/2]
    subderivatives = Array(Vector{(Float64,Float64)},N)
    for i in 1:N
        subderivatives[i] = Array((Float64,Float64),0)
    end
    converged = false
    set_converged() = (converged = true)
    is_converged() = (converged)
    nmaster = 0
    nback = Int[]
    didtrigger = Bool[]
    nsubproblems = 0
    increment_solved() = (nsubproblems += 1)
    tasks = Array((Float64,Int,Int),0)

    function pushtask(x)
        for i in 1:N
            push!(tasks,(x[1],i,nmaster+1))
        end
        push!(didtrigger, false)
        push!(nback, 0)
    end

    pushtask(cur)

    @sync for p in 1:np
        if p != myid() || np == 1
            @spawnlocal while !is_converged()
                if length(tasks) == 0
                    yield()
                    continue
                end
                mytask = shift!(tasks)
                result = remote_call_fetch(p,f,mytask[1:2])
                push!(subderivatives[mytask[2]],result)
                @assert length(nback) >= mytask[3]
                @assert length(didtrigger) >= mytask[3]
                nback[mytask[3]] += 1
                resolve = false
                if nback[mytask[3]] >= asyncparam*N && didtrigger[mytask[3]] == false
                    didtrigger[mytask[3]] = true
                    resolve = true
                #elseif nback[mytask[3]] == N
                #    resolve = true
                end
                if resolve
                    # generate new candidate point
                    modelresults = Optim.optimize(x->evalmodel(x[1],subderivatives),cur)
                    #println("Model obj: ", modelresults.f_minimum)
                    println("Model minimizer: ", modelresults.minimum)
                    cur[1] = modelresults.minimum[1]
                    if abs(cur[1]-(N+1)/2) <= 1e-4
                        println("Converged!")
                        set_converged()
                    else
                        pushtask(cur)
                    end
                end
            end
        end
    end
    println("Converged in $nmaster master solves, $(sum(nback)) subproblem evaluations of f")
end


@time cpserial(10)
