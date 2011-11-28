source "../../common/script/projnav.tcl"

# findFiles
# basedir - the directory to start looking in
# pattern - A pattern, as defined by the glob command, that the files must match
proc findFiles { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}

    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty
    foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
        lappend fileList $fileName
    }

    # Now look for any sub direcories in the current directory
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        # Recusively call the routine on the sub directory and append any
        # new files to the results
        set subDirList [findFiles $dirName $pattern]
        if { [llength $subDirList] > 0 } {
            foreach subDirFile $subDirList {
                lappend fileList $subDirFile
            }
        }
    }
    return $fileList
 }

set cur_dir [pwd]
cd ../../
set prj_dir [pwd]
cd $cur_dir
cd ../
set dsn_dir [pwd]
cd $cur_dir                ; #puts "Cuurent dir: $cur_dir"
cd ../ise/src/core_gen
set dsn_coregen_dir [pwd]  ; #puts "Core_gen dir: $dsn_coregen_dir"
cd $cur_dir

set cgp_file cgp
set xco_file xco
set coe_file coe

#»щем все файлы xco,coe
set list_xco_files [findFiles $prj_dir/common *.$xco_file]
set list_coe_files [findFiles $prj_dir/common "*.$coe_file"]

#»щем файл проекта core_gen
set dsn_cgp_file [findFiles $dsn_coregen_dir *.$cgp_file]

foreach name $list_xco_files {
  file copy -force -- $name $dsn_coregen_dir ;# puts "$name"
}
foreach name $list_coe_files {
  file copy -force -- $name $dsn_coregen_dir ;# puts "$name"
}

#set list_dsn_xco_files [findFiles $dsn_coregen_dir *.$xco_file]
#cd ../ise/src/core_gen
#puts "[pwd]"
#exec coregen_regenerate.bat

#foreach name $list_dsn_xco_files {
#  set xco $name
#  puts "xco_file : $xco"
#  puts "cgp_file : $dsn_cgp_file"
#  exec C:/Xilinx/ISE_DS/ISE/bin/nt64/coregen.exe -b $xco -p $dsn_cgp_file -r
#}


