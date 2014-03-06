# Uniform Type Identifiers (UTI) for LUTs

There are no standard [Uniform Type Identifiers](https://en.wikipedia.org/wiki/Uniform_Type_Identifier) for LUTs.

This is especially problematic because LUTs have various and conflicting file extensions, so extensions alone cannot be used to disambiguate between LUT file formats.

CocoaLUT aims to also provide a standard specification for LUTs that developers of applications can use to provide a consistent user experience when opening files on Apple operating systems.

## Public LUT UTIs

- `public.plain-text`

  - `public.color-lookup-table`

    A base UTI for any type of color lookup table.

    - `public.3d-color-lookup-table`

      A [three-dimensional color lookup table](https://en.wikipedia.org/wiki/3D_lookup_table).

      - `com.autodesk.3dl`

        Autodesk Lustre 3D LUT

      - `com.blackmagicdesign.cube`

        DaVinci Resolve Cube LUT

    - `public.1d-color-lookup-table`

      A one-dimensional color lookup table.

      - `com.blackmagicdesign.olut`

        DaVinci Resolve 1D LUT


# Contributing

Contributions are welcome. Please open an issue or pull request.