@def title = "Immutability"
@def hascode = true

# Immutability

\toc

We can deal with software complexity by encapsulating and hiding the complexity behind abstraction barriers,
by using a language with a strong type system and adhering to the subtyping substitution principle, and by
applying the abstraction principles and reusing code written as functions, classes, and parametric types.

Another useful strategy is to avoid change altogether. This can be done by creating instances of composite types using Julia's default `struct`, which is immutable. The created instance of the Composite type cannot have any visible changes outside its abstraction barrier. This means that every method called on the instance must behave the same way throughout the lifetime of the instance.

## Mutable Point and Circle

Let's first define two types, `Point` and `Circle`, and some related methods, but let `Point` and `Circle` be mutable.

```julia
mutable struct Point
    x::Float64
    y::Float64
end

mutable struct Circle
    centre::Point
    radius::Float64
end

function get_area(c::Circle)
    return π * c.radius^2
end

function contains(c::Circle, p::Point)
    return (p.x - c.centre.x)^2 + (p.y - c.centre.y)^2 < c.radius^2
end

function move_to(p::Point, x, y)
    p.x = x
    p.y = y
end

function move_to(c::Circle, x, y)
    move_to(c.centre, x, y)
end
```

There are many advantages of why we want to make our composite type immutable when possible.
Let's see what happens when we try to move only `c1`.

```julia
p = Point(0, 0)
c1 = Circle(p, 1)
c2 = Circle(p, 4)
move_to(c1, 1, 1)
```

Calling `move_to` on `c1` changes the center `Point` of both both `c1` and `c2`, since both `c1`
and `c2` sharing the same point.

```julia-repl
julia> @show c1
c1 = Circle(Point(1.0, 1.0), 1.0)
julia> @show c2
c2 = Circle(Point(1.0, 1.0), 4.0)
```

One way to avoid this is by creating two separate points for each `Circle`:

```julia
p1 = Point(0, 0)
c1 = Circle(p1, 1)
p2 = Point(0, 0)
c2 = Circle(p2, 4)
move_to(c1, 1, 1)
```

Now calling `move_to` on `c1` does not change the center `Point` of `c2`:

```julia-repl
julia> @show c1
c1 = Circle(Point(1.0, 1.0), 1.0)

julia> @show c2
c2 = Circle(Point(1.0, 1.0), 4.0)
```

By creating new instances, we avoid the two `Circle` instances sharing the same reference
to a single `Point` instance. This fix, however, comes with extra costs in computational
resources as the number of objects to increase rapidly.

## Immutable Point and Circle

We can make our `Point` and `Circle` types immutable by removing the `mutable` keyword in
the `struct` definition:

```julia
struct Point
    x::Float64
    y::Float64
end

struct Circle
    centre::Point
    radius::Float64
end
```

Now, you cannot reassign any of the fields after initialisation:

```julia-repl
julia> c = Point(1.0, 2.0)
Point(1.0, 2.0)

julia> c.x
1.0

julia> c.x = 1.5
ERROR: setfield! immutable struct of type Point cannot be changed
```

Concrete types in Julia also cannot be subtyped, which is somewhat equivalent to declaring a class
`final` in a language like Java.

```julia-repl
julia> struct Origin <: Point end
ERROR: invalid subtyping in definition of Origin
```

Now, let's redefine the `move_to` methods for `Point` and `Circle`:

```julia
function move_to(p::Point, x, y)
    return Point(x, y)
end

function move_to(c::Circle, x, y)
    return Circle(move_to(c.centre, x, y), c.radius)
end

p = Point(0, 0)
c1 = Circle(p, 1)
c2 = Circle(p, 4)
move_to(c1, 1, 1)
```

Now, neither `c1` nor `c2` are modified, even after `move_to` is called. To update `c1`, we will have
to reassign the newly created instance to it by calling `c1 = move_to(c1, 1, 1)`.

```julia-repl
julia> @show c1
c1 = Circle(Point(0.0, 0.0), 1.0)

julia> @show c2
c2 = Circle(Point(0.0, 0.0), 4.0)

julia> @show c1 = move_to(c1, 1, 1)
c1 = move_to(c1, 1, 1) = Circle(Point(1.0, 1.0), 1.0)
```

## Advantages of Immutability

### Ease of Understanding

Code written with immutable types is easier to reason with and easier to understand. Suppose
we create a `Circle` and assign it to a local variable `c`:

```julia
c = Circle(Point(1, 2), 3)
```

We can reuse `c` by passing it other methods or as fields of other composite types. These other methods
can invoke methods that dispatch on `c`. However since `c` is immutable, we can guarantee that c is still
a circle centered at `(1, 2)` with a radius of `3`. The immutability makes it significantly easier to read, understand, and debug our code.

If the `Point` and `Circle` types were immutable, we will have to check all methods that dispatch on `c`
to ensure that none of them modify `c`.

### Enabling Safe Sharing of Objects?

Unfortunately in Julia, there is not much equivalent to what Java has since there is no concept of a
"static field" in Julia. One possibility to get closer would be to use a global variable that is constant.

```julia
struct Point
    x::Float64
    y::Float64
end

function Point()
    return Point(0, 0)
end

const ORIGIN = Point()
```

The issue with this is that we replace the default constructor of `Point` with an inner constructor.
This means that we can still have statements that create Points from arbitrary coordinates.

An alternative (and maybe better?) way to do this is to define a wrapper type to handle different
initialisations of the underlying data. However, this will only work as part of a package, where
you can decide which types and functions you want to export for the end-user to use.

```julia
module Shapes

export Point

struct Data
    x::Float64
    y::Float64
end

struct Point
    p::Data
    function Point()
        return new(Data(0, 0))
    end
end

function Point(x, y)
    if x == 0 && y == 0
        return Point()
    else
        return Point(Data(x, y))
    end
end
```

### Enabling Safe Sharing of Internals

Let's consider a new `ImmutableArray` composite type below. Note that the inner constructor
for `ImmutableArray` takes in a variable number of arguments, which should be of type `T`.

```julia
# get is a default function in Base, needs to be imported
import Base.get

struct ImmutableArray{T}
    array::Vector{T}
    function ImmutableArray{T}(x...) where {T}
        return new{T}(collect(x))
    end
end

function get(a::ImmutableArray, index::Int)
    return a.array[index]
end
```

Suppose we want to implement a method called `subarray`, that returns a new ImmutableArray
containing the elements between two indices `left` and `right`. The naive way would be to
copy every element in this range into a new instance, which becomes expensive if we store
many elements. Instead, what we can do is use the same array by storing the `left` and
`right` indices.

```julia
struct ImmutableArray{T}
    array::Vector{T}
    left::Int
    right::Int
    function ImmutableArray(a::Vector{T}, l, r) where {T}
        return new{T}(a, l, r)
    end
end

function ImmutableArray{T}(x::T...) where {T}
    if length(x) == 0
        return ImmutableArray{T}(collect(x), 0, 0)
    else
        return ImmutableArray{T}(collect(x), 1, length(x))
    end
end

function get(a::ImmutableArray, index::Int)
    if index < 1 || a.left + index - 1 > a.right
        throw(BoundsError(a, index))
    end
    return a.array[a.left + index - 1]
end

function subarray(a::ImmutableArray{T}, left::Int, right::Int) where {T}
    return ImmutableArray{T}(a.array, a.left + left - 1, a.left + right - 1)
end
```