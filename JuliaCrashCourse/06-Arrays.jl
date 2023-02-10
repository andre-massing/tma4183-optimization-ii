##  Creating arrays

# Creates an array of Int64
squares = [x^2 for x in 1:8]

# If we later rather want to treat them as float we can use
# use on of the Float types available in Julia
squares_float = Float64[x^2 for x in 1:1e8]

# Access the first element
squares[1]

# Alternatively, you can use the keyword end
squares[begin]

# Acess the last element
squares[end]

# Get a slices containing everything from the 3th to 9th element
# using a range object and 1 (via broadcasting +=) 
squares[begin+2:end-1] .+= 1

# An more complicated slice
squares[2:2:end-2]

# You can also use an array of indices to slice the array
squares[[1, 3, 7]]

# Slices (as in Python) provide a view to the content of your array 
# and you can use them to manipulate your data.
squares[[1, 3, 7]] .+= 1

# type of squares
typeof(squares)

##  Now we have a look at different array type

# List with comma-separated items gives a Vector of Int64 written
# Vector{Int64} which is just an alias for a rank one Array{Int64,1} 
# stored in column format.
cubes = [1, 8, 27, 64, 125, 216, 343, 512]

# The same list WITHOUT A COMMA generates a HORIZONTAL vector.
# As the array storage format i column-oriented in Julia
# the result type is an 1x8 Matrix{Int64}
# Note that Matrix{T} is just an alias for Array{T, 2}
cubes_hor = [1 8 27 64 125 216 343 512]
typeof(cubes_hor)

# Vertical concatenation perform with ;
# So you can easily write matrices with several rows using ;
[1 2 3; 1 4 6]

# which is the same as if you write the various rows literally in different rows
[1 2 3
  1 4 6]

# You can generally verticaly stack arrays using V;
[1:8; squares; cubes]
# or use vcat
vcat(1:8, squares, cubes)

# But don't use `,` trying to stack them horizontally 
# This will you only give a list of lists
[1:8, squares, cubes]

# Instead use no separators as above
powers = [1:8 squares cubes]
# or hcat
hcat(1:8, squares, cubes)

# You can access elements of a matrix via 
powers[2, 3]

##  Fancier slicing

# Extract 2nd column 
powers[:, 2]

# and  3rd row
powers[3, :]

# Extract row 1, 3, 8
powers[[1, 3, 8], :]

# Extract row 1, 3, 8 and column 1 and 3
powers[[1, 3, 8], [1, 3]]

## Some useful functions and operations when you work with arrays and alike

# Create a sequence of float numbers  via range and them collect them into an array
midpoints = collect(1.5:2:11)

fib = [1, 1, 2, 3, 5, 8, 13]

# Function names are probably self-explanatory :)
push!(fib, 21)

push!(fib, fib[end] + fib[end-1])

# Removes last element and returns it
popped = pop!(fib)

poppedfirst = popfirst!(fib)

pushfirst!(fib, 1)

# You can also append or prepend collections of items instead of single items
evens = collect(2:2:10)
odds = collect(1:2:10)
append!(odds, evens)
print(evens)
print(odds)

# If you want to delete or insert something at an arbitrary position you can use
deleteat!(evens, 4)
deleteat!(evens, 1:2)

# Remove all even elements we added to odds earlier
deleteat!(odds, findall(x -> x % 2 == 0, odds))

# You can also insert items
evens = collect(2:2:10)
deleteat!(evens, 2)
print(evens)
insert!(evens, 2, 40)
print(evens)

# You can also reshape arrays (which returns a reshaped copy)
evens = collect(2:2:10)
odds = collect(1:2:10)
evens_odds = [evens odds]
reshape(evens_odds, (2, 5))

# IMPORTANT: Recall that Julia stores arrays one column at a time.
# 
# So when you e.g. write loops over large array, you iterate over
# arrays via column-major loops in order to get the best performance.
# More information about fast indexing of multidimensional arrays
# inside nested loops can be found at 
# https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-column-major
#
# Let's have a look at some examples to illustrate this important point.

A = fill(0.5, (10000, 10000))

# Most inner loop goes iterates throug column elements
num_rows, num_cols = size(A)

@time for j in 1:num_cols, i in 1:num_rows
  A[i, j] = 1.0
end

@time for i in 1:num_rows, j in 1:num_cols
  A[i, j] = 1.0
end

function set_ones_per_col(A)
  num_cols = size(A)[2]
  for i in 1:num_cols
    A[:, i] .= 1.0
  end
  A
end

function set_ones_per_row(A)
  num_rows = size(A)[1]
  for i in 1:num_rows
    A[i, :] .= 1.0
  end
  A
end

# Exercise: Lookup the doc on @elapsed
@elapsed set_ones_per_col(A)

@elapsed set_ones_per_row(A)

@elapsed A[:, :] .= 1.0

## Creating and filling arrays

# Create a 2x3 matrix filled with random Integers
rand(Int64, (2, 3))

#  or Floats between 0 and 1
rand(Float64, (2, 3))

# Short-cut for that is
rand(2, 3)

# Create arrays of ones or zeros
ones(5, 10)
zeros(5, 10)

# or your favorite number
pis = fill(3.1415, (3, 4))
pis = fill(π, (3, 4))

# which gives you a matrix of Irrational 
# But how can we turn that into a mattrix of floats?
pis = fill(convert(Float64, π), (3, 4))

# If you want to create an empty 3x4 matrix of e.g. Strings you can use
undef_mat = Array{String}(undef, 3, 4)

# and then set it to same value via broadcasting
undef_mat[:, :] .= "Hello Word"