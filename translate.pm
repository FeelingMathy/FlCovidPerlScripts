#!/usr/bin/perl
package translate;
use warnings;
use strict;

#
# This software is provided as is, where is, etc with no guarantee that it is
# fit for any purpose whatsoever. Use at your own risk. Mileage may vary.
#

#
# This table can be used to delete column names (i.e. 'VCountry1') or to change
# them to something else. To delete, make the equilivent name empty: ""
#
our @translate_table = (
    "age",            "Age",
    "gender",         "Gender",
    "Sex",            "Gender",
    "county",         "County",
    "Travel_related", "TravelRelated",
    "Travel_Related", "TravelRelated",
    "travel",         "Travel",
    # "Case_",        "Case",
    "VCountry1",      "",
    "VCountry2",      "",
    "VCountry3",      "");
our $translate_table_len = @translate_table;

#
# The subroutine all programs (scripts) use to perform the translate function
#
sub translate_names {
    my $column_name_list_ptr = shift;
    my $debug = shift // 0;

    my $count = @$column_name_list_ptr;

    my @deleted_columns;
    my $new_string;
    my @new_column_name_list;

    #
    #
    #
    for (my $i = 0; $i < $count; $i++) {
        #
        # Remove a name from the front of the list
        #
        my $temp = @$column_name_list_ptr[$i];

        #
        # There were a few days where the 1st file of the day had double quotes around
        # column headers and the 2nd+ files did not. This also reduces the number of master
        # column names from about 50 to about 35
        #
        if ($temp =~ /^"/ && $temp =~ /"\z/) {
            my $len = length ($temp);
            my $new_temp = substr ($temp, 1, $len - 2);
            if ($debug) {
                print ("Removing double quotes from $temp. It is now $new_temp\n");
            }
            $temp = $new_temp;
        }

        #
        # If the name is in the 1st column of the translate table, replace it with what's
        # in the 2nd column
        #
        for (my $j = 0; $j < $translate_table_len; $j += 2) {
            if ($temp eq $translate_table[$j]) {
                $temp = $translate_table[$j + 1];
                last;  # terminate $j loop
            }
        }

        #
        # If the name is not zero-length, put it on the new list
        # If it is zero-length, record the column number
        #
        if (length ($temp) > 0) {
            push (@new_column_name_list, $temp);
        }
        else {
            push (@deleted_columns, $i);
            if ($debug) {
                print ("Deleting column $i\n");
            }
        }
    }

    $new_string = join (',', @new_column_name_list);

    return ($new_string, \@new_column_name_list, \@deleted_columns);
}

1;
