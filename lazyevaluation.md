@def title = "Lazy Evaluation"
@def hascode = true

# Lazy Evaluation

## Computation when required

Consider the following program:

```julia
mutable struct Message
    msg
    count
    function Message()
        return new("", 0)
    end
end

function add_sentence(t::Message, sentence::Function)
    if t.count >= 2
        t.msg *= sentence() * "\n";
    end
    t.count += 1
end

note = Message();
a = () -> "First Line | " * string(today())
b = () -> "Second Line | " * string(today())
c = () -> "Third Line | " * string(today())
```
Here, the composite type `Message` is mutable. The `add_sentence` method takes in a
`Message` and a function `sentence`, whose result is concatenated to the `msg` variable
if the count is greater than 2. `a`, `b` and `c` are all functions that return the string
expressions. The functions are not yet evaluated - we defer the evaluation of expressions
we do not need currently, and only evaluate them whenever required.

```julia-repl
julia> add_sentence(note, a);
julia> note.msg
""
julia> add_sentence(note, b);
julia> note.msg
""
julia> add_sentence(note, c);
julia> note.msg
"Third Line | 2021-08-12\n"
```

Now, our expression `string(today())` is only evaluated when the count is greater
or equals to 2, since the `sentence` argument of `add_sentence` is a function, and
is not evaluated when the count is less than 2. 

## Avoiding Repeated Computation

On top of deferring the evaluation, we can store the results of our computation to
prevent repeated computation.

```julia
mutable struct Lazy
    f::Function
    evaluated::boolean
    value
    function Lazy(f)
        return new(f, false)
    end
end

function getvalue(x::Lazy)
    if !x.evaluated
        t.value = t.f()
        t.evaluated = true
    end
    return t.value
end
```

For the `Lazy` composite type, only the first call of `getvalue` will result in an evaluation
of the function `f`. Any subsequent calls of `getvalue` will just retrieve the result stored
in the field `value`.

