# VirtualPLantLab v0.0.2 release notes

There is no official release for VirtualPlantLab 0.0.1, so the changes below are relative to
the (unregistered) VPL.jl.

## Changes to API

- All exported functions that are not associated to a data type use `snake_case` style,
unless one of the words has a single letter. For example, `loadmesh` becomes `load_mesh` but
`nvertices` remains the same in the API. Similarly, `isRoot` becomes `is_root`. Most of
these changes affect the graph-related and rendering API. Functions associated to datatypes
(i.e., constructors) use `CamelCase` but that was already the case (e.g., `SolidCube!` or
`Scene`) so no changes there!.

- The function `feed!` now belongs to PlantGeomTurtle, so to define methods for `feed!` you
should now use `PlantGeomTurtle.feed!` instead of `VPL.Geom.feed!`.

- The functions `render` and `draw` (and their mutating `!` versions) no longer have a `backend`
argument to set the graphics backend. Instead, the user should import `GLMakie` (for native
backend), `WGLMakie` (for web backend) or `CairoMakie` (for Cairo backend) before any call
to `render` or `draw`. Note that these packages are not installed when installing
VirtualPlantLab.jl, so the user may need to install them. Check the new version of the
tutorials for more information.
