# # Basic linear algebra in Julia
# Author: Andreas Noack Jensen (MIT) (http://www.econ.ku.dk/phdstudent/noack/)
# (with edits from Jane Herriman)

using LinearAlgebra

#-

# First let's define a random matrix

A = rand(1:4, (3, 3))

# Define a vector of ones

x = ones(3)

# Notice that $A$ has type Array{Int64,2} but $x$ has type Array{Float64,1}. Julia defines the aliases Vector{Type}=Array{Type,1} and Matrix{Type}=Array{Type,2}.
#
# Many of the basic operations are the same as in other languages
# #### Multiplication

b = A*x

# #### Transposition
# As in other languages `A'` is the conjugate transpose, or adjoint

A'

Z = A + A*im
Z'

# and we can get the (real) transpose with
transpose(A)

# but a complex-valued matrix we need to take the adjoint
adjoint(Z)

# #### Transposed multiplication
# Julia allows us to write this without *

A'A

# #### Solving linear systems
# The problem $Ax=b$ for ***square*** $A$ is solved by the \ function.

A \ b

# `A \ b` gives us the *least squares solution* if we have an overdetermined linear system (a "tall" matrix)

Atall = rand(3, 2)

#-

Atall \ b

# and the *minimum norm least squares solution* if we have a rank-deficient least squares problem

v = rand(3)
rankdef = hcat(v, v)
# Check the rank before we solve
rank(rankdef)

#-

rankdef \ b

# Julia also gives us the minimum norm solution when we have an underdetermined solution (a "short" matrix)

bshort = rand(2)
Ashort = rand(2, 3)

#-

Ashort \ bshort

# ## Dot products and row vectors

v = [1,2,3]
dot(v,v)
# More mathematical notations
v ⋅ v
v'v

# We distinguish "row vectors" from "row matrices"
rowmat = [1 2 3]
rowvec = [1,2,3]'

rowmat * v

rowvec * v


# ## Diagonals

# `diag` gives the diagonal of a matrix

diag(A)

# `diagm` constructs diagonal matrices

diagm(v)

# Though there is a much better way...

#-

# ### Exercises
#
# #### 10.1
# Take the inner product (or "dot" product) of a vector `v` with itself and assign it to variable `dot_v`.

v = [1,2,3]

# dot_v = 

#-

@assert dot_v == 14

# #### 10.2
# Take the outer product of a vector v with itself and assign it to variable `outer_v`

# outer_v = 
@assert size(outer_v) == (3, 3)
