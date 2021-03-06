#!/usr/bin/perl
#
# the traditional first program
#
# Strict and warnings are recommended.
#
use strict;
use warnings;
#use Path::Class;
use Getopt::Long;
print " Accpet commands as follows. -param filename or -width nn, -stages nn -reset nn and -outfile filename\n";

my $file = "temp.txt";

my $string = "reg";
my $file2 = "file.txt";
my $num = 0;
my @array = ();
my $indexnum = 0;

my $filename   ="";
my $width      ="";
my $stages     ="";
my $reset      ="";
my $outfile    ="";
my $help       ="";

if (@ARGV >0) {
     


GetOptions(
    'help|h'       => \$help,
    'param:s'      => \$filename,
    'width:i'      => \$width,
    'stages:i'     => \$stages,
    'reset:s'      => \$reset,
    'outfile:s'    => \$outfile
) 
or die "Incorrect usage!\n";close FILE;
}

if ($help){
	print " Accpet commands as follows. -param filename or -width nn, -stages nn -reset nn and -outfile filename\n";
	
}
elsif ( (not $filename =~ /^ *$/) && ((not $width =~ /^ *$/) && (not $stages =~ /^ *$/) && (not $outfile =~ /^ *$/)) )   {
     	
     die "Incorrect usage!\n";close FILE;

}

elsif ( (not $filename =~ /^ *$/) || ((not $width =~ /^ *$/) && (not $stages =~ /^ *$/) && (not $outfile =~ /^ *$/)) )   {
     	
     if (not $filename =~ /^ *$/){
	

        open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
	while (my $row = <$fh>) {
  		chomp $row;

		if ($row =~ "width"){

			my ($width_temp)   = $row =~ /(\d+)/g;  
			$width = int($width_temp);
			
       		}
                elsif($row =~ "stages"){
			
			my ($stages_temp) = $row =~ /(\d+)/g;  
			$stages = int($stages_temp);
			
 		}
		elsif($row =~ "reset"){
			if ( $row =~ "0x"){                # if string has 0x convert hex
				my ($a) = $row =~ /x\s*(.+)$/;				
				$reset = substr($a, 0, index($a, ';'));
		                $reset = hex($reset);
	                	
		  	}
			else{
			my ($reset_temp) = $row =~ /(\d+)/g;  
			$reset = int($reset_temp);
			}
		}
		elsif($row =~ "outfile"){
			my ($a) = $row =~ /=\s*(.+)$/;    # read string after = sign
			$outfile = $a;
		}

	}
	if (($reset) > ($width) ){
	die "Reset shouldn't be larger than width\n"; close FILE;
	}

}
     elsif((not $width =~ /^ *$/) && (not $stages =~ /^ *$/) && (not $outfile =~ /^ *$/)){
	$filename = "";  #default val
        $width = $width+0;
        $stages =$stages+0;

     	if( ($width <1 || $width >64) || ($stages <2 || $stages >128) ){
       		die "Limits out of range!\n";close FILE;
     	}
        if ( $reset =~ "0x"){
		$reset = substr($reset,2);
                $reset = hex($reset);
                
  	} else {
                $reset = $reset + 0;
		
        }
        if (($reset) > ($width) ){
	die "Reset shouldn't be larger than width\n"; close FILE;
	}
     }
    
}
else{
		die "\n(Error ! Invalid argument)\n";
}


    print "My filename is $filename.\n";
    print "The width is $width.\n";
    print "The stages is $stages.\n";
    print "The reset is $reset.\n";
    print "The outfile is $outfile\n";






unless(open FILE, '>'.$outfile){
	die "\nUnable to create(outfile not provided) $outfile\n";
}
$outfile= substr($outfile, 0, index($outfile, '.'));

$width = $width -1;
print FILE "module ";   
print FILE $outfile;                  
    my $message = <<"END_MESSAGE";
(
    reset,
    clk,
    in,
    out,
    scan_in0,
    scan_en,
    scan_out0
    ) ;
 
input
    reset,                // system reset
    clk ;                 // write strobe

input [$width:0]
    in ;                  // data input

output [$width:0]
    out ;                 // data output

input
    scan_in0,             // test scan mode data input
    scan_en;              // test scan mode enable

output
    scan_out0;            // test scan mode data output

wire [$width:0]
    out ;
END_MESSAGE

    print FILE $message;

    for (my $number=0;$number<$stages;$number++)
    {

        print FILE "reg" ." [".$width.":0]"." R".$number . ";\n";
    }
my $message2 = <<"END_MESSAGE";
always @(posedge clk or posedge reset)
    if (reset)
        begin
END_MESSAGE
    print FILE $message2;
for (my $number=0;$number<$stages;$number++)
    {     
        print FILE "          R".$number ." <= ".$reset. ";\n";
    }

my $message3 = <<"END_MESSAGE";
        end
    else
        begin
          R0 <= in;
END_MESSAGE
print FILE $message3;
for (my $number=0;$number<$stages;$number++){
   if ($number < $stages-1){   
        print FILE "          R";
        $num= $number+1;
        print FILE $num." <= R".$number. ";\n";
   }
   else{ 
        print FILE "          assign out = " . "R".$number.";\n" ;
   }
}
my $message4 = <<"END_MESSAGE";
        end
        
endmodule 
END_MESSAGE
print FILE $message4;

close FILE;

