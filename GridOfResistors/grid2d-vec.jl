# grid2d.jl - Grid of Resistors problem in two dimensions

n     = length(ARGS) >= 1 ? int(ARGS[1]) : 1000
niter = length(ARGS) >= 2 ? int(ARGS[2]) : 10

mu = (cos(pi/(2n))+cos(pi/(2n+1)))/2
om = 2(1-sqrt(1-mu^2))/mu^2

v = zeros(2n+1,2n+2)

ie = 2:2:2n
io = 3:2:2n-1
je = 2:2:2n
jo = 3:2:2n+1

tic()
for k = 1:niter
    v[ie,je] = (1-om)*v[ie,je] + om*0.25(v[ie+1,je]+v[ie-1,je]+v[ie,je+1]+v[ie,je-1])
    v[io,jo] = (1-om)*v[io,jo] + om*0.25(v[io+1,jo]+v[io-1,jo]+v[io,jo+1]+v[io,jo-1])
    v[n+1,n+1] = v[n+1,n+1]+0.25om

    v[ie,jo] = (1-om)*v[ie,jo] + om*0.25(v[ie+1,jo]+v[ie-1,jo]+v[ie,jo+1]+v[ie,jo-1])
    v[io,je] = (1-om)*v[io,je] + om*0.25(v[io+1,je]+v[io-1,je]+v[io,je+1]+v[io,je-1])
    v[n+1,n+2] = v[n+1,n+2]-0.25om

    r = 2v[n+1,n+1]
    println("Iter = $k, r = $r")
end
tottime = toq();

println("Time/iteration = $(tottime/niter) s")
