cprnc README
------------

cprnc is a generic tool for analyzing a netcdf file or comparing
two netcdf files.

If you are trying to debug an installed cprnc tool make sure that you
are looking at the correct one by comparing the path to the one in
your case directory.


Quick Start Guide:
------------------

cprnc uses cmake and requires netcdf-fortran.  It is a serial program and must
use a serial build of the netcdf-fortran library.  To build
cd cprnc
mkdir bld
cd bld
cmake ../

This should be suffiecient if netcdf-fortran and the compiler that
library was built with are in the path.

Finally, put the resulting executable in CCSM_CPRNC as defined in
config_machines.xml.


 Usage: cprnc  [-v] [-d dimname:start[:count]] file1 [file2]
 -m: Compare each time sample. Default is false, i.e. match "time"
     coordinate values before comparing
 -v: Verbose output
 -d dimname:start[:count]
     Print variable values for the specified dimname index subrange.


Users Guide:
------------

cprnc is a Fortran-90 application. It relies on netcdf version 3 or
later and uses the f90 netcdf interfaces.  It requires a netcdf include
file and a netcdf library.

cprnc generates an ascii output file via standard out.  It initially
summarizes some characteristics of the input file[s].  A compare file is
generally 132 characters wide and an analyze file is less than 80
characters wide.

In analyze mode, the output for a field looks like
```
                      (   lon,   lat,  time, -----)
              259200  (   587,   134,     1) (   269,    59,     1)
 FX1           96369   8.273160400390625E+02  0.000000000000000E+00
            avg abs field values:   9.052845920820910E+01
```
and a guide to this information is printed at the top of the file

```
                      (  dim1,  dim2,  dim3,  dim4)
              ARRSIZ1 ( indx1, indx2, indx3) file 1
 FIELD        NVALID           MAX                   MIN
```

The first 10 characters of the field name are identified in the first
  dozen columns of the third line.
The first line summarizes the names of the dimensions of the field
The second line summarizes the indices of the maximum and minimum value
  of the field for the first three dimensions.  If the fourth dimension
  exists, it's always assumed to be time.  Time is handled separately.
The third line summarizes the number of valid values in the array
  and the maximum and minimum value over those valid values.  Invalid
  values are values that are identified to be "fill" value.
The last line summarizes some overall statistics including the average
  absolute value of the valid values of the field.

In comparison mode, the output (132 chars wide) for a field looks like
```
               96369  (   lon,   lat,  time)
              259200  (   422,   198,     1) (   203,   186,     1)           (    47,   169,     1)         (   224,   171,     1)
 FIRA          96369   1.466549530029297E+02 -3.922052764892578E+01   1.4E+02 -3.037954139709473E+01 1.0E+00 -3.979958057403564E+00
               96369   1.321966247558594E+02 -1.603044700622559E+01            1.084177169799805E+02          3.982142448425293E+00
              259200  (   156,    31,     1) (   573,   178,     1)           (
          avg abs field values:    6.778244097051392E+01    rms diff: 1.4E+01   avg rel diff(npos):  4.6E-02
                                   5.960437961084186E+01                        avg decimal digits(ndif):  1.2 worst:  0.0
```
and a guide to this information is printed at the top of the file
```
              NDIFFS  (  dim1,  dim2,  dim3,  dim4, ... )
              ARRSIZ1 ( indx1, indx2, indx3, ... ) file 1
 FIELD        NVALID1          MAX1                  MIN1            DIFFMAX  VALUES                RDIFMAX  VALUES
              NVALID2          MAX2                  MIN2
              ARRSIZ2 ( indx1, indx2, indx3, ...) file 2
```
The information content is identical to the information in analyze
mode with the following additions.  Two additional lines are added
in the main body.  Lines 4 and 5 are identical to line 3 and 2
respectively but are associated with file 2 instead of file 1.
In addition, the right hand side of lines 2, 3, and 4 contain
information about the maximum difference, the location and values
of the maximum difference, the relative difference and the location
and values of the maximum relative difference.  The last two line
summarize some overall statistics including average absolute values
of the field on the two files, rms difference, average relative
difference, average number of digits that match, and the worst
case for the number of digits that match.

"avg rel diff" gives the average relative difference (sum of relative
differences normalized by the number of indices where both variables
have valid values). The denominator for each relative difference is
the MAX of the two values.

"avg decimal digits" is determined by: For each diff, determine the
number of digits that match (as -log10(rdiff(i)); add this to a
running sum; then normalize by the number of diffs (ignoring places
where the two variables are the same). For example, if there are 10
values, 8 of which match, one has a relative difference of 1e-3 and
one has a relative difference of 1e-5, then the avg decimal digits
will be 4.

"worst decimal digits" is simply log10(1/rdmax), where rdmax is the
max relative difference (in the above example, this would give 3).

At the end of the output file, a summary is presented that looks like
```
SUMMARY of cprnc:
 A total number of    119 fields were compared
          of which     83 had non-zero differences
               and     17 had differences in fill patterns
               and      2 had differences in dimension sizes
 A total number of     10 fields could not be analyzed
 A total number of      0 time-varying fields on file 1 were not found on file 2.
 A total number of      0 time-constant fields on file 1 were not found on file 2.
 A total number of      0 time-varying fields on file 2 were not found on file 1.
 A total number of      0 time-constant fields on file 2 were not found on file 1.
  diff_test: the two files seem to be DIFFERENT
```

This summarizes:
- the number of fields that were compared
- the number of fields that differed (not counting fields that differed
  only in the fill pattern)
- the number of fields with differences in fill patterns
- the number of fields with differences in dimension sizes
- the number of fields that could not be analyzed
- the number of fields on one file but not the other
  - for files with an unlimited (time) dimension, these counts are
    broken down into time-varying fields (i.e., fields with an unlimited
    dimension) and time-constant fields (i.e., fields without an
    unlimited dimension)
- whether the files are IDENTICAL, DIFFERENT, or DIFFER only in their field lists
  - Files are considered DIFFERENT if there are differences in the values, fill
    patterns or dimension sizes of any variable
  - Files are considered to "DIFFER only in their field lists" if matching
    variables are all identical, but there are either fields on file1 that are
    not on file2, or fields on file2 that are not on file1
    - However, if the only difference in field lists is in the presence
      or absence of time-constant fields on a file that has an unlimited
      (time) dimension, the files are considered to be IDENTICAL, with
      an extra message appended that notes this fact. (While not ideal,
      this exception is needed so that exact restart tests pass despite
      some time-constant fields being on the output files from one case
      but not the other.)

Developers Guide:
-----------------

The tool works as follows.

Fields can be analyzed if they are int, float or double and
have between 0 and n dimensions

In general, fields that appear on both files are
compared.  If they are sizes, no difference
statistics are computed and only a summary of the fields on
the files are presented.  If  fields only appear
on one file, those fields are analyzed.

The unlimited dimension is treated uniquely.  In general, for files
that have a dimension named "time", the time axes are compared
and matching time values on the two files are compared one
timestep at a time.  Time values that don't match are skipped.
To override the matching behaviour, use cprnc -m.  In this mode,
timestamps are compared in indexical space.  In analyze mode,
the fields are analyzed one timestamp at a time.  In general,
if there is a "time" axis, it will be the outer-most loop in
the output analysis.  In compare mode, fields with a time axis
and a timestamp that are not common between the two files are
ignored.

It is also possible to compare files that don't have an unlimited
dimension; in this case, the '-m' flag must be given.
