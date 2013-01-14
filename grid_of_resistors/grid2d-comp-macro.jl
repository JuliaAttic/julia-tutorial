# grid2d.jl - Grid of Resistors problem in two dimensions

stencil(v,i,j,om) = (1-om)*v[i,j] + om*0.25*(v[i+1,j]+v[i-1,j]+v[i,j+1]+v[i,j-1])

macro sor_iter(I, J)
    quote 
        v[$I, $J] = [ stencil(v, i, j, om) for i=$I, j=$J ]
    end
end

function do_sor(n, niter)

v=zeros(2*n+1,2*n+2)

mu = (cos(pi/(2*n))+cos(pi/(2*n+1)))/2
om = 2*(1-sqrt(1-mu^2))/mu^2

tic()
for k=1:niter
  @sor_iter 2:2:2*n   2:2:2*n
  @sor_iter 3:2:2*n-1 3:2:2*n+1
  v[n+1,n+1] += om*0.25

  @sor_iter 2:2:2*n   3:2:2*n+1
  @sor_iter 3:2:2*n-1 2:2:2*n
  v[n+1,n+2]-=om*0.25

  r=2*v[n+1,n+1]
  println("Iter = $k, r = $r")
end
tottime = toc()
end

n=int(ARGS[1])
niter=10

tottime = do_sor(n, niter)
println("Time/iteration = $(tottime/niter) s")

