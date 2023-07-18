#!/bin/bash
UrL=https://images.linuxcontainers.org/images

fixTarball () {
[[ -z "$1" ]] && return -1
if [ "$1" = "interfaces" ]
then
	if [ "$2" = "debian" ]
	then
		### uncompress todays rootfs tarball
		echo "applying fix(es)"

		### debian switched to systemd-network or whatever, but prox expects ifupdown
		## create files proxmox expects
		rm -rf ./etc
		mkdir -p ./etc/network
		echo "auto lo" >> ./etc/network/interfaces
		echo "iface lo inet loopback" >> ./etc/network/interfaces

		## append correct files/folders to tarball (which wont actually do anything at first boot, but DHCP will work)
		tar -rf ./rootfs.tar ./etc/network
		tar -rf ./rootfs.tar ./etc/network/interfaces
		rm -rf ./etc
		echo "create temporary container..."
		pct stop 999999999
		pct unmount 999999999
		pct destroy 999999999
		pct create 999999999 $(pwd)/rootfs.tar --arch arm64 --features nesting=1 --hostname pimox-fixer --ostype debian --password='passw0rd' --storage rpi4-local --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,ip6=dhcp
		rm $(pwd)/rootfs.tar
		pct start 999999999
		pct exec 999999999 -- bash -c "for i in {1..50}; do sleep 5 ; ping -c1 www.google.com &> /dev/null && break; done"
		pct exec 999999999 apt update
		pct exec 999999999 apt install ifupdown
		pct exec 999999999 sudo mv /etc/systemd/network/eth0.{network,off}
		pct stop 999999999
		pct unmount 999999999
		pct mount 999999999
		mntdir=`mount |grep -e "999999999/rootfs" | awk '{print $3}'`
		thisdir=`pwd`
		cd $mntdir
		echo Recompressing tarball...
		tar -vcf $thisdir/rootfs.tar .
		cd $thisdir
		pct unmount 999999999
		pct destroy 999999999
	fi

fi
}



function pause(){
 read -s -n 1 -p "Press any key to continue . . ."
 echo ""
}

#################################EndFunctions#######################################


quiet=0
[[ ! -z "$1" ]] && distro=$1
[[ ! -z "$2" ]] && release=$2
[[ ! -z "$3" ]] && variant=$3
[[ ! -z "$4" ]] && PaTh_tO_ImAgE_CaChE=$4 || PaTh_tO_ImAgE_CaChE="."
[[ ! -z "$5" ]] && quiet=$5

clear
for UrlPart in distro release arm64 variant build_date
do
	[[ "$UrlPart" = "arm64" ]] && continue
	if [ "$UrlPart" = "build_date" ]
	then
		build_date=$(curl --silent https://images.linuxcontainers.org/images/$distro/$release/arm64/$variant/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' |cut -d '_' -f 1| sort -r |head -n 1)
		build_date=$(curl --silent https://images.linuxcontainers.org/images/$distro/$release/arm64/$variant/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' |grep -e "$build_date")
		#UrL=$UrL/$build_date
		continue
	else
		[[ ! -z "$1" ]] && continue
		[[ ! -z "$2" ]] && continue
		[[ ! -z "$3" ]] && continue
	fi
	LIST=($(curl --silent $UrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'))
	echo
	echo "#### Pimox Container image fetcher ####"
	echo
	PS3=$(echo ; echo "## Pick a $UrlPart: ")
	select ITEM in ${LIST[@]}
	do
		[[ -z "$ITEM" ]] && continue
		[[ "$UrlPart" = "distro" ]] && distro=$ITEM
	    [[ "$UrlPart" = "release" ]] && release=$ITEM
		[[ "$UrlPart" = "variant" ]] && variant=$ITEM
		clear
		break
	done
done
UrL=$UrL/$distro/$release/arm64/$variant/$build_date/rootfs.tar.xz
[[ "$quiet" = 1 ]] || echo distro\: $distro
[[ "$quiet" = 1 ]] || echo release\: $release
[[ "$quiet" = 1 ]] || echo variant\: $variant
[[ "$quiet" = 1 ]] || echo build_date\: $build_date
[[ "$quiet" = 1 ]] || echo $UrL
[[ "$quiet" = 1 ]] || echo
[[ "$quiet" = 1 ]] || pause

clear
#you can change to your image path if you have the correct permissions
#otherwise it will download in folder

[[ "$PaTh_tO_ImAgE_CaChE" = "." ]] && PaTh_tO_ImAgE_CaChE=$(pwd)
[[ "$quiet" = 1 ]] || echo "Checking Url"
wget --spider -nv "$UrL" >/dev/null 2>/dev/null || badurl=1 && badurl=0 
[[ "$badurl" = 1 ]] && echo "bad url, check internet?" 
[[ "$badurl" = 1 ]] && exit 0


## cleanup from last time
rm -rf rootfs.*
##time to DL
[[ "$quiet" = 1 ]] || echo "Downloading rootfs..."
[[ "$quiet" = 1 ]] || wget -nv --show-progress $UrL && wget -nv $UrL >/dev/null 2>&1

fixTarball=0
tar --wildcards -tf rootfs.tar */etc/network/interfaces >/dev/null 2>&1 || fixTarball=1

if [ "$fixTarball" = 1 ]
then
	echo "decompressing tarball..."
	unxz -T0 ./rootfs.tar.xz
	fixTarball
	echo "recompressing tarball..."
	xz -T0 ./rootfs.tar
else
	
fi

[[ "$quiet" = 1 ]] || echo "moving to image directory ($PaTh_tO_ImAgE_CaChE)"


mv rootfs.tar $PaTh_tO_ImAgE_CaChE/${distro}_arm64_${release}_${variant}_${build_date}.tar
