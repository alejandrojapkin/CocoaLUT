# CocoaLUT

[![Build Status](https://travis-ci.org/wilg/CocoaLUT.svg?branch=master)](https://travis-ci.org/wilg/CocoaLUT)
[![Coverage Status](https://img.shields.io/coveralls/wilg/CocoaLUT.svg)](https://coveralls.io/r/wilg/CocoaLUT?branch=master)
[![Version](https://betabadges.herokuapp.com/v/CocoaLUT/badge.svg)](http://cocoadocs.org/docsets/CocoaLUT)
[![Platform](https://betabadges.herokuapp.com/p/CocoaLUT/badge.svg)](http://cocoadocs.org/docsets/CocoaLUT)

CocoaLUT is a tool for importing, exporting, and manipulating [3D look up tables](https://en.wikipedia.org/wiki/3D_lookup_table) (3D LUTs) and 1D look up tables (1D LUTs) for colors. LUTs are often used in film and video finishing, graphics, video games, and rendering.

The goal of this project is to have a fast, modern Objective-C (and soon, Swift) library that works on both iOS and OS X.

This project uses [LUTSpec](http://github.com/wilg/LUTSpec) for UTI standardization.

Do you need something like this in Python? Try [pylut](http://github.com/gregcotten/pylut).

## Features

- Reads and writes 3D LUTs
  - DaVinci Resolve Cube LUT (.cube)
  - Autodesk Lustre / Nuke 3D LUT (.3dl)
  - Unwrapped Texture LUT Image (.tiff, .dpx, .png)
  - CMS Test Pattern LUT Image (.tiff, .dpx, .png)
- Reads and writes 1D LUTs
  - DaVinci Resolve Cube LUT (.cube)
  - DaVinci Resolve 1D LUT (.ilut, .olut)
  - Discreet 1D LUT (.lut)
- Reads non-LUT formats as LUTs
  - Arri Look (.xml) as a 3D LUT
  - ICC/ColorSync Profiles (.icc, .icm, .pf, .prof) as a 3D LUT *(OS X only)*
- Has a format-independent internal data structure. You can create LUTs and use them in-memory.
- Apply LUTs to NSImage, CIImage, and UIImage
- Generate Core Image Filters (CIFilter / CIColorCube) from LUTs
- Generate visualizations for LUTs with Scene Kit
- Resize LUTs
- Reverse LUTs
- Extract the color shift from a 3D LUT
- Extract the contrast shift from a 3D LUT

## Installation

CocoaLUT is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod 'CocoaLUT'

## Authors

- Wil Gieseler (@wilg)
- Greg Cotten (@gregcotten)

## License

CocoaLUT is available under the MIT license. See the LICENSE file for more info.

