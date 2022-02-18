# gem package -- multi_stage

Provide `spots-warp`, `projection-device` and `projection-map` that projects coordinates and image to other space.  `spots-warp` is useful to convert 
stage coordinate of certain device into global coordinate in VisualStage 2007.

See also `image-warp` in [python package -- image_mosaic](https://github.com/misasa/image_mosaic).

# Dependency

## [gem package -- opencvtool](https://github.com/misasa/opencvtool)

# Installation

Install this package as:

    $ gem source -a http://dream.misasa.okayama-u.ac.jp/rubygems/
    $ gem install multi_stage

# Commands

Commands are summarized as:

| command           | description                                                      | note  |
| ----------------- | ---------------------------------------------------------------- | ----- |
| spots-warp        | Project coordinates to other space.                              |       |
| projection-device | Generate image-info file to project imagefile onto device space. |       |
| projection-map    | Generate imageometryfile to project imagefile onto vs space.     |       |


# Usage

See online document:

    $ spots-warp --help
    $ projection-device --help
    $ projection-map --help
