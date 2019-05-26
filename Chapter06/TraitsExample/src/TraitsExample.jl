module TraitsExample

export Residence, Stock, Money, Book,
 tradable, marketprice, 
 itradable, imarketprice

# Abstract type hierarchy for personal assets
abstract type Asset end

abstract type Property <: Asset end
abstract type Investment <: Asset end
abstract type Cash <: Asset end

abstract type House <: Property end
abstract type Apartment <: Property end

abstract type Bond <: Investment end
abstract type Equity <: Investment end

# Define concrete classes 
struct Residence <: House
    location
end

struct Stock <: Equity
    symbol
    name
end

struct Money <: Cash
    currency
    amount
end

# --------------------------------------------------------------------------------

# --- Liquidity traits ---

abstract type LiquidityStyle end
struct IsLiquid <: LiquidityStyle end
struct IsIlliquid <: LiquidityStyle end

# Default behavior is illiquid
LiquidityStyle(::Type) = IsIlliquid()

# Cash is always liquid
LiquidityStyle(::Type{<:Cash}) = IsLiquid()

# Any subtype of Investment is liquid
LiquidityStyle(::Type{<:Investment}) = IsLiquid()

# --- Trait behavior ---

# The thing is tradable if it is liquid
tradable(x::T) where {T} = tradable(LiquidityStyle(T), x)
tradable(::IsLiquid, x) = true
tradable(::IsIlliquid, x) = false

# The thing has a market price if it is liquid
marketprice(x::T) where {T} = marketprice(LiquidityStyle(T), x)
marketprice(::IsLiquid, x) = stub("Will implement pricing function", 0.00)
marketprice(::IsIlliquid, x) = stub("Price for illiquid asset $x is not available.", NaN)

# Pricing for Money
marketprice(x::Money) = x.amount

# A stub function that display a message and then just return the provided value
function stub(s::String, x) 
    println(s)
    return x
end

# --- testing ---

function trait_test1()
    println("\n=== Test Cash ===")
    cash = Money("USD", 100.00)
    @show tradable(cash)
    @show marketprice(cash)

    println("\n=== Test Stock ===")
    aapl = Stock("AAPL", "Apple, Inc.")
    @show tradable(aapl)
    @show marketprice(aapl)

    println("\n=== Test Residence ===")
    home = Residence("Los Angeles")
    @show tradable(home)
    @show marketprice(home)
end

# --- what if we need to use the trait for another thing e.g. a book? ---

abstract type Literature end

struct Book <: Literature
    name
end

# assign trait
LiquidityStyle(::Type{Book}) = IsLiquid()

function trait_test2()
    println("\n=== Test Book ===")
    book = Book("Romeo and Juliet")
    @show tradable(book)
    @show marketprice(book)
end

# --- behavior by trait ---

# The `sell` function sell the thing if it is tradable with a price.
function sell(x)
    if tradable(x) && marketprice(x) != nothing
        return "sold"
    else
        return "cannot be sold"
    end
end

function trait_test3()
    println("\n=== Test Residence ===")
    home = Residence("Los Angeles")
    @show sell(home)

    println("\n=== Test Book ===")
    book = Book("Romeo and Juliet")
    @show sell(book)
end

# --------------------------------------------------------------------------------
# Additional Thoughts:

# How about just using dynamic dispatch?

# Here we define `itradable` and `imarketprice` functions as part of our
# interface.  Using the abstract type hierarchy, it is easy.

itradable(x::Asset) = false  # default is not tradable
itradable(x::Union{T,Cash}) where {T<:Investment} = true

imarketprice(x::Asset) = println("Price for illiquid asset $x is not available.")
imarketprice(x::Union{T,Cash}) where {T<:Investment} = stub("Will implement pricing function", 0.00)

# Let's see how extensible when we need to work with a different hierarchy.

itradable(x::Book) = true

# Let's say I forgot to implement imarketprice for Book.
# Then, the code that depends on it will fail miserably.
# To get the default behavior, we need to add Book to the Union type above.
# (which is not ideal).
#imarketprice(x::Book) = stub("Will check Amazon prices", 25.00)

# duck typing function
# but one has to assume that the object implements the interface
function isell(x)
    if itradable(x) && imarketprice(x) != nothing
        return "sold"
    else
        return "cannot be sold"
    end
end

function dispatch_test()
    println("\n=== Test Stock ===")
    aapl = Stock("AAPL", "Apple, Inc.")
    @show itradable(aapl) 
    @show imarketprice(aapl)

    println("\n=== Test Residence ===")
    home = Residence("Los Angeles")
    @show itradable(home)
    @show imarketprice(home)

    println("\n=== Test Book ===")
    @show book = Book("Romeo and Juliet")
    @show itradable(book) 
    @show imarketprice(book)
    @show isell(book)  # this will fail badly
end

end # module