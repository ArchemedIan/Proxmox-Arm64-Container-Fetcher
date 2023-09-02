#!/bin/bash
UrL=https://images.linuxcontainers.org/images
LastDir=`pwd`
ls /tmp/parm6rct >/dev/null 2>&1||mkdir  /tmp/parm6rctcd /tmp/parm6rct
fixTarball () {
	#echo $1
	#echo $2
	#exit 0
	[[ -z "$1" ]] && return -1
	if [ "$1" = "debian" ] ; then
		### uncompress todays rootfs tarball
		echo "decompressing tarball..."
		unxz -T0 ./rootfs.tar.xz
		
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
  		sudo pvesm status | grep ctbuildtmp && pvesm remove ctbuildtmp
  		pvesm add dir ctbuildtmp -content rootdir -path /tmp/ctbuildtmp
		pct create 999999999 $(pwd)/rootfs.tar --arch arm64 --features nesting=1 --hostname pimox-fixer --ostype debian --password='passw0rd' --storage ctbuildtmp --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,ip6=dhcp
		rm $(pwd)/rootfs.tar
		pct start 999999999
		pct exec 999999999 -- bash -c "for i in {1..50}; do ip link set eth0 up ; dhclient eth0; sleep 5 ; ping -c1 www.google.com &> /dev/null && break; done"
		pct exec 999999999 apt update
		pct exec 999999999 apt install ifupdown wget
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
		sudo pvesm status | grep ctbuildtmp && pvesm remove ctbuildtmp
		echo "recompressing tarball..."
		xz -T0 ./rootfs.tar	
	
	elif [ "$1" = "apertis" ] ; then
		echo "$1 will boot, but the network settings in the webgui are ignored."
		echo "let me know if you find a fix"
		echo
		pause
	elif [ "$1" = "archlinux" ] ; then
		echo "$1 will boot, but the network settings in the webgui are ignored."
		echo "however it does allow the ip to be set once started, but does not survive restarts"
		echo "let me know if you find a fix"
		echo
		pause
	elif [ "$1" = "busybox" ] ; then
		echo "$1 will install on pimox 7, but i couldnt get the console to work"
		echo "let me know if you find a fix"
		echo
		pause
	elif [ "$1" = "fedora" ] ; then
		if [ $2 > 36 ] ; then
			echo "$1 $2 will not install on pimox 7, it claims it is not yet supported, try 36, or maybe tumbleweed"
			echo "official proxmox provides 37 and 38, but pimox wont install them."
			echo "let me know if this changes"
			echo
			pause
		fi
	elif [ "$1" = "gentoo" ] ; then 
		if [ "$3" = "systemd" ] ; then
			echo "$1 $2 $3 will not install on pimox 7, try the openrc variant"
			echo "let me know if this changes"
			echo
			pause
		else
			echo
		fi
	elif [ "$1" = "oracle" ] ; then
		if [ $2 -gt 8 ] ; then
			echo "$1 $2 will not install on pimox 7, it claims it is not supported, try 8"
			echo "let me know if this changes"
			echo
			pause
		fi
		if [ $2 -eq 7 ] ; then
			echo "$1 $2 will install on pimox 7, but i couldnt get the console to work, try 8"
			echo "let me know if you find a fix"
			echo
			pause
		fi
	elif [ "$1" = "opensuse" ] ; then
		echo "$1 will install on pimox 7, but i couldnt get the console to work"
		echo "let me know if you find a fix"
		echo
		pause
	elif [ "$1" = "rockylinux" ] ; then
		if [ $2 -gt 8 ] ; then
			echo "$1 $2 will not install on pimox 7, it claims it is not supported, try 8"
			echo "let me know if this changes"
			echo
			pause
		fi
	elif [ "$1" = "alpine" ] || [ "$1" = "arch" ] || [ "$1" = "centos" ] || [ "$1" = "devuan" ] || [ "$1" = "kali" ] || [ "$1" = "ubuntu" ]; then 
		echo
	else
		echo "$1 not supported by pimox, image may not work (let me know if you find a fix)"
		echo
		pause
	fi


}



function pause(){
	read -s -n 1 -p "Press any key to continue . . ."
	echo ""
}

function header(){
	[[ "$quiet" = 1 ]] && return 0
        clear
	echo 
	echo "#### Pimox Container image fetcher ####"
	echo
	[[ "$distro" = -2 ]] && distro=-1
	[[ "$distro" = -1 ]] && echo "  distro: <not yet chosen>" || echo "  distro: $distro" 
	[[ "$release" = -1 ]] && echo "  release: <not yet chosen>" || echo "  release: $release"
	[[ "$variant" = -1 ]] && echo "  variant: <not yet chosen>" || echo "  variant: $variant" 
	echo
	[[ "$UrlPart" = "build_date" ]] && echo "  Getting Latest Build Date..."|| echo "  Listing ${UrlPart}s:" 
	echo
}

function dlheader(){

[[ "$quiet" = 1 ]] || echo "latest build date: $friendly_build_date"
[[ "$quiet" = 1 ]] || echo "latest build time: $friendly_build_time"
[[ "$quiet" = 1 ]] || echo
[[ "$quiet" = 1 ]] || echo "Download URL: $UrL"
[[ "$quiet" = 1 ]] || echo

}
#################################EndFunctions#######################################


quiet=0
[[ -z "$1" ]] && distro=-1 || distro=$1
[[ -z "$2" ]] && release=-1 || release=$2
if [ "$distro" = "debian" ] ; then
	if [ "$release" = "unstable" ] ; then
 		release=sid
  	fi
   	if [ "$release" = "10" ] ; then
 		release=buster
  	fi
   	if [ "$release" = "11" ] ; then
 		release=bullseye
  	fi
   	if [ "$release" = "12" ] ; then
 		release=bookworm
  	fi
fi
if [ "$distro" = "ubuntu" ] ; then
	if [ "$release" = "16.04" ] ; then
 		release=xenial
  	fi
   	if [ "$release" = "18.04" ] ; then
 		release=bionic
  	fi
   	if [ "$release" = "20.04" ] ; then
 		release=focal
  	fi
   	if [ "$release" = "22.04" ] ; then
 		release=jammy
  	fi
   	if [ "$release" = "23.04" ] ; then
 		release=lunar
  	fi
   	if [ "$release" = "23.10" ] ; then
 		release=mantic
  	fi
fi
[[ -z "$3" ]] && variant=-1 || variant=$3
[[ -z "$4" ]] && PaTh_tO_ImAgE_CaChE="." || PaTh_tO_ImAgE_CaChE=$4
[[ -z "$5" ]] || quiet=$5

echo $distro $release $variant $PaTh_tO_ImAgE_CaChE $quiet
#exit 0
LUrL="$UrL"
clear
for UrlPart in distro release arm64 variant build_date
do
	if [ "$UrlPart" = "arm64" ] ; then
			HasArm64=1
			curl --output /dev/null --silent --head --fail "$LUrL/arm64/" || HasArm64=0 
			[[ "$HasArm64" = 1 ]] && LUrL=$LUrL/arm64
			[[ "$HasArm64" = 1 ]] && continue
			echo Distro has no arm64 release
			pause
			exit 1
	fi
	
	if [ "$UrlPart" = "distro" ] ; then
		[[ "$distro" = -1 ]] || LUrL=$LUrL/$distro
		[[ "$distro" = -1 ]] || continue 
		# -e "springdalelinux" -e "pld" -e "" -e "" -e "" 
		supportedLIST=($(curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'| grep -v -e "pld" -e "springdalelinux" -e "plamo" -e "plamo" -e "mint" -e "almalinux" -e "amazonlinux" -e "alt" -e "funtoo" -e "openeuler" -e "openwrt" -e "voidlinux")) 
		unsupportedLIST=($(curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'| grep -e "pld" -e "springdalelinux" -e "plamo" -e "plamo" -e "mint" -e "almalinux" -e "amazonlinux" -e "alt" -e "funtoo" -e "openeuler" -e "openwrt" -e "voidlinux"))
		header
		PS3=$(echo ; echo "## Pick a $UrlPart: ")
		while true ; do
			select ITEM in ${supportedLIST[@]} \<Unsupported\ Distro\ List\>
			do
				[[ -z "$ITEM" ]] && continue
				Back=0
				if [ "$ITEM" = "<Unsupported Distro List>" ] ; then
					header
					PS3=$(echo ; echo "## Pick a $UrlPart: ")
					select ITEM in \<Supported\ Distro\ List\> ${unsupportedLIST[@]} 
					do
						[[ "$ITEM" = "<Supported Distro List>" ]] && Back=1
						[[ "$ITEM" = "<Supported Distro List>" ]] && break
						
						[[ -z "$ITEM" ]] && continue
						[[ "$UrlPart" = "distro" ]] && distro=$ITEM
						break
					done
				echo "$ITEM"
				fi
				if [ "$Back" = 1 ]  ; then
					clear
					header
					PS3=$(echo ; echo "## Pick a $UrlPart: ")
					break
				fi
				[[ "$distro" = -1 ]] || break 
				
				distro=$ITEM
				break
			done
			[[ "$distro" = -1 ]] || LUrL=$LUrL/$distro
			[[ "$distro" = -1 ]] || break
			
		done
	fi
	
	if [ "$UrlPart" = "release" ] ; then
		[[ "$release" = -1 ]] || LUrL=$LUrL/$release
		ListSort=1
		[[ "$release" = -1 ]] || continue 
		LIST=($(test $ListSort -eq 1 && curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'|sort -r || curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'))
	fi
	
	if [ "$UrlPart" = "variant" ] ; then
		[[ "$variant" = -1 ]] || LUrL=$LUrL/$variant
		ListSort=1
		[[ "$variant" = -1 ]] || continue 
		LIST=($(test $ListSort -eq 1 && curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'|sort -r || curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'))
	fi
	
	if [ "$UrlPart" = "build_date" ] ; then
		build_date=$(curl --silent https://images.linuxcontainers.org/images/$distro/$release/arm64/$variant/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' | sort -r |head -n 1)
		build_date=$(curl --silent https://images.linuxcontainers.org/images/$distro/$release/arm64/$variant/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' | grep -e "$build_date")
		friendly_build_date=$(echo $build_date|cut -d"_" -f1)
		friendly_build_time=$(echo $build_date|cut -d"_" -f2| sed 's/%3A/:/')
		#echo $friendly_build_date
		
		LUrL=$LUrL/$build_date
		
		continue
	fi


	#LIST=($(test $ListSort -eq 1 && curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'|sort -r || curl --silent $LUrL/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//'| grep -ve '\.\.'))
	ListSort=0
	header
	PS3=$(echo ; echo "## Pick a $UrlPart: ")
	select ITEM in ${LIST[@]}
	do
		[[ -z "$ITEM" ]] && continue
		LUrL=$LUrL/$ITEM
		#echo $LUrL
		[[ "$UrlPart" = "distro" ]] && distro=$ITEM
	    [[ "$UrlPart" = "release" ]] && release=$ITEM
		[[ "$UrlPart" = "variant" ]] && variant=$ITEM
		
		break
	done
done
UrL=$UrL/$distro/$release/arm64/$variant/$build_date/rootfs.tar.xz
[[ "$quiet" = 1 ]] ||clear
[[ "$quiet" = 1 ]] ||echo
[[ "$quiet" = 1 ]] ||header
[[ "$quiet" = 1 ]] ||dlheader
[[ "$quiet" = 1 ]] || pause
#exit 0
[[ "$quiet" = 1 ]] ||clear
[[ "$quiet" = 1 ]] ||header
[[ "$quiet" = 1 ]] ||dlheader
#you can change to your image path if you have the correct permissions
#otherwise it will download in folder

[[ "$PaTh_tO_ImAgE_CaChE" = "." ]] && PaTh_tO_ImAgE_CaChE=$(pwd)
[[ "$quiet" = 1 ]] || echo "Checking Url"
badurl=0
curl --output /dev/null --silent --head --fail "$UrL" || badurl=1 
[[ "$badurl" = 1 ]] && echo "bad url, check internet?" || echo "url is valid"
[[ "$badurl" = 1 ]] && exit 0
[[ "$quiet" = 1 ]] || echo

## cleanup from last time
rm -rf ./rootfs*
sleep 2
##time to DL
[[ "$quiet" = 1 ]] || echo "Downloading rootfs..."
[[ "$quiet" = 1 ]] || wget -Orootfs.tar.xz -q -nv --show-progress $UrL && wget -Orootfs.tar.xz -q -nv $UrL 
[[ "$quiet" = 1 ]] || echo
fixTarball=0
#tar --wildcards -tf rootfs.tar.xz */etc/network/interfaces >/dev/null 2>&1 || 
fixTarball=1
#echo $fixTarbal

[[ "$quiet" = 1 ]] && fixTarball $distro $release $variant >/dev/null 2>/dev/null || fixTarball $distro $release $variant
if [ "$distro" = "debian" ] ; then
	if [ "$release" = "sid" ] ; then
 		release=sid
  	fi
   	if [ "$release" = "buster" ] ; then
 		release=10
  	fi
   	if [ "$release" = "bullseye" ] ; then
 		release=11
  	fi
   	if [ "$release" = "bookworm" ] ; then
 		release=12
  	fi
fi
if [ "$distro" = "ubuntu" ] ; then
	if [ "$release" = "xenial" ] ; then
 		release=16.04
  	fi
   	if [ "$release" = "bionic" ] ; then
 		release=18.04
  	fi
   	if [ "$release" = "focal" ] ; then
 		release=20.04
  	fi
   	if [ "$release" = "jammy" ] ; then
 		release=22.04
  	fi
   	if [ "$release" = "lunar" ] ; then
 		release=23.04
  	fi
   	if [ "$release" = "mantic" ] ; then
 		release=23.10
  	fi
fi


[[ "$quiet" = 1 ]] || echo
[[ "$quiet" = 1 ]] || echo "moving to image directory ($PaTh_tO_ImAgE_CaChE/${distro}-${release}-${variant}-arm64-${friendly_build_date}-${friendly_build_time}.tar.xz)"

mv rootfs.tar.xz $PaTh_tO_ImAgE_CaChE/${distro}-${release}-${variant}-arm64-${friendly_build_date}-${friendly_build_time}.tar.xz
#[[ "$quiet" = 1 ]] && printf ${distro}_${release}_${variant}_arm64_${friendly_build_date}_${friendly_build_time}.tar.xz
cd $LastDir
