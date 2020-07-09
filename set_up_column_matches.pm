#!/usr/bin/perl
package set_up_column_matches;
use warnings;
use strict;

use lib '.';
use translate;

#
# This software is provided as is, where is, etc with no guarantee that it is
# fit for any purpose whatsoever. Use at your own risk. Mileage may vary.
#

my $debug = 0;

#
#  'FBT_' = file being tested
#  'NF_' = new file being created
#
sub set_up_column_matches {
    my $fbt_column_name_string = shift;   # 1st record of FBT .csv file
    my $NF_name_hash_ptr = shift;

    my @column_matcher;
    my %fbt_name_hash;

    my @original_fbt_column_name_list = split (',', $fbt_column_name_string);
    my $original_fbt_column_count = @original_fbt_column_name_list;
    my @translated_fbt_column_name_list;
    my $translated_fbt_column_count;

    if ($debug) {
        print ("\@original_fbt_column_name_list:\n");
        my $c = 0;
        foreach my $n (@original_fbt_column_name_list) {
            my $string = sprintf ("%02d  %s", $c++, $n);
            print ("  $string\n");
        }
    }

    #
    # Use the translate table to change names in the list if necessary
    #
    my ($new_string, $new_column_name_list_ptr, $deleted_columns_ptr) = 
        translate::translate_names (\@original_fbt_column_name_list, $debug);

    #
    #
    #
    @translated_fbt_column_name_list = @$new_column_name_list_ptr;
    if (@$deleted_columns_ptr) {
        my @deleted_columns = @$deleted_columns_ptr;

        for (my $i = 0; $i < $original_fbt_column_count; $i++) {

            my $del_col_flag = 0;
            foreach my $dc (@deleted_columns) {
                if ($i == $dc) {
                    $del_col_flag = 1;
                }
            }

            if ($del_col_flag) {
                push (@translated_fbt_column_name_list, '');
            }
            else {
                my $n = shift (@translated_fbt_column_name_list);
                push (@translated_fbt_column_name_list, $n);
            }
        }
    }

    #
    # This is a Sanity Clause
    #
    $translated_fbt_column_count = @translated_fbt_column_name_list;
    if ($translated_fbt_column_count != $original_fbt_column_count) {
        die;
    }

    for (my $fbt_column_number = 0; $fbt_column_number < $translated_fbt_column_count; $fbt_column_number++) {

        my $fh = $translated_fbt_column_name_list[$fbt_column_number];
        if (length ($fh) == 0) {
            $column_matcher[$fbt_column_number] = -1;
            next;
        }

        #
        # $fbt_name_hash will map the names in the FBT to column numbers starting at 0
        #
        $fbt_name_hash{$fh} = $fbt_column_number;

        if (exists ($NF_name_hash_ptr->{$fh})) {
            my $from_column = $fbt_column_number;
            my $to_column = $NF_name_hash_ptr->{$fh};
            $column_matcher[$from_column] = $to_column;
            if ($debug) {
                print ("Column $from_column goes to column $to_column\n");
            }
        }
        else {
            print ("Did not find a to column for $fh\n");
            die;
        }
    }

    my $column_matcher_count = @column_matcher;
    if ($column_matcher_count != $original_fbt_column_count) {
        die;
    }

    return (\@column_matcher);
}

sub copy_of_make_name_hash {
    my $names_string = shift;

    my @names_list = split (',', $names_string);
    my $names_list_len = @names_list;
    my %names_hash;
    for (my $i = 0; $i < $names_list_len; $i++) {
        my $key = $names_list[$i];
        $names_hash{$key} = $i;
    }

    return (\%names_hash);
}

if ($debug) {
    my $fbt_file = 'd:/covid/caselinedata/2020 03 19/fl-2020-03-19_110000.csv';
    my $file_number = 1;
    my $nf = 'DateChart,Travel,EDvisit,Origin,ObjectId,Case1,RunningCount,Case_,DayofM,Age,ChartDate,CaseNum,County,TravelRelated,Gender,Case,DateC,Hospitalized,Died,State,Contact,Jurisdiction,CaseDate,Age_group,EventDate';
    my $fbt1 = 'Case_,Contact,Travel_related,Origin,Age,Hospitalized,Gender,County,ObjectId,Jurisdiction,Died,EDvisit';
    my $fbt2 = '"County","Age","Age_group","Gender","Jurisdiction","Travel_related","Origin","EDvisit","Hospitalized","Died","Case_","Contact","Case1","EventDate","ChartDate","ObjectId"';
    my $fbt3 = 'County,State,Age,Sex,Contact,Jurisdiction,Travel_Related,VCountry1,VCountry2,VCountry3,ObjectId';
    my $nf_hash_ptr = copy_of_make_name_hash ($nf);

    my ($column_matcher_ptr) = set_up_column_matches (
        $fbt_file,
        $file_number,
        $fbt3,
        $nf_hash_ptr
    );

    print ("Column matcher:\n");
    my $c = 0;
    foreach my $cm (@$column_matcher_ptr) {
        my $string = sprintf ("%02d  %03d", $c++, $cm);
        print ("  $string\n");
    }

    # if (defined ($deleted_column_ptr)) {
    #     print ("Deleted columns:\n");
    #     $c = 0;
    #     foreach my $dc (@$deleted_column_ptr) {
    #         my $string = sprintf ("%02d  %02d", $c++, $dc);
    #         print ("  $string\n");
    #     }
    # }

}

1;
