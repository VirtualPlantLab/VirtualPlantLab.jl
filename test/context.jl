#=

Context sensitive rules

Alejandro Morales - May 2023

This examples goes back to a very simple situation: a linear sequence of 3
cells. The point of this example is to introduce relational growth rules and
context capturing.

A relational rules matches nodes based on properties of neighbouring nodes in
the graph. This requires traversing the graph, which can be done with the
methods `parent` and `children` on the `Context` object of the current node,
which return a list of `Context` objects for the parent or children nodes.

In some cases, it is not only sufficient to query the neighbours of a node but
also to use properties of those neighbours in the right hand side component of
the rule. This is know as "capturing the context" of the node being updated.
This can be done by returning the additional nodes from the `lhs` component (in
addition to `true` or `false`) and by accepting these additional nodes in the
`rhs` component. In addition, we tell VPL that this rule is capturing the
context with `captures = true`.

In the example below, each `Cell` keeps track of a `state` variable (which is
either 0 or 1). Only the first cell has a state of 1 at the beginning. In the
growth rule, we check the father of each `Cell`. When a `Cell` does not have a
parent, the rule does not match, otherwise, we pass capture the parent node. In
the right hand side, we replace the cell with a new cell with the state of the
parent node that was captured. Note that that now, the rhs component gets a new
argument, which corresponds to the context of the father node captured in the
lhs.
=#
using VPL
module types
    using VPL
    struct Cell <: Node
        state::Int64
    end
end
import .types: Cell

let
function transfer(context)
    if has_parent(context)
        return (true, (parent(context),))
    else
        return (false, ())
    end
end
rule = Rule(
    Cell,
    lhs = transfer,
    rhs = (context, father) -> Cell(data(father).state),
    captures = true,
)
axiom = Cell(1) + Cell(0) + Cell(0)
pop = Graph(axiom = axiom, rules = rule)

#=
In the original state defined by the axiom, only the first node contains a state
of 1. We can retrieve the state of each node with a query. A `Query` object is a
like a `Rule` but without a right-hand side (i.e., its purpose is to return the
nodes that match a particular condition). In this case, we just want to return
all the `Cell` nodes. A `Query` object is created by passing the type of the
node to be queried as an argument to the `Query` function. Then, to actually
execute the query we need to use the `apply` function on the graph.
=#
getCell = Query(Cell)
apply(pop, getCell)

# If we rewrite the graph one we will see that a second cell now has a state of 1.
rewrite!(pop)
apply(pop, getCell)

# And a second iteration results in all cells have a state of 1
rewrite!(pop)
apply(pop, getCell)

#=
Note that queries may not return nodes in the same order as they were created
because of how they are internally stored (and because queries are meant to
return collection of nodes rather than reconstruct the topology of a graph). If
we need to process nodes in a particular order, then it is best to use a
traversal algorithm on the graph that follows a particular order (for example
depth-first traversal with `traverseDFS()`). This algorithm requires a function
that applies to each node in the graph. In this simple example we can just store
the `state` of each node in a vector (unlike Rules and Queries, this function
takes the actual node as argument rather than a `Context` object, see the
documentation for more details):
=#

pop = Graph(axiom = axiom, rules = rule)
states = Int64[]
traversedfs(pop, fun = node -> push!(states, node.state))
states

# Now the states of the nodes are in the same order as they were created:
rewrite!(pop)
states = Int64[]
traversedfs(pop, fun = node -> push!(states, node.state))
states

end
