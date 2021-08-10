@def title = "More on FP"
@def hascode = true

# More on FP

\toc

## Function Currying
A function (per the mathematical definition) typically takes in only one value and returns one value.
However, we often have to write functions that take in multiple parameters. One way this can be done,
is by building these functions that take in multiple parameters using functions take take in single
parameters. In other words, we will build a _n_-ary function using a sequence of _n_ unary functions.
This technique is known as _currying_, and the unary functions are known as a sequence of _curried_
functions.

```julia
add = (x, y) -> x + y
# Alternatively
new_add = x -> y -> x + y
```

In the above example, we rewrote the function `add` which was a function that takes in two parameters
`x` and `y`, into a function `new_add` that takes in a single parameter `x` and returns another function.
To call them, we would do:

```julia-repl
julia> add(1, 3)
4

julia> new_add(1)(3)
4
```

Again, this is possible since functions in julia are first-class objects, as we have seen in the [previous
section](../functions).

Currying allows us to partially apply our functions since we only accept one parameter at a time, and is
useful when we may not have all the parameters required for complete evaluation. It also allows for greater
reuse of code, if the same parameters are used for different evaluations. In the example above, I can define
`f = new_add(1)`, which is a function I can call which will add the value of 1 and any subsequent parameter
I provide.

However, unlike actual FP languages like Haskell where all functions are considered curried by default, in
Julia we need to explicitly define functions that are meant to be curried like in the example above. I cannot
just call `add(1)` or `add(1)(2)` and expect it to work.

## Piping in Julia
Julia provides the `|>` or _pipe_ operator, which allows functions to be combined by chaining them together
sequentially. The Julia documentation [here](https://docs.julialang.org/en/v1/manual/functions/#Function-composition-and-piping)
shows a simple example of this:

```julia
julia> 1:10 |> sum |> sqrt
7.416198487095663
```

In the example above, we take a `UnitRange` representing the numbers 1 to 10, apply the function `sum` to
obtain the sum of the numbers, and apply `sqrt` on that result to obtain it's square root. What we are doing
is we are applying a function, the the output of the previous function. This is similar to how you would compose
a function using ∘ or `ComposedFunction`. In fact, you can broadcast the operations using Julia's dot syntax.[^1]

```julia
julia> 1:10 .|> sqrt |> sum
22.4682781862041
```

Now instead of take the square root of the sum from 1 to 10, we are taking the sum of the square roots
of 1 to 10.

The limitation of the `|>` operator is that it does not work with functions that take in multiple arguments,
which prevents us from doing partial application of functions. There are some packages that try to introduce
this functionality such as [Pipe.jl](https://github.com/oxinabox/Pipe.jl) and [Lazy.jl](https://github.com/MikeInnes/Lazy.jl).

## Closures in Julia
```julia
function f(x)
    g = y -> x + y
    return g
end

c = f(1)
```

The function `f` in the example above returns another function `g`. However, notice that the function `g` actually
uses the variable `x`, which is outside the scope of `g`. The variable `x` is captured by `g`. We can see this
for `c`, which is a function which has a non-local variable `x` bound to the value 1. We call `c` a closure.
In Julia, a closure is a callable object[^2], usually a function, with field names corresponding to captured variables.

Closures allow us to store information about the environment where the closure is defined, and use them later. This
increases the amount of code re-use, and can allow us to represent the state of the environment. In the example below,
we use the function `save_state` to create a closure that allows us to save the value of the global variable `state`
at different points of the program. 

```julia
state = 0

function save_state()
    x = state
    return () -> x
end
a = save_state();
state = 5;
b = save_state();
state = 7;
c = save_state();
```

And we can see that the values of calling `a`, `b` and `c` correspond to the value of `state` when it was created:

```julia-repl
julia> a()
0
julia> b()
5
julia> c()
7
```

In fact, we can implement OOP like functionality in Julia[^3], at the cost of referential transparency:

```julia
function Dog(name, weight)
    get_name = () -> name
    get_weight = () -> weight
    eat_food = x -> weight += x
    return () -> (get_name, get_weight, eat_food)
end
```

Here the function `get_weight` mutates the `weight` variable, so the function `eat_food` is not a pure function.

```julia-repl
julia> dog = Dog("Johnny", 20);
julia> dog.get_name()
"Johnny"
julia> dog.get_weight()
20
julia> dog.eat_food(1)
21
julia> dog.get_weight()
21
```

## Some other interesting things in Julia
In Julia, operators such as `+`, `-`, `*`, `/`, `<`, `==` (and many others) are functions. For example, to sum two
numbers we could just do `+(1, 2)` instead of `1 + 2`. Several operators such as `+` and `*` can even accept multiple
arguments: `*(3, 4, 5)` is a valid statement.

Comparison operators such as `<`, `<=`, `>`, `>=`, `==` and `===` can be partially applied, by first supplying it
with the "left" side of the operation.

```julia-repl
julia> eq_5 = ==(5);
julia> eq_5(1)
false
julia> eq_5(5)
true

julia> lt_8 = <(8);
julia> lt_8(2)
true
julia> lt_8(9)
false
```

[^1]: The dot syntax in Julia makes use of broadcasting to allow us to easily create vectorised functions from unary functions, without the need to have a separate implementation.
[^2]: Julia has function-like objects, allowing instances of composite types to be called like functions by adding methods to the type itself. (Not be confused with functors in FP.)
[^3]: The use of closures may affect performance of captured variables. See [here](https://github.com/JuliaLang/julia/issues/15276).

