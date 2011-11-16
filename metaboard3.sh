#!/bin/bash
##########################CONFIGURATION########################
eagle=/usr/bin/eagle
pcb2gcode=/home/bkubicek/git/pcb2gcode/pcb2gcode
preamble=/home/bkubicek/metaboard3/preamble.ngc
postamble=/home/bkubicek/metaboard3/postamble.ngc

# all values are in mm
millhead="0.6"
pcb_thickness=2.5
#feedrates mm per minute
drillfeedrate=200
cutfeedrate=400
millfeedrate=900
#height to move around
safe=2
offset=100

#################################################################

echo "*****************"
echo "*   Metaboard   *"
echo "*****************"
echo "A script to facitlitate gcode creation from eagle"
echo 
echo "Usage: metaboard <options> filename"
echo " filename: eagle brd file to process"
echo " -double: create a double sided gcode"
echo " -0.8:    use a 0.8mm mill head instead of a 0.6"
echo " -tight:  only offset by a distance of 0.3 mm"
echo " -filled: the eagle board file has a filed dimension area instead of lines"
echo 
echo
echo "***** starting processing  ******"
brd=${!#} 


basename=`echo $brd |sed 's/.brd//g'`
brdname=`basename $brd|sed 's/\.brd//'`
dirname=`dirname $brd|sed 's/\.//g'`


pwd=`pwd`
tmpdir=$pwd$dirname/tmp/

infeed=`awk "BEGIN {print $pcb_thickness /1.8;}"`


OPTS=""
OPTS+="--back ${tmpdir}${brdname}_back.gerber "
OPTS+="--outline ${tmpdir}${brdname}_outline.gerber "
OPTS+="--drill ${tmpdir}${brdname}_drill.excellon "

fill="--outline-width 1 --fill-outline true "
preparefront='echo no front used'
for i in $* ; do
  case $i in
    -double)
      echo "OPTION:  double sided  " 
      OPTS+="--front ${tmpdir}${brdname}_front.gerber "
      preparefront="$eagle -X -dgerber_rs274x -c- -r -o${tmpdir}${brdname}_front.gerber $brd 1  17 18"
      ;;
    -0.8)
    	echo "OPTION: 0.8 drill"
    	millhead="0.8"
    	;;
    -tight)
    	echo "OPTION: minimal offsetting "
    	offset="0.3"
    	;;
    -filled)
    	echo "OPTION: Dimension was already filled "
    	fill=""
    	;;
    \?)
      ;;
  esac
done
echo
echo

OPTS+="--metric --milldrill  "
OPTS+="--zwork 0 --zsafe $safe --zchange 10 --zcut -$pcb_thickness --cutter-diameter $millhead "
OPTS+="--zdrill -$infeed --drill-feed $drillfeedrate --drill-speed 10 "
OPTS+="--offset $offset "
OPTS+="--mill-feed $millfeedrate --mill-speed 10 --cut-feed $cutfeedrate --cut-speed 10 --cut-infeed $infeed "
OPTS+="--dpi 350 "
OPTS+="$fill "
#OPTS+="--basename $basename "
OPTS+="--preamble $preamble --postamble $postamble "


rm -r $tmpdir
mkdir -p $tmpdir

echo "#######################  Exporting front?  ###############"
$preparefront

echo "#######################  Exporting back  ###############"
$eagle -X -dgerber_rs274x -c- -r -o${tmpdir}${brdname}_back.gerber $brd 16  17 18 
echo "#######################  Exporting outline  ###############"
$eagle -X -dgerber_rs274x -c- -r -o${tmpdir}${brdname}_outline.gerber $brd 20
echo "#######################  Exporting drill  ###############"
$eagle -X -dexcellon -c- -r -o${tmpdir}${brdname}_drill.excellon $brd 44 45


echo "#######################  pcb2gcode options ##############"
echo $OPTS 
echo "#######################  Creating paths   ###############"
$pcb2gcode $OPTS
mv outp*.png tmp/

mv back.ngc ${basename}_back.ngc
mv drill.ngc ${basename}_drill.ngc
mv outline.ngc ${basename}_outline.ngc