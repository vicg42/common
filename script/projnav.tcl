#
# Utilities for driving Xilinx ISE 10.1i XTCLSH tool
#

# projNav.tcl
package provide projNav 2.0

if { [array names env -exact "XILINX" ] == "XILINX" } {
  set xilinx $env(XILINX)
  set pjr_full_path [ file join $xilinx bin xilinx-init.tcl ]
  if { [ file exists $pjr_full_path] } {
    source $pjr_full_path
  } else {
    puts "*** File $pjr_full_path does not exist"
    exit -1
  }
} else {
  puts "*** Environment variable XILINX must be set."
  exit -1
}

namespace eval ::projNav:: {
  set VMod "Verilog Module"
  set VTB "Verilog Test Fixture"
  set MXCO "Coregen Module"
  set VHDMod "VHDL Module"
  set VHDPkg "VHDL Package"
  set VHDTB "VHDL Testbench"
  set AllTargets [ list "xrc" "xrcp" "xrc2l" "xrc2" "xpl" "xp" "wrc2" "drc2" "xpi" "xrc4sx" "xrc4lx" "xrc4fx" "xrce4fx" "xrc5lx" "xrc5t1" "xrc5t2" "xrc5tz" "xrc5tda1" ]
  set AllDesigns [ list "clock" "ddma" "ddma64" "dll" "frontio" "itest" "master" "memory" "memory64" "reario" "simple" "simple64" "zbt" "zbt64" ]

  namespace export VMod
  namespace export MXCO
  namespace export VHDMod
  namespace export VHDPkg
  namespace export VHDTB
  namespace export AllTargets
  namespace export AllDesigns
  namespace export makeProject
  namespace export makeProjects
  namespace export removeFile
  namespace export removeFiles
  namespace export runProject
  namespace export runProjects
  namespace export runProjectsAll
  namespace export rerunProject
  namespace export rerunProjects
  namespace export rerunProjectsAll
  namespace export installBitstream
  namespace export installBitstreams
  namespace export installBitstreamsAll
}

#
# Function to generate a Project Navigator Project from a description
# of the sources.
#
proc ::projNav::makeProject { _wd _design _entity _projDesc _verbose } {
  set _family [lindex $_projDesc  0]
  set _device [lindex $_projDesc  1]
  set _package [lindex $_projDesc  2]
  set _speed [lindex $_projDesc  3]
  set _target [lindex $_projDesc  4]
  set _sources [lindex $_projDesc  5]
  set _xcf [lindex $_projDesc  6]

  if [expr $_verbose >= 1] then {
    puts "Making ${_design}-${_family}-${_device}-${_speed}"
  }

  set _exists [file exists ${_wd}${_design}.ise]
  if $_exists then {
    puts "  + Project '${_wd}${_design}.ise' already exists - skipping"
    return
  }

#  file mkdir "${_wd}/prj"
#  cd "${_wd}/prj"

  if [expr $_verbose >= 2] then {
    puts "Creating project..."
  }
  project new "${_design}.ise"

  if [expr $_verbose >= 2] then {
    puts "Setting FPGA family to '${_family}'..."
  }
  project set family "${_family}"

  if [expr $_verbose >= 2] then {
    puts "Setting device to 'xc${_device}'..."
  }
  project set device "xc${_device}"

  if [expr $_verbose >= 2] then {
    puts "Setting package to '${_package}'..."
  }
  project set package "${_package}"

  if [expr $_verbose >= 2] then {
    puts "Setting speed grade to '-${_speed}'..."
  }
  project set speed "-${_speed}"

  if [expr $_verbose >= 2] then {
    puts "Adding source files..."
  }
  foreach _source $_sources {
    set _file [lindex $_source 0]
    set _type [lindex $_source 1]
    if [expr $_verbose >= 3] then {
      puts "Adding source ${_file} type ${_type}"
    }
    xfile add "${_file}"
  }

  if [expr $_verbose >= 2] then {
    puts "Setting process properties..."
  }
#    puts "Setting XST property 'Keep Hierarchy' to YES..."
#    project set "Keep Hierarchy" yes
    puts "Setting XST property 'Keep Hierarchy' to NO..."
    project set "Keep Hierarchy" no

    puts "Setting XST property 'Cross Clock Analysis' to YES..."
    project set "Cross Clock Analysis" true

    if [string match $_xcf ""] then {
    } else {
    if [expr $_verbose >= 3] then {
      puts "Setting XST property 'Use Synthesis Constraints File' to TRUE..."
    }
    project set "Use Synthesis Constraints File" true

    if [expr $_verbose >= 3] then {
      puts "Setting XST property 'Synthesis Constraints File' to '$_xcf'"
    }
    project set "Synthesis Constraints File" "$_xcf"
    }

  if [expr $_verbose >= 3] then {
    puts "Setting MAP property 'Pack I/O Registers/Latches into IOBs' to 'For Inputs and Outputs'..."
  }
  project set "Pack I/O Registers/Latches into IOBs" [ list For Inputs and Outputs ]

  if [expr $_verbose >= 3] then {
    puts "Setting BITGEN property 'Drive Done Pin High' to TRUE..."
  }
  project set "Drive Done Pin High" true

  if [expr $_verbose >= 3] then {
    puts "Setting BITGEN property 'Unused IOB Pins' to 'Float'..."
  }
  project set "Unused IOB Pins" [ list Float ]

  if [expr $_verbose < 4] then {
    puts "Setting BITGEN property 'Enable BitStream Compression' to TRUE..."
    project set "Enable BitStream Compression" true
  }

  if [expr $_verbose >= 3] then {
    puts "Setting PAR property 'Place & Route Effort Level (Overall)' to 'High'..."
  }
  project set "Place & Route Effort Level (Overall)" [ list High]

  if [string match $_family "virtex"] then {
    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map to Input Functions' to 6..."
    }
    project set "Map to Input Functions" [ list 6 ]
  }

  if [string match $_family "virtexe"] then {
    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map to Input Functions' to 6'..."
    }
    project set "Map to Input Functions" [ list 6 ]
  }

  if [string match $_family "virtex2"] then {
    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Perform Timing-Driven Packing and Placement' to TRUE..."
    }
    project set "Perform Timing-Driven Packing and Placement" true


    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map to Input Functions' to 8..."
    }
    project set "Map to Input Functions" [ list 8 ]

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map Effort Level' to 'High'..."
    }
    project set "Map Effort Level" [ list High ]
  }

  if [string match $_family "virtex2p"] then {
    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Perform Timing-Driven Packing and Placement' to TRUE..."
    }
    project set "Perform Timing-Driven Packing and Placement" true

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map to Input Functions' to 8..."
    }
    project set "Map to Input Functions" [ list 8 ]

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map Effort Level' to 'High'..."
    }
    project set "Map Effort Level" [ list High ]

  }

  if [string match $_family "virtex4"] then {
    if [expr $_verbose >= 3] then {
      puts "Setting NGDBUILD property 'Macro Search Path' to '../../../../common/null_mgt'..."
    }
    project set "Macro Search Path" "../../../../common/null_mgt" -process "Translate"

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Perform Timing-Driven Packing and Placement' to TRUE..."
    }
    project set "Perform Timing-Driven Packing and Placement" true

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map to Input Functions' to 8..."
    }
    project set "Map to Input Functions" [ list 8 ]

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Map Effort Level' to 'High'..."
    }
    project set "Map Effort Level" [ list High ]
  }

  if [string match $_family "virtex5"] then {
# map -k will be disabled for Virtex5 in ISE 10.2 / 11?
#   if [expr $_verbose >= 3] then {
#     puts "Setting MAP property 'Map to Input Functions' to 8..."
#   }
#   project set "Map to Input Functions" [ list 8 ]

    if [expr $_verbose >= 3] then {
      puts "Setting MAP property 'Placer Effort Level' to 'High'..."
    }
    project set "Placer Effort Level" [ list High ]
  }

  if [expr $_verbose >= 2] then {
    puts "Closing project..."
  }
  project close

  cd $_wd
}

#
# Function to generate a set of Project Navigator Projects from a
# set of descriptions of the sources.
#
proc ::projNav::makeProjects { _wd _design _entity _projDescs _verbose } {
  foreach _projDesc $_projDescs {
    makeProject $_wd $_design $_entity $_projDesc $_verbose
  }
}

#
# Function to run the "Generate Programming File" process of a project.
#
proc ::projNav::runProject { _wd _design _entity _target _device _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Running project ${_design}-${_target}-${_device}"
  }
# cd "${_wd}/${_target}/${_device}"
# project open "${_design}-${_target}-${_device}.ise"
# process run "Generate Programming File"
# project close
# cd $_wd
#  cd "${_wd}/prj"
  project open "${_design}.ise"
  process run "Generate Programming File"
  project close
  cd $_wd
}

#
# Function to run the "Generate Programming File" processes of all projects
# of specified targets for a given design.
#
proc ::projNav::runProjects { _wd _design _entity _targets _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Running targets \[${_targets}\] for design ${_design}"
  }
  foreach _target $_targets {
    set _exists [file exists $_target]
    if $_exists {
      set _isDir [file isdirectory $_target]
      if $_isDir {
        set _devices [glob -nocomplain -directory "${_target}" -- "*"]
        foreach _device $_devices {
          set _device [file tail $_device]
          set _projfile [file join "${_target}" "${_device}" "${_design}-${_target}-${_device}.ise" ]
          set _exists [file exists $_projfile]
          if $_exists {
            runProject $_wd $_design $_entity $_target $_device $_verbose
          }
        }
      }
    }
  }
}

#
# Function to run the "Generate Programming File" processes of all projects
# of all targets for a given design.
#
proc ::projNav::runProjectsAll { _wd _design _entity _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Building design ${_design}"
  }
  set _targets [glob -nocomplain -directory "." -- "*" ]
  foreach _target $_targets {
    set _isDir [file isdirectory $_target]
    if $_isDir {
      set _target [file tail $_target]
      set _devices [glob -nocomplain -directory "${_target}" -- "*"]
      foreach _device $_devices {
        set _device [file tail $_device]
        set _projfile [file join "${_target}" "${_device}" "${_design}-${_target}-${_device}.ise" ]
        set _exists [file exists $_projfile]
        if $_exists {
          runProject $_wd $_design $_entity $_target $_device $_verbose
        }
      }
    }
  }
}

#
# Function to rerun all processes of a project, up to and including
# "Generate Programming File"
#
proc ::projNav::rerunProject { _wd _design _entity _target _device _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Rebuilding project ${_design}-${_target}-${_device}"
  }
  cd "${_wd}/${_target}/${_device}"
  project open "${_design}-${_target}-${_device}.ise"
  process run "Generate Programming File" -force rerun_all
  project close
  cd $_wd
}

#
# Function to rerun all processes of all projects of specified targets a given design,
# up to and including the "Generate Programming File" process.
#
proc ::projNav::rerunProjects { _wd _design _entity _targets _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Rebuilding targets \[${_targets}\] for design ${_design}"
  }
  foreach _target $_targets {
    set _exists [file exists $_target]
    if $_exists {
      set _isDir [file isdirectory $_target]
      if $_isDir {
        set _devices [glob -nocomplain -directory "${_target}" -- "*"]
        foreach _device $_devices {
          set _device [file tail $_device]
          set _projfile [file join "${_target}" "${_device}" "${_design}-${_target}-${_device}.ise" ]
          set _exists [file exists $_projfile]
          if $_exists {
            rerunProject $_wd $_design $_entity $_target $_device $_verbose
          }
        }
      }
    }
  }
}

#
# Function to rerun all processes of all projects of all targets of a given design,
# up to and including the "Generate Programming File" process.
#
proc ::projNav::rerunProjectsAll { _wd _design _entity _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Rebuilding design ${_design}"
  }
  set _targets [glob -nocomplain -directory "." -- "*" ]
  foreach _target $_targets {
    set _isDir [file isdirectory $_target]
    if $_isDir {
      set _target [file tail $_target]
      set _devices [glob -nocomplain -directory "${_target}" -- "*"]
      foreach _device $_devices {
        set _device [file tail $_device]
        set _projfile [file join "${_target}" "${_device}" "${_design}-${_target}-${_device}.ise" ]
        set _exists [file exists $_projfile]
        if $_exists {
          rerunProject $_wd $_design $_entity $_target $_device $_verbose
        }
      }
    }
  }
}

#
# Function to copy a bitstream of a project into the bit/<design> directory,
# with the filename <design>-<target>-<device>.bit.
#
proc ::projNav::installBitstream { _wd _design _target _device _bitdir _verbose } {
  set _srcFile [file join "." "${_target}" "${_device}" "${_design}.bit"]
  set _dstDir [file join "${_bitdir}" "${_design}"]
  set _dstFile [file join "${_dstDir}" "${_design}-${_target}-${_device}.bit"]
  if [expr $_verbose >= 1] then {
    puts "Copying ${_srcFile} to $_dstFile"
  }
  file mkdir $_dstDir
  file copy -force -- $_srcFile $_dstFile
}

#
# Function to copy all bitstreams of a design for specified targets into the bit/<design> directory.
#
proc ::projNav::installBitstreams { _wd _design _targets _bitdir _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Installing bitstreams for targets \[${_targets}\] for design ${_design}"
  }
  foreach _target $_targets {
    set _exists [file exists $_target]
    if $_exists {
      set _isDir [file isdirectory $_target]
      if $_isDir {
        set _devices [glob -nocomplain -directory "${_target}" -- "*"]
        foreach _device $_devices {
          set _device [file tail $_device]
          set _bitfile [file join "${_target}" "${_device}" "${_design}.bit" ]
          set _exists [file exists $_bitfile]
          if $_exists {
            installBitstream $_wd $_design $_target $_device $_bitdir $_verbose
          }
        }
      }
    }
  }
}

#
# Function to copy all bitstreams of a design into the bit/<design> directory.
#
proc ::projNav::installBitstreamsAll { _wd _design _bitdir _verbose } {
  if [expr $_verbose >= 1] then {
    puts "Installing all bitstreams for design ${_design}"
  }
  set _targets [glob -nocomplain -directory "." -- "*" ]
  foreach _target $_targets {
    set _isDir [file isdirectory $_target]
    if $_isDir {
      set _target [file tail $_target]
      set _devices [glob -nocomplain -directory "${_target}" -- "*"]
      foreach _device $_devices {
        set _device [file tail $_device]
        set _bitfile [file join "${_target}" "${_device}" "${_design}.bit" ]
        set _exists [file exists $_bitfile]
        if $_exists {
          installBitstream $_wd $_design $_target $_device $_bitdir $_verbose
        }
      }
    }
  }
}

#
# Function to remove a file or directory tree
#
proc ::projNav::removeFile { _file } {
  set _exists [file exists $_file ]
  if $_exists {
    set _isDir [file isdirectory $_file]
    if $_isDir then {
      # puts "$_file : type = d"
      set _dirfiles [glob -nocomplain -- [file join "$_file" "*"]]
      foreach _f $_dirfiles {
        removeFile $_f
      }
      file delete $_file
    } else {
      # puts "$_file : type != d"
      file delete $_file
    }
  } else {

  }
}

#
# Function to remove a list of files or directory trees
#
proc ::projNav::removeFiles { _files } {
  foreach _f $_files {
    removeFile $_f
  }
}
