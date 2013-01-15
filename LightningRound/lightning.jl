A = rand(5,5)
A[1,1]
rand(5,5)[1,1]

[ i for i=1:5 ]
[ trace(rand(n,n)) for n=1:5 ]
x = rand(10)
[ x[i]+x[i+1] for i=1:9 ]
{ eye(n) for n=1:5 }
[ i+j for i=1:5, j=1:5 ]

A = rand(5,6)
svd(A)
(u,s,v) = svd(A)
ndims(u), typeof(u)
ndims(s), typeof(s)

sgn(x) = x > 0 ? 1 : -1
sgn(x) = x > 0 ? 1 : x < 0 ? -1 : 0

im
typeof(2im)
typeof(2.0im)
complex(3,4)
complex(3,4.0)
sqrt(-1)
sqrt(complex(-1))

A = rand(5,5)
v = rand(5)
typeof(v)
typeof(1.0:5)
w = 1:5
A*w
A*[w]
ones(5)
eye(5)

run(`cal`)
run(`cal` | `grep Sa`)

ccall(:clock, Int32, ())
bytestring(ccall(:ctime, Ptr{Uint8}, ()))

Pkg.add("Calendar")
using Calendar
Calendar.now()
now()

n = now()
typeof(n)
n.tz
n.millis
z = convert(Array, @parallel [ Calendar.now().millis for x=1:10 ])
z - mean(z)

strang(n) = SymTridiagonal(2*ones(n),-ones(n-1))
lit = strang(500)
big = full(lit)
@time eigvals(lit)
@time eigvals(big)
big + big
lit + lit
import Base.+
xdump(lit)
+(a::SymTridiagonal,b::SymTridiagonal) = SymTridiagonal(a.dv+b.dv,a.ev+b.ev)
lit + lit

function stepbystep()
    for n=1:3
        produce(n^2)
    end
end
p = Task(stepbystep)
consume(p)
consume(p)
consume(p)
consume(p)

sqrt(-1)
anothersqrt(x) = x < 0 ? sqrt(complex(x)) : sqrt(x)
[ anothersqrt(x) for x=-2:3 ]
