# Pimox-Container-Fetcher
get arm64 LXC images for your Pimox installation

# USAGE

`./pimox_image_fetcher.sh (<distro> <release> <variant> <outputPath> <quiet?>)`

## Examples:
###   interactive:

`./pimox_image_fetcher.sh `

###   semi-interactive:

`./pimox_image_fetcher.sh debian bullseye default /var/lib/vz/template/cache 0`

###   silent

`./pimox_image_fetcher.sh debian bullseye default /var/lib/vz/template/cache 1`
