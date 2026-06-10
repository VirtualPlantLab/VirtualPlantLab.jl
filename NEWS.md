# VirtualPLantLab v0.1.2 release notes

Fixed test dependencies.

# VirtualPLantLab v0.2.0 release notes

We have added the capability to simulate:

- Rows of plants that are not oriented North-South: `α` keyword argument
  (azimuth of the X axis, default `π`).
- Terrain with a slope and orientation: `alpha_soil` (slope
  inclination, default `0`) and `beta_soil` (azimuth of slope normal, default `π`).

A how to guide is added to the website explaining how to use the new feature as well as a
technical note with all the details regarding geomery. The user will mainly have to modify
the call to `sky()` from SkyDomes.jl to account for the changes.

These are not breaking changes as the defaults represent the original situation (so no
need to change code). However, Julia does treat any minor version below 1.0.0 as a breaking
change so you may need to update your `[compat]` section.

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
