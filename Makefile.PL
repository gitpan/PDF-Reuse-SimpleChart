use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile( 'NAME'	   	=> 'PDF::Reuse::SimpleChart',
               'VERSION_FROM'	=> 'SimpleChart.pm', 
               'PREREQ_PM'		=> {PDF::Reuse => 0} );
