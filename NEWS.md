# VirtualPLantLab v0.1.1 release notes

Update dependencies and ensure it works on Julia 1.12

# VirtualPLantLab v0.1.0 release notes

No changes (other than version number) since v0.0.7, see below.

# VirtualPLantLab v0.0.7 release notes

Changes in this version:

- A new `Mesh` object is defined that contains any number of user defined properties per
triangle. To access `colors` or `materials` one should do `properties(mesh)[:colors]` or
`properties(mesh)[:materials]` respectively. Note that the assignmet of colors and materials
through turtle constructors maintains the same API.

- No `Scene` object exists anymore, a mesh contains all the information needed. The `Scene`
constructors are now replaced by `Mesh` constructors (i.e., replace `Scene()` with `Mesh()`).

- The function `add!` has a sligthly different API, check the documentation and examples.

- One can add properties individually to a mesh using the `add_property!` function. This is
  required when meshes are constructed first and then added to a turtle or existing meshes.
  Check the API documentation for details of this function.

- Calls to `geoms()` should also be replaced with `Mesh()`

- When merging multiple meshes you need to ensure that they all have the same properties.
