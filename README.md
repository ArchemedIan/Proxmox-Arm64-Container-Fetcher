# Pimox-Container-Fetcher
get arm64 LXC images for your Pimox installation


# tl;dr i need a debian bullseye template NOW!

well run this on your pimox!

```
bash <(curl -s https://raw.githubusercontent.com/ArchemedIan/Proxmox-Arm64-Container-Fetcher/main/pimox_image_fetcher.sh)
```


# USAGE

`./pimox_image_fetcher.sh (<distro> <release> <variant> <outputPath> <quiet?>)`

## Examples:
###   interactive:

`./pimox_image_fetcher.sh `

###   interactive w/ path:

`./pimox_image_fetcher.sh -1 -1 -1 /var/lib/vz/template/cache`

###   semi-interactive:

`./pimox_image_fetcher.sh debian -1 default /var/lib/vz/template/cache 0`

###   silent

`./pimox_image_fetcher.sh debian bullseye default /var/lib/vz/template/cache 1`
