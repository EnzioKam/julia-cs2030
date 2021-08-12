@def title = "Immutability"
@def hascode = true

# Functions

\toc

## Pure Functions

### Side Effects

Ideally, functions in our programs should behave the same as functions in mathematics. For a particular
input, a pure function should compute and return an output, and do nothing else. There should be no
side effects -- writing to files, printing to standard output, mutate other variables or arguments,
or throwing exceptions / errors.

Functions in Julia cannot be pure by default, since they can alter and be affected by the global state
of the program. Furthermore, they can be called on any parameter type if there are no type annotations
for the parameters, and they can possibly return any type if there are no type annotations for the
return value. However, with type annotations we can try to make the functions we define act like pure
functions.

Let's look at some examples of pure functions:

```julia
function square(x::Int)
    return x * x
end

function add(x::Int, y::Float64)
    return x + y
end
```

And some non-pure functions:

```julia
# May throw exception if y is not a number.
# Annoate y's type to make it pure.
function divide(x::Int, y)
    return x / y
end

# count is a global variable, may give different results
# for the same x. Note how there is no global keyword.
function increase_count(x)
    return count + i
end

# Does not return a value and mutates count.
# The global keyword is required to mutate it.
function incrCount(int i)
    global count
    count += i
    return nothing
end

# The array is mutated.
function add_to_array!(array, x)
    append!(array, x)
end
```

Notice that for `add_to_array!`, the function has a `!` at the end of it's name. In Julia, it is the convention
that functions that will modify their arguments have a `!` at the end of their name. Some examples in
`Base` include `empty!` and `push!`.[^1]

With our composite types being immutable by default, it makes it easier for us to define functions that
have no side effects!

### Referential Transparency

Another property of pure functions is referential transparency. An expression is called referentially transparent
if it can be replaced with its corresponding value (and vice-versa) without changing the program's behavior.
That is, if I have $f(x) = y$, I should be able to replace all occurrences of $f(x)$ with $y$.

This means we want the function to be _deterministic_ - it should produce the same output for a particular input
__every single time__. For example, the following is not deterministic:

```julia
# Returns a random integer in the range [x, y]
function get_range(x::Int, y::Int)
    return rand(1:5)
end
```

The function `get_range` is not pure since we cannot ensure that it will always give the same result. Functions
that give random results or depend on some other state that is not dependent on the parameters of the function
are not pure functions.

The use of pure functions by applying and composing them to build a program is the core of functional programming.
Examples of functional programming languages include Haskell, OCaml, Erlang, Clojure, F#, and Elixir. Julia
is not a functional programming language, but we can emulate some of the constructs commonly found in
functional programming languages.

## Functions as First-Class Objects in Julia

Functions in Julia are first-class objects: they can be assigned to variables, and called using the standard
function call syntax from the variable they have been assigned to. They can be used as arguments to other
functions, can be used as another function's return value, and they can be created anonymously.

```julia-repl
julia> a = () -> "Hello World";
julia> a()
"Hello World"

julia> function make_hw(func)
           return func
       end
make_hw (generic function with 1 method)

julia> make_hw(a)
#7 (generic function with 1 method)

julia> make_hw(a)()
"Hello World"
```

We see in the first line of code above that a function is initialised without any parameters, represented by
`()`, which returns a string, and is assigned to the variable `a`. This is an example of an anonymous function,
since there is no name associated to it in the Julia namespace. Another example would be `(x, y) -> x + y`,
which is a anonymous function that takes in two parameters and returns their sum. The rest of the example
shows how the function `make_hw` takes in a function as a parameter, outputs the function as the return value,
and how the function can be evaluated.

An example of how to make use of the fact that functions are first-class objects is in sorting, when we may want
to compare elements of an array, but not use their natural or predefined ordering.

```julia-repl
julia> names = ["john", "adam", "sam", "david", "jane", "mary"];
julia> sort(names)
6-element Vector{String}:
 "adam"
 "david"
 "jane"
 "john"
 "mary"
 "sam"

julia> sort(names, by = x -> x[3])
6-element Vector{String}:
 "adam"
 "john"
 "sam"
 "jane"
 "mary"
 "david"
```

In the second `sort` call, we specify an anonymous function for the parameter `by`, which makes the sort
compare the elements of the array based on the third character of each element.

Even if the ordering is not defined, we can still sort composite types by supplying a comparison function
to the `lt` parameter:

```julia-repl
julia> pts = [Point(1.5, 2.5), Point(1.7, -5.1), Point(-3.0, 7.2)];

julia> sort(pts, lt = (a, b) -> a.x < b.x)
3-element Vector{Point}:
 Point(-3.0, 7.2)
 Point(1.5, 2.5)
 Point(1.7, -5.1)
```

## Some comparisons with Java

The way Java implemented functions to be first-class was through functional interfaces.[^2] By specifying
a single abstract method to be overriden when implementing the interface. Examples of this include
`Comparator` and it's `compare` method and `Function` and it's `apply` method.

```julia
Function<Integer, Integer> add1 = new Function<>() {
    @Override
    public Integer apply(Integer t) {
        return t + 1;
    }
};
Function<Integer, Integer> add3 = new Function<>() {
    @Override
    public Integer apply(Integer t) {
        return t + 1;
    }
};
Function<Integer, Integer> composed = add1.compose(add3);
Integer result = composed.apply(0);
```

The above example shows how we can implement function composition in Java. With lambda expressions from
Java 8 onwards, we can shorten this to:

```julia
Function<Integer, Integer> add1 = x -> x + 1;
Function<Integer, Integer> add3 = x -> x + 3;
Function<Integer, Integer> composed = add1.compose(add3);
Integer result = composed.apply(0);
```

The equivalent in Julia would be the following:

```julia
add1 = x -> x + 1
add3 = x -> x + 3
composed = add1 ∘ add3
# Alternatively
composed = ComposedFunction(add1, add3)
result = composed(0)
```

The Julia version looks very similar to the Java version using lambda expressions. Personally, I dislike
the fact that I have to always go through the functional interface in Java. Also, we are still limited by
the type system in Java. `add1` will work on `Float64` in Julia, but `add1` cannot work on `Double` in Java,
which is (at least to me) quite counterintuitive since you would expect `x -> x + 1` to work for all numbers.
(Which is why I prefer Julia's type conversion using annotations over Java's type declaration, especially for
function parameters.) There is also the issue of Java generics not working on primitives, which leads to the
use of wrapper types like `Integer` and `Double`.

Julia's disadvantage comes from that fact that type mismatches can only be caught at runtime.

```julia
# Julia
function f(x, y) return x / y end
f("10", "5")

# Java
int f(int x, int y) { return x / y; }
f("10", "5")
```

In the above example, Java will detect the type mismatch at compile time, but Julia will only detect the type mismatch
when the statement `f("10", "5")` is executed.

[^1]: Note that in Julia, the `return` keyword is optional. Julia will return the result of the last statement whenever available, or return `nothing` if it cannot be found. In the example above, `add_to_array` will return the return value of `append!` - original array in the argument that has been modified.
[^2]: Of course, there are method references and anonymous inner classes. But the comparisons with that that can be another article on it's own.

