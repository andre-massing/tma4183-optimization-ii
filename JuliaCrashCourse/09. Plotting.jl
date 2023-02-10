# # Plotting
#
# ## Basics
# There are a few different ways to plot in Julia (including calling PyPlot). <br>
#
# Here we'll show you how to use `Plots.jl`.  If it's not installed yet, you need to use the package manager to install it, and Julia will precompile it for you the first time you use it:

## using Pkg
## Pkg.add("Plots")
using Plots

# One of the advantages to `Plots.jl` is that it allows you to seamlessly change backends. In this notebook, we'll try out the `gr()` and `plotlyjs()` backends.<br>
#
# In the name of scientific inquiry, let's use this notebook to examine the relationship between the global temperature and the number of pirates between roughly 1860 and 2000.

globaltemperatures = [14.4, 14.5, 14.8, 15.2, 15.5, 15.8]
numpirates = [45000, 20000, 15000, 5000, 400, 17]

# Plots supports multiple backends — that is, libraries that actually do the drawing — all with the same API. To start out, let's try the GR backend.  You choose it with a call to `gr()`:

gr()

# and now we can use commands like `plot` and `scatter` to generate plots.

p = plot(numpirates, globaltemperatures, label="line")
scatter!(p, numpirates, globaltemperatures, label="points")

# The `!` at the end of the `scatter!` function name makes `scatter!` a mutating function, indicating that the scattered points will be added onto the pre-existing plot.
#
# In contrast, see what happens when you replace `scatter!` in the above with the non-mutating function `scatter`.
#
# Next, let's update this plot with the `xlabel!`, `ylabel!`, and `title!` commands to add more information to our plot.

xlabel!("Number of Pirates [Approximate]")
ylabel!("Global Temperature (C)")
title!("Influence of pirate population on global warming")

# This still doesn't look quite right. The number of pirates has decreased since 1860, so reading the plot from left to right is like looking backwards in time rather than forwards. Let's flip the x axis to better see how pirate populations have caused global temperatures to change over time!

xflip!()

#-

# ## 3d plots
# Exercise: add Plotly package to your environment
# plotlyjs()

gr()
# ## Plot in 3d
xs = collect(0.1:0.05:2.0)
ys = collect(0.2:0.1:2.0)
X = [x for x = xs for _ = ys]
Y = [y for _ = xs for y = ys]
Z = ((x, y)->begin
            1 / x + y * x ^ 2
        end)
surface(X, Y, Z.(X, Y), xlabel = "longer xlabel", ylabel = "longer ylabel", zlabel = "longer zlabel")




# And there we have it!
#
# Note: We've had some confusion about this exercise. :) This is a joke about how people often conflate correlation and causation.
#

# ### Exercises

# #### 8.0 (preparation)
#
# 1. `] instantiate` or `import Pkg; Pkg.instantiate()`
# 2. `using Plots`
# 3. `gr()`

# #### 8.1
# Given
# ```julia
# x = -10:10
# ```
# plot y vs. x for $y = x.^2$.  You may want to change backends back again.


 
# #### 8.2
# Execute the following code

x = -10:10
p1 = plot(x, x)
p2 = plot(x, x.^2)
p3 = plot(x, x.^3)
p4 = plot(x, x.^4)
plot(p1, p2, p3, p4, layout = (2, 2), legend = false)

# and then create a $4x1$ plot that uses `p1`, `p2`, `p3`, and `p4` as subplots.
m, n = 3, 4
plots = []
for i = 1:m*n
    p = plot(x, x.^i)
    push!(plots, p)
end
plot(plots..., layout = (m, n), legend = false)
