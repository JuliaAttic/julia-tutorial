require("Optim")
using Winston

@everywhere busytime = Array((Float64,Float64),0)

# f_i(x) = 0.5(x-i)^2
# returns subderivative in the form 
# (a,b) -> ax' + b = f'(x)*x' + (f(x)-x*f'(x)) (from f(x) + f'(x)(x'-x))
@everywhere function f(input)
    x,i = input
    t = time()
    #sleep(0.56)
    sleep(max(0.1,0.2+1*randn())) # simulate computation time
    push!(busytime,(t,time()))
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

function staticmapversion(N::Integer)
    cur = [1/N]
    subderivatives = Array(Vector{(Float64,Float64)},N)
    for i in 1:N
        subderivatives[i] = Array((Float64,Float64),0)
    end
    niter = 0
    while abs(cur[1]-(N+1)/2) > 1e-4
        for (i,result) in enumerate(Base.pmap_static(f,[(cur[1],i) for i in 1:N]))
            push!(subderivatives[i],fetch(result))
        end
        modelresults = Optim.optimize(x->evalmodel(x[1],subderivatives),cur)
        #println("Model obj: ", modelresults.f_minimum)
        println("Model x: ", modelresults.minimum)
        cur = modelresults.minimum
        niter += 1
        

    end
    println("Converged in $niter iterations")

end

function pmapversion(N::Integer)
    cur = [1/N]
    subderivatives = Array(Vector{(Float64,Float64)},N)
    for i in 1:N
        subderivatives[i] = Array((Float64,Float64),0)
    end
    niter = 0
    mastertime = 0.
    while abs(cur[1]-(N+1)/2) > 1e-4
        results = pmap(f,[(cur[1],i) for i in 1:N])
        for i in 1:N
            push!(subderivatives[i],results[i])
        end
        t = time()
        modelresults = Optim.optimize(x->evalmodel(x[1],subderivatives),cur)
        mastertime += time() - t
        #println("Model obj: ", modelresults.f_minimum)
        println("Model x: ", modelresults.minimum)
        cur = modelresults.minimum
        niter += 1
        points = linspace(0,N,200)
        modelval = map(x->evalmodel(x,subderivatives),points)
        fval = map(x->sum([0.5(x-i)^2 for i in 1:N]),points)
        p = FramedPlot()
        add(p, Curve(points,modelval))
        add(p, Curve(points,fval,"type","dash"))
        file(p, "iter$niter.pdf")
    end
    println("Converged in $niter iterations, mastertime: $mastertime")

end

function asyncversion(N::Integer,asyncparam::Float64)
    np = nprocs() 
    cur = [1/N]
    subderivatives = Array(Vector{(Float64,Float64)},N)
    for i in 1:N
        subderivatives[i] = Array((Float64,Float64),0)
    end
    converged = false
    set_converged() = (converged = true)
    is_converged() = (converged)
    mastertime = 0.
    nmaster = 0
    increment_mastertime(t) = (mastertime += t; nmaster += 1)
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
                push!(subderivative[mytask[2]],result)
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
                    t = time()
                    modelresults = Optim.optimize(x->evalmodel(x[1],subderivatives),cur)
                    increment_mastertime(time() - t)
                    #println("Model obj: ", modelresults.f_minimum)
                    println("Model x: ", modelresults.minimum)
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
    println("Converged in $nmaster master solves, $(sum(nback)) subproblem evaluations of f, mastertime: $mastertime")
end




time0 = time()
#@time staticmapversion(100)
@time pmapversion(100)
#@time asyncversion(100,0.9)

# gather busy intervals from each process and plot
if nprocs() > 1
    busytimes = [ remote_call_fetch(p,()->busytime) for p in 1:nprocs() ]
    p = FramedPlot()
    for i in 1:nprocs()
        for (starttime,endtime) in busytimes[i]
            add(p, Curve([starttime-time0,endtime-time0],[i,i]))
        end
    end

    setattr(p.frame, "draw_axis", false)
    setattr(p.y1, "ticks", [float(i) for i in 2:nprocs()])
    setattr(p.x1, "ticks", [0.])
    setattr(p.x1, "ticklabels", [""])
    setattr(p.x1, "range", (0.,45.)) # adjust as necessary
    file(p, "activityplot.pdf")
end


