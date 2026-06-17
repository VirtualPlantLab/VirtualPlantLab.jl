# VirtualPLantLab v1.0.2 release notes

It is now possible to create ellipsoids (both directly and via the turtle). Note that, unlike
other primitives, the argument `n` does not specify the number of triangles but rather 
`ntriangles = 2n(n - 1)` (see documentation of `Ellipsoid` for details).

# VirtualPLantLab v1.0.1 release notes

All packages in the VPLCore plus SkyDomes are in version 1.0.1. This completes the migration
of angles and trigonometry to work exclusively on hexadecimal degree.

## Breaking changes in PlantGeomPrimitives, PlantRayTracer, PlantViz and SkyDomes

This means that all functions that take an angle as input or return an angle as output (from
VPLCore packages plus SkyDomes) will now only work with angles in hexadecimal degrees, never
radians.

The changes also affect internal functions that you may be relying on.

# VirtualPLantLab v1.0.0 release notes

All packages in the VPLCore plus SkyDomes are in version 1.0.0. This is done for technical
reasons to facilitate further development of VPL and to signal that the tools are already
being used as part of research projects across the world.

## Breaking changes in SkyDomes

All public API functions now express angles in degrees instead of
radians (both inputs and outputs). The internal calculations remain in radians.

The affected functions and their angle arguments/outputs are:

* `sky`: inputs `theta_dir`, `phi_dir`, `α`, `alpha_soil`, and `beta_soil` now in degrees.
  Default values updated accordingly (`α = 180.0`, `beta_soil = 180.0`).
* `clear_sky`: input `lat` and outputs `theta` and `phi` now in degrees.
* `daily_radiation`: input `lat` now in degrees.
* `cloudy_sky`: input `lat` and outputs `theta` and `phi` now in degrees.
* `CIE`: inputs `θₛ` and `Φₛ` now in degrees.
* `declination`: return value now in degrees (was radians).
* `day_length`: inputs `lat` and `dec` now in degrees.

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

# VirtualPLantLab v0.1.2 release notes

Fixed test dependencies.

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
