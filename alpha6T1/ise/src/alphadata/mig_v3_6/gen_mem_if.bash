#!/bin/sh
#
# Script for use with ISE12.3 MIG v3.6 onwards
#
_MIG_Temp=./mig_temp
_MIG_Version=mig_v3_6
#
_XCO_Path=./xco/$1.xco
_XCO_Dest=$1.xco
#
_CGP_Path=./cgp/$1.cgp
_CGP_Dest=$1.cgp
#
_CUS_Path=./prj/custom_part
_CUS_Dest=custom_part
#
_PRJ_Path=./prj/banks4_1Gb_187e_$1.prj
_PRJ_Dest=$_MIG_Version/user_design/mig.prj
#
_FileError=0
if test ! -e $_XCO_Path; then _FileError=1; fi
if test ! -e $_CGP_Path; then _FileError=1; fi
if test ! -e $_CUS_Path; then _FileError=1; fi
if test ! -e $_PRJ_Path; then _FileError=1; fi
#
if test $_FileError -eq 1; then
  echo ""
  echo "Batch file input error"
  echo ""
  echo "Please enter a valid device type: 6vlx240t/6vlx365t/6vlx550t/6vsx315t/6vsx475t"
  echo "For example:"
  echo ""
  echo "gen_mem_if.bash 6vlx240t"
  echo ""
  exit -1
fi
#
#
echo ""
echo "Device Selected: $1"
echo ""
#echo "Project File: $_CGP_Path"
#echo "MIG Parameters: $_XCO_Path"
#echo "MIG Parameters: $_PRJ_Path"
#echo "MIG Parameters: $_CUS_Path"
#echo ""
#
#
echo ""
echo "Creating $_MIG_Temp temporary directory"
echo ""
rm -rf $_MIG_Temp
mkdir $_MIG_Temp
mkdir $_MIG_Temp/$_MIG_Version
mkdir $_MIG_Temp/$_MIG_Version/user_design
#
echo ""
echo "Copying files:"
echo ""
echo "Copying CGP file $_CGP_Path to $_CGP_Dest"
cp -f $_CGP_Path $_MIG_Temp/$_CGP_Dest
echo "Copying PRJ file $_PRJ_Path to $_PRJ_Dest"
cp -f $_PRJ_Path $_MIG_Temp/$_PRJ_Dest
echo "Copying XCO file $_XCO_Path to $_XCO_Dest"
cp -f $_XCO_Path $_MIG_Temp/$_XCO_Dest
echo "Copying custom parts $_CUS_Path to $_CUS_Dest"
cp -rf $_CUS_Path $_MIG_Temp/$_CUS_Dest
#
echo ""
echo "Generating MIG files:"
echo ""
cd $_MIG_Temp
echo "coregen -r -b $_XCO_Dest  -p $_CGP_Dest"
coregen -r -b $_XCO_Dest  -p $_CGP_Dest
errorlevel=$?
#
if test $errorlevel -eq 1; then
  echo ""
  echo "CORE Generator error detected"
  echo ""
  exit $errorlevel
fi
#
#
echo ""
echo "Copying generated VHDL to rtl folder"
cd ..
cp -f $_MIG_Temp/coregen.log .
rm -rf ./rtl
mkdir ./rtl
cp -fR $_MIG_Temp/$_MIG_Version/user_design/rtl .
errorlevel=$?
#
if test $errorlevel -eq 1; then
  echo ""
  echo "RTL copy error"
  echo "Source: $_MIG_Temp/$_MIG_Version/user_design/rtl"
  echo "Dest  : ./rtl"
  echo ""
  exit $errorlevel
fi
#
#rmdir $_MIG_Temp
#
#
echo ""
echo "Generation of MIG cores complete."
echo ""
exit 0
