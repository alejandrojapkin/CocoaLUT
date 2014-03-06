# CocoaLUT

[![Version](http://cocoapod-badges.herokuapp.com/v/CocoaLUT/badge.png)](http://cocoadocs.org/docsets/CocoaLUT)
[![Platform](http://cocoapod-badges.herokuapp.com/p/CocoaLUT/badge.png)](http://cocoadocs.org/docsets/CocoaLUT)

CocoaLUT is a tool for importing, exporting, and manipulating [3D look up tables](https://en.wikipedia.org/wiki/3D_lookup_table) (LUTs) for colors. LUTs are often used in film and video finishing, graphics, video games, and rendering.

The goal of ths project is to have a fast, modern Objective-C library that works on both iOS and OS X.

Do you need something like this in Python? Try [pylut](http://github.com/gregcotten/pylut)

## Features

- Reads and writes 3D LUTs
  - DaVinci Resolve Cube LUT (.cube)
  - Autodesk Lustre 3D LUT (.3dl)
- Reads 1D LUTs
  - DaVinci Resolve 1D LUT (.olut)
- Has a format-independent internal data structure. You can create LUTs and use them in-memory.
- Apply LUTs to NSImage, CIImage, and UIImage
- Generate Core Image Filters (CIFilter / CIColorCube) from LUTs
- Generate visualizations for LUTs with Scene Kit
- Resize LUTs
- Reverse LUTs

## Uniform Type Identifiers (UTI) for LUTs

There are no standard [Uniform Type Identifiers](https://en.wikipedia.org/wiki/Uniform_Type_Identifier) for LUTs.

This is especially problematic because LUTs have various and conflicting file extensions, so extensions alone cannot be used to disambiguate between LUT file formats.

CocoaLUT aims to also provide a standard specification for LUTs that developers of applications can use to provide a consistent user experience when opening files on Apple operating systems.

**[View and Contribute to the LUT UTI Specification](LUT_UTI_SPEC.md)**

## Installation

CocoaLUT is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod 'CocoaLUT', :head

## Author

- Wil Gieseler (@wilg)
- Greg Cotten (@gregcotten)

## License

CocoaLUT is available under the MIT license. See the LICENSE file for more info.

