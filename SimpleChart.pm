package PDF::Reuse::SimpleChart;
use PDF::Reuse;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

sub new
{  my $name  = shift;
   my ($class, $self);
   if (ref($name))
   {  $class = ref($name);
      $self  = $name;
   }
   else
   {  $class = $name;
      $self  = {};
   }
   bless $self, $class;
   return $self;
}

sub outlines
{  no warnings;
   my $self = shift;
   my %param = @_;
   for (keys %param)
   {   my $key = lc($_);
       $self->{$key} = $param{$_}; 
   }
   $self->{xsize}    = 1 unless ($self->{xsize} != 0);
   $self->{ysize}    = 1 unless ($self->{ysize} != 0);
   $self->{size}     = 1 unless ($self->{size}  != 0);
   $self->{width}    = 450 unless ($self->{width} != 0);
   $self->{height}   = 450 unless ($self->{height} != 0);
   
   if (($self->{type} ne 'bars') 
   &&  ($self->{type} ne 'totalbars')
   &&  ($self->{type} ne 'percentbars')
   &&  ($self->{type} ne 'lines')
   &&  ($self->{type} ne 'area'))
   {  if (substr($self->{type}, 0, 1) eq 't')
      {  $self->{type} = 'totalbars'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'p')
      {  $self->{type} = 'percentbars'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'l')
      {  $self->{type} = 'lines'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'a')
      {  $self->{type} = 'area'; 
      }
      else
      {  $self->{type} = 'bars'; 
      }
   }

   if (! defined $self->{color})
   {   $self->{color} = ['0 0 0.8', '0.8 0 0.3', '0.9 0.9 0', '0 1 0', '0.6 0.6 0.6',
                 '1 0.8 0.9', '0 1 1', '0.9 0 0.55', '0.2 0.2 0.2','0.55 0.9 0.9'];
   }
   return $self;
}

sub add
{  my $self  = shift;
   my @values = @_;
   my $name = shift @values || ' ';
   my $num = 0;
   my $ready;
   if (! defined $self->{col})
   {  for (@values)
      {  if (($_ =~ m'[A-Za-z]+'o) && ($_ !~ m'undef'oi))
         {  $ready = 1;
            $self->{col} = \@values;
            $self->{xunit} = $name;
            last;
         }
      }
   }
   if (! defined $ready)          
   {   if (! exists $self->{series}->{$name})
       {  push @{$self->{sequence}}, $name;
          $self->{series}->{$name} = [];
       }
       my @array = @{$self->{series}->{$name}}; 
       
       for (@values)
       {  if ($_ =~ m'([\d\.\-]*)'o)
          {  if (length($1))
             {   $array[$num] += $1;
             }
          }
          $num++;
       } 
       $self->{series}->{$name} = \@array;
   }
   return $self;
}
   
sub columns
{  my $self   = shift;
   my $xunit = shift;
   $self->{col} = \@_;
   $self->{xunit} = $xunit;
   return $self;
}

sub color
{  my $self = shift;
   $self->{color} = [ (@_) ];
   return $self;
}

sub analysera
{  my $self = shift;
   my $min;
   my $max;
   my @tot = ();
   my @pos = ();
   my @neg = ();
   my $num = 0;
   my $maxSum;
   my $minSum;
   for my $namn (@{$self->{sequence}})
   {   my $i = -1;
       for (@{$self->{series}->{$namn}})
       {   $i++;
           next if (! defined $_);
           $max = $_ if ((! defined $max) || ($_ > $max));
           $min = $_ if ((! defined $min) || ($_ < $min));
           $tot[$i] += abs($_);
           $pos[$i] += $_ if $_ > 0;
           $neg[$i] += abs($_) if $_ < 0;
           $maxSum = $tot[$i] if ((! defined $maxSum) || ($tot[$i] > $maxSum));
           $minSum = $tot[$i] if ((! defined $minSum) || ($tot[$i] < $minSum)); 
       }
       $num = $i if ((! defined $num) || ($num < $i));
   }
   $self->{max} = (defined $max) ? $max : 0;
   $self->{min} = (defined $min) ? $min : 0;
   $self->{maxSum} = (defined $maxSum) ? $maxSum : 0;
   $self->{minSum} = (defined $minSum) ? $minSum : 0;
   $self->{tot} = \@tot;
   $self->{pos} = \@pos;
   $self->{neg} = \@neg;
   $self->{num} = (defined $num) ? $num : 0;

}
sub draw
{  my $self = shift;
   my %param = @_;
   for (keys %param)
   {  my $key = lc($_); 
      $self->{$key} = $param{$_}; }
   $self->outlines();
   my ($str, $xsize, $ysize, $font, $x, $y, $max, $min, $y0, $ySteps, $xT);
   
   $self->analysera();

   my $num = $self->{num} + 1;
   my $xSteps = $#{$self->{col}} + 1;
   $xSteps = $num if ($num > $xSteps);
   my $groups = $#{$self->{sequence}} + 1;

   if (($self->{type} eq 'bars') 
   || ($self->{type} eq 'lines')
   || ($self->{type} eq 'percentbars'))
   {  $max = $self->{max};
      $min = $self->{min};
   }
   elsif (($self->{type} eq 'totalbars')
   ||     ($self->{type} eq 'area')) 
   {  my $totMax = 0;
      my $totMin = 0;
      for (my $i = 0; $i < $num; $i++)
      {   my $tempMax = $self->{pos}[$i] || 0;
          $totMax = $tempMax if $tempMax > $totMax; 
          my $tempMin = $self->{neg}[$i] || 0;
          $totMin = $tempMin if $tempMin > $totMin;
      }
      $min = ($totMin > 0) ? ($totMin * -1): 0;
      $max = ($totMax > 0) ? $totMax : 0;
      $ySteps = ($max - $min) || 1;
   }
   
   if ($self->{type} ne 'percentbars')
   {  if ($min > 0)
      { $ySteps = $max || 1;
      }
      elsif ($max < 0)
      { $ySteps = ($min * -1) || 1;
      }
      else
      { $ySteps = ($max - $min) || 1;
      }
   }
   else
   {  if ($min > 0)
      {  $max = 100;
         $min = 0;
         $ySteps = 100;
      }
      elsif ($max < 0)
      {  $max = 0;
         $min = -100;
         $ySteps = 100;
      }
      else
      {  my $totMax = 0;
         my $totMin = 0;
         for (my $i = 0; $i < $num; $i++)
         {   if ($self->{tot}[$i])
             {  my $tempMax = $self->{pos}[$i] || 0;
                $tempMax = ($tempMax / $self->{tot}[$i]) * 100;
                $totMax = $tempMax if $tempMax > $totMax; 
                my $tempMin = $self->{neg}[$i] || 0;
                $tempMin = ($tempMin / $self->{tot}[$i]) * 100;
                $totMin = $tempMin if $tempMin > $totMin;
             }
         }
         $min = $totMin * -1;
         $max = $totMax;
         $ySteps = ($max - $min) || 1;
      }
   }         
   
   ####################
   # Några kontroller
   ####################

   if ($num < 1)
   {  prText ($self->{x}, $self->{y}, 
              'Values are missing - no graph can be shown');
      return;
   }
   
   if ((! defined $max) || (! defined $min))
   {  prText ($self->{x}, $self->{y}, 
              'Values are missing - no graph can be shown');
      return;
   }
   my $tal1 = sprintf("%.0f", $max);
   my $tal2 = sprintf("%.0f", $min);
   my $tal = (length($tal1) > length($tal2)) ? $tal1 : $tal2;
   my $langd = length($tal);
   my $punkt = index($tal, '.');
   if ($punkt > 0)
   {  $langd -= $punkt;
   }
   
   my $xCor  = ($langd * 12) || 25;         # margin to the left
   my $yCor  = 10;                          # margin from the bottom
   my $xEnd  = $self->{width};
   my $yEnd  = $self->{height};
   my $xArrow = $xEnd * 0.9;
   my $yArrow = $yEnd * 0.97;
   my $xAreaEnd = $xEnd * 0.8;
   my $yAreaEnd = $yEnd * 0.92;
   my $xAxis =  $xAreaEnd - $xCor;
   my $yAxis =  $yAreaEnd - $yCor;

   $xsize = $self->{xsize} * $self->{size};
   $ysize = $self->{ysize} * $self->{size};
   $str  = "q\n";                            # save graphic state
   $str .= "3 M\n";                          # miter limit
   $str .= "1 w\n";                          # line width
   $str .= "0.5 0.5 0.5 RG\n";               # Gray as stroke color
   $str .= "$xsize 0 0 $ysize $self->{x} $self->{y} cm\n";
   if (defined $self->{rotate})
   {   my $rotate = $self->{rotate};
       my $rightx = $self->{x} + $self->{width};
       my $upperY = $self->{y} + $self->{height};
       if ($rotate =~ m'q(\d)'oi)
       {  my $tal = $1;
          if ($tal == 1)
          {  $upperY = $rightx;
             $rightx = 0;
             $rotate = 270;
          }
          elsif ($tal == 2)
          {  $rotate = 180;
          }
          else
          {  $rotate = 90;
             $rightx = $upperY;
             $upperY = 0;
          }
       }
       else
       {   $rightx = 0;
           $upperY = 0;
       }  
       my $radian = sprintf("%.6f", $rotate / 57.2957795);    # approx. 
       my $Cos    = sprintf("%.6f", cos($radian));
       my $Sin    = sprintf("%.6f", sin($radian));
       my $negSin = $Sin * -1;
       $str .= "$Cos $Sin $negSin $Cos $rightx $upperY cm\n";
   }
  
   $font = prFont('H');
   
   my $labelStep = sprintf("%.3f", ($xAxis / $xSteps));
   my $width  = sprintf("%.3f", ($labelStep / ( $groups + 1)));
   my $prop   = sprintf("%.3f", ($yAxis / $ySteps));
   my $xStart = $xAreaEnd + $xCor;
   my $yStart = $yAreaEnd - 10;
   my $tStart = $xStart + 20;
   my $iStep  = sprintf("%.3f", ($yAxis / $num));
   if ($max < 0)
   {  $y0 = $yAreaEnd;
   }
   elsif ($min < 0)
   {  $y0 = $yCor - ($min * $prop);
   } 
   else 
   {  $y0 = $yCor;
   }


   ################
   # Rita y-axeln
   ################

   if (defined $self->{background})
   {  $str .= "$self->{background} rg\n";
      $str .= "$xCor $yCor $xAxis $yAxis re\n";
      $str .= "b*\n";
      $str .= "0 0 0 rg\n";
   }
   $str .= "$xCor $yCor m\n";
   $str .= "$xCor $yArrow l\n";
   # $str .= "b*\n";

   ###############
   # Rita X-axeln
   ###############
   
   $str .= "$xCor $y0 m\n";
   $str .= "$xArrow $y0 l\n";
   $str .= "b*\n";


   #####################   
   # Draw the arrowhead
   #####################

   $str .= "$xCor $yArrow m\n";                  
   $x = $xCor + 2;
   $y = $yArrow - 5;
   $str .= "$x $y l\n";
   $x = $xCor;
   $y = $yArrow - 2;
   $str .= "$x $y l\n";
   $x = $xCor - 2;
   $y = $yArrow - 5;
   $str .= "$x $y l\n";
   $str .= "s\n";

   my $xT2 = 0;

   if ((! defined $self->{nounits}) && (defined $self->{yunit}))
   {  $xT = $xCor - (length($self->{yunit}) * 3);
      $xT = 1 if $xT < 1;
      $xT2 = $xT + (length($self->{yunit}) * 6);
      $y = $yArrow + 7;
      $x = $xCor - 15;
      $str .= "BT\n";
      $str .= "/$font 12 Tf\n";
      $str .= "$xT $y Td\n";
      $str .= '(' . $self->{yunit} . ') Tj' . "\n";
      $str .= "ET\n"; 
   }

   if ($self->{title})
   {  $xT = ($self->{width} / 2) - (length($self->{title}) * 5);
      if ($xT < ($xT2 + 10))
      {  $xT = $xT2 + 10;
      }
      $y = $yArrow + 12;
      $str .= "BT\n";
      $str .= "/$font 14 Tf\n";
      $str .= "$xT $y Td\n";
      $str .= '(' . $self->{title} . ') Tj' . "\n";
      $str .= "ET\n";
   }
       


      
   #####################
   # draw the arrowhead
   #####################
 
   $str .= "$xArrow $y0 m\n";
   $x = $xArrow - 5;                           
   $y = $y0 - 2;
   $str .= "$x $y l\n";
   $x = $xArrow - 2;
   $y = $y0;
   $str .= "$x $y l\n";
   $x = $xArrow - 5;
   $y = $y0 + 2;
   $str .= "$x $y l\n";
   $str .= "s\n";

   if ((! defined $self->{nounits}) && (defined $self->{xunit}))
   {  $y = $y0 - 5;
      $x = $xArrow + 10;
      $str .= "BT\n";
      $str .= "/$font 12 Tf\n";
      $str .= "$x $y Td\n";
      $str .= '(' . $self->{xunit} . ') Tj' . "\n";
      $str .= "ET\n"; 
   } 

   ##################################
   # draw the lines cross the x-axis
   ##################################
   my $yCor2 = $yCor - 5;
   my $yFrom = $yAreaEnd;
   if (($self->{type} eq 'area') || ($self->{type} eq 'lines'))
   {  $xT = sprintf("%.4f", ($labelStep / 2));
      $xT += $xCor;
   }
   
   $str .= "0.9 w\n";
   
   $x = $xCor;
   for (my $i = 1; $i <= $xSteps; $i++)
   {  if (($self->{type} eq 'area') || ($self->{type} eq 'lines'))
      {   $str .= "0.9 0.9 0.9 RG\n";
          $str .= "$xT $yAreaEnd m\n";
          $str .= "$xT $yCor l\n";
          $str .= "S\n";
          $str .= "0 0 0 RG\n";
          $xT += $labelStep;
      }
      $x += $labelStep;
      $str .= "$x $yCor m\n";
      $str .= "$x $yCor2 l\n";
      $str .= "s\n";
   }

   ####################################
   # Write the labels under the x-axis
   ####################################

   $str .= "1 w\n";
   $str .= "0 0 0 RG\n";
   $x = $xCor + sprintf("%.3f", ($labelStep / 3));
   if ((scalar @{$self->{col}}) && ($labelStep > 5) && (! $self->{nounits}))
   {   my $radian = 5.3;     
       my $Cos    = sprintf("%.4f", (cos($radian)));
       my $Sin    = sprintf("%.4f", (sin($radian)));
       my $negSin = $Sin * -1;
       my $negCos = $Cos * -1;
       for (my $i = 0; $i <= $xSteps; $i++)
       {  if (exists $self->{col}->[$i])
          {    $str .= "BT\n";
               $str .= "/$font 8 Tf\n";
               $str .= "$Cos $Sin $negSin $Cos $x $yCor2 Tm\n";
               $str .= '(' . $self->{col}->[$i] . ') Tj' . "\n";
               $str .= "ET\n"; 
          }
          $x += $labelStep;
       }       
       
   }
   if ($iStep > 20)
   {  $yStart -= 20;
      $iStep   = 20;
   }

   if ($tal < 0)
   {  $tal *= -1;
      $langd = length($tal);
   }
   
   if ($langd > 1)
   {  $langd--;
      if (($langd > 1) &&  (substr($tal, 0, 1) le '4'))
      {  $langd--;
      }
      $langd = '0' x $langd;
      $langd = '1' . $langd;
   }
   my $skala = $langd || 1;
   my $xCor2 = $xCor - 5;
   srand(9); 
   
   $str .= "0.3 w\n";
   $str .= "0.5 0.5 0.5 RG\n";
   $x = $xAreaEnd + 5;
   my $last = 0;
     
   while ($skala <= $max)
   {   my $yPos = $prop * $skala + $y0;
       if (($yPos - $last) > 13)  
       {  if (! $self->{nounits})
          {  $xT = $xCor - (length($skala) * 6) - 12;
             $xT = 1 if ($xT < 1);
             $str .= "BT\n";
             $str .= "/$font 12 Tf\n";
             $str .= "$xT $yPos Td\n";
             $str .= "($skala)Tj\n";
             $str .= "ET\n";
          }
          $last = $yPos;
          $str .= "$xCor2 $yPos m\n";
          $str .= "$x $yPos l\n";
          $str .= "b*\n";
       }       
       $skala += $langd;
   }
   $last  = $prop * $langd + $y0;
   $skala = 0;
   while ($skala >= $min)
   {   my $yPos = $prop * $skala + $y0;
       if (($last - $yPos) > 13)
       {  if (! $self->{nounits})
          {   $xT = $xCor - (length($skala) * 6) - 10;
              $xT = 1 if ($xT < 1);
              $str .= "BT\n";
              $str .= "/$font 12 Tf\n";
              $str .= "$xT $yPos Td\n";
              $str .= "($skala)Tj\n";
              $str .= "ET\n";
          }
          $last = $yPos;
          $str .= "$xCor2 $yPos m\n";
          $str .= "$x $yPos l\n";
          $str .= "b*\n";
       }       
       $skala -= $langd;
   }


   $str .= "0 0 0 RG\n";
   my $col1 = 0.9;
   my $col2 = 0.4;
   my $col3 = 0.9;
   
   my @color = @{$self->{color}};
   for (my $i = 0; $i < $groups; $i++)
   {  if (! defined $color[$i])
      {  $col1 = $col3;
         my $alt1 = sprintf("%.2f", (rand(1)));
         my $alt2 = sprintf("%.2f", (rand(1)));
         $col2 = abs($col2 - $col3) > abs(1 - $col3) ? $col3 : (1 - $col3);
         $col3 = abs($col3 - $alt1) > abs($col3 - $alt2) ? $alt1 : $alt2;
         $color[$i] = "$col1 $col2 $col3";
      }
      
      $str .= "$color[$i] rg\n";
      if (($yStart < ($y0 + 13)) && ($yStart > ($y0 - 18)))
      {   $yStart = $y0 - 20;
      }
      $str .= "$xStart $yStart 10 7 re\n";
      $str .= "b*\n";
      $str .= "0 0 0 rg\n";
      $str .= "BT\n";
      $str .= "/$font 12 Tf\n";
      $str .= "$tStart $yStart Td\n";       
      if ($self->{sequence}->[$i])
      {  $str .= '(' . $self->{sequence}->[$i] . ') Tj' . "\n";
      }
      else
      {  $str .= '(' . $i . ') Tj' . "\n";
      }
      $str .= "ET\n";       
      $yStart -= $iStep;
   }
  
   if ($self->{type} eq 'bars')
   {  for (my $j = 0; $j <= $xSteps; $j++)
      {   $xCor += $width / 2;
          my $height;
          my $i = -1;
          for my $namn (@{$self->{sequence}})
          {  $i++;
             if (defined $self->{series}->{$namn}->[$j])
             {  $height = $self->{series}->{$namn}->[$j] * $prop;
                $str .= "$color[$i] rg\n";
                $str .= "$xCor $y0 $width $height re\n";
                $str .= "b*\n";
             }
             $xCor += $width; 
          }
          $xCor += $width / 2;
      }
   }
   elsif ($self->{type} eq 'totalbars')
   {  $width = $labelStep / 2;
      $x = $xCor + $width / 2;
      for (my $j = 0; $j <= $xSteps; $j++)
      {   $y = $y0;
          my $yNeg   = $y0;
          my $height = 0;
          my $depth  = 0;
          my $i = -1;
          for my $namn (@{$self->{sequence}})
          {   $i++;
              if (defined $self->{series}->{$namn}->[$j])
              {  if ($self->{series}->{$namn}->[$j] > 0)
                 {  $height = $self->{series}->{$namn}->[$j] * $prop;
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $y $width $height re\n";
                    $str .= "b*\n";
                    $y += $height;
                 }
                 else
                 {  $depth = $self->{series}->{$namn}->[$j] * $prop;
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $yNeg $width $depth re\n";
                    $str .= "b*\n";
                    $yNeg += $depth;
                 }
              }              
          }
          $x += $labelStep;
      }
   }
   elsif ($self->{type} eq 'lines')
   {  $str .= "1.5 w\n";
      my $offSet = ($min < 0) ? $min : 0;
      my $i = -1;
      for my $namn (@{$self->{sequence}})
      {   $i++;
          my $move;
          $x = $xCor + $labelStep / 2;
          my $height;
          my $x2;
          my $y2;
          $str .= "$color[$i] RG\n";
          $str .= "$color[$i] rg\n";
          for (my $j = 0; $j <= $xSteps; $j++)
          {   if (defined $self->{series}->{$namn}->[$j])
              {  $height = ($self->{series}->{$namn}->[$j] - $offSet) * $prop;
                 $height += $yCor;
                 if ($move)
                 {   $str .= "$move m\n" if ($move);
                     $str .= "$x $height l\n";
                 }
                 $x2 = $x - 1.5;
                 $y2 = $height - 1.5;
                 $move = "$x $height"; 
                 $str .= "$x2 $y2 3 3 re\n";           
              }
              else
              {  $str .= "b*\n";
                 $move = undef;
              }
              $x += $labelStep;
               
          }
          $str .= "b*\n";
      }
   }
   elsif ($self->{type} eq 'percentbars')
   {  $width = $labelStep / 2;
      $x = $xCor + $width / 2;
      for (my $j = 0; $j <= $xSteps; $j++)
      {   $y = $y0;
          my $yNeg   = $y0;
          my $height = 0;
          my $depth  = 0;
          my $i = -1;
          for my $namn (@{$self->{sequence}})
          {   $i++;
              if ((defined $self->{series}->{$namn}->[$j])
              &&  ($self->{series}->{$namn}->[$j] != 0))
              {  if ($self->{series}->{$namn}->[$j] > 0)
                 {  $height = sprintf ("%.4f", (($self->{series}->{$namn}->[$j] / $self->{tot}[$j]) * 100 
                              * $prop));
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $y $width $height re\n";
                    $str .= "b*\n";
                    $y += $height;
                 }
                 else
                 {  $depth = sprintf ("%.4f", (($self->{series}->{$namn}->[$j] / $self->{tot}[$j]) * 100 
                              * $prop));
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $yNeg $width $depth re\n";
                    $str .= "b*\n";
                    $yNeg += $depth;
                 }
              }              
          }
          $x += $labelStep;
      }
   }
   elsif ($self->{type} eq 'area')
   {  $width = $labelStep / 2;
      my @pos = @{$self->{pos}};
      my @neg = @{$self->{neg}};
      my $i = -1;
      for my $namn (@{$self->{sequence}})
      {   $i++;
          my $move;
          $x = $xCor;
          my $x2;
          my $x3;
          my $x0;
          $str .= "$color[$i] RG\n";
          $str .= "$color[$i] rg\n";
          for (my $j = 0; $j <= $xSteps; $j++)
          {   $x2 = $x + $width;
              if (defined $self->{series}->{$namn}->[$j])
              {  if ($self->{series}->{$namn}->[$j] > 0)
                 {   $y = ($pos[$j] * $prop) + $y0;
                     if (! defined $move)
                     {  $x0 = $x + $width / 2;
                        $str .= "$x0 $y0 m\n";
                        $str .= "$x0 $y l\n";
                        $move = 1;
                     }
                     $str .= "$x2 $y l\n";
                     $pos[$j] -= $self->{series}->{$namn}->[$j];  
                 }
                 else
                 {   $neg[$j] = 0 if (! defined $neg[$j]);
                     $y = $y0 - ($neg[$j] * $prop);
                     if (! defined $move)
                     {  $x0 = $x + $width / 2;
                        $str .= "$x0 $y0 m\n";
                        $str .= "$x0 $y l\n";
                        $move = 1;
                     }
                     $str .= "$x2 $y l\n";
                     $neg[$j] += $self->{series}->{$namn}->[$j];  
                 }
                 $x3 = $x2 + $width / 2;      
              }
              elsif ($move)
              {   $str .= "$x3 $y l\n";
                  $str .= "$x3 $y0 l\n";
                  $str .= "B*\n";
                  undef $move;
              }
              $x += $labelStep;               
          }
          if ($move)
          {  $str .= "$x3 $y l\n";
             $str .= "$x3 $y0 l\n";
             $str .= "B*\n";          
          }
      }
   }
   $str .= "Q\n";
   PDF::Reuse::prAdd($str);
   
   return $self;
}
1;

__END__


=head1 NAME

PDF::Reuse::SimpleChart - Produce simple charts with PDF::Reuse

=head1 SYNOPSIS

   use PDF::Reuse::SimpleChart;
   use PDF::Reuse;
   use strict;
  
   prFile('myFile.pdf');
   my $s = PDF::Reuse::SimpleChart->new();

   $s->columns(qw(Month  January February  Mars  April  May June July));
   $s->add(      'Riga',     314,     490,  322,  -965, 736, 120, 239);
   $s->add(      'Helsinki', 389,    -865, -242,     7, 689, 294, 518);
   $s->add(      'Stockholm',456,    -712,  542,   367, 742, 189, 190);
   $s->add(      'Oslo',     622,     533,  674,  1289, 679, -56, 345);
  
   $s->draw(x     => 10,
            y     => 200,
            yUnit => '1000 Euros',
            type  => 'bars');
   prEnd();

(In this case, type could also have been 'totalbars','percentbars', 'lines' or 
'area'.)

=head1 DESCRIPTION

To draw simple charts with the help of PDF::Reuse. Currently there are 5 types:
'bars', 'totalbars','percentbars', 'lines' and 'area'.

=head1 Methods

=head2 new

    my $s = PDF::Reuse::SimpleChart->new();

Constructor. Mandatory.

You can also create a clone of an object like this:

    my $clone = $s->new(); 

=head2 columns

    $s->columns( qw(unit column1 column2 .. columnN));

Defines what you want to write along the x-axis. The first value will be put to 
the right of the arrow of the axis. It could be the "unit" of the columns.

=head2 add

    $s->add('name', value1, value2, ..., valueN);

To define data for the graph. 

The name will be put to the right of the graph. It will be the identifier 
(case sensitive) of the series, so you can add new values afterwards. (Then the 
values also have to come in exactly the same order.)

The values can be numbers with '-' and '.'. You can also have '' or undef to denote
a missing value. If the values contain other characters, the series is interpreted
as 'columns'.

If you have a text file with a simple 2-dimensional table, like the one here below,
you can use each line as parameters to the method. 
(The value in the upper left corner will refer to the columns to the right, not to
the names under it.) 

    Month   January February Mars  April  May  June  July
    Riga        314    490    322   -965  736   120   239
    Helsinki    389   -865   -242      7  689   294   518
    Stockholm   456   -712    542    367  742   189   190
    Oslo        622    533    674   1289  679   -56   345


ex.:

   use PDF::Reuse::SimpleChart;
   use PDF::Reuse;
   use strict;
     
   prFile('myFile.pdf');
   my $s = PDF::Reuse::SimpleChart->new();
   
   open (INFILE, "textfile.txt") || die "Couldn't open textfile.txt, $!\n";
   while (<INFILE>)
   {  my @list = m'(\S+)'og;
      $s->add(@list) if (scalar @list) ;
   }
   close INFILE; 
  
   $s->draw(x     => 10,
            y     => 200,
            yUnit => '1000 Euros',
            type  => 'bars');
   prEnd();


=head2 draw

This method does the actual "plotting" of the graph. The parameters are

=over 4

=item x

x-coordinate of the lower left corner in pixels, where the graph is going to be drawn.
The actual graph comes still a few pixels to the right.

=item y

y-coordinate of the lower left corner in pixels, where the graph is going to be drawn.
The actual graph comes still a few pixels higher up.

=item width

Width of the graph. 450 by default. Long texts might end up outside.

=item height

Height of the graph. 450 by default.

=item size

A number to resize the graph, with lines, texts and everything

(If you change the size of a graph with the parameters width and height, the
font sizes, distances between lines etc. are untouched, but with 'size' they 
also change.)

=item xsize

A number to resize the graph horizontally, with lines, texts and everything

=item ySize

A number to resize the graph vertically, with lines, texts and everything

=item type

By default: 'bars'. Can also be 'totalbars', percentbars', 'lines' and 'area',
(you could abbreviate to the first character if you want). They are more
or less freely interchangeable. 

When you have 'lines' or 'area', you get vertical lines. They show where the 
values of the graph are significant. The values between these points are possible,
but of course not necessarily true. It is an illustration.

=item yUnit

What to write above the y-axis

=item rotate

Look at the documentation for prForm in PDF::Reuse for details. Also texts are
rotated, so most often it is not a good idea to use this parameter.

=item background

Three RGB numbers ex. '0.95 0.95 0.95'.

=item noUnits

If this parameter is equal to 1, no units are written.

=item title

=back

=head2 color

   $s->color( ('1 1 0', '0 1 1', '0 1 0', '1 0 0', '0 0 1'));

To define colors to be used. The parameter to this method is a list of RGB numbers.

=head1 EXAMPLE

This is not a real case. Everything is just invented. It is here to show
how to use the module. If you want the graphs to be less 'dramatic' change the 
type to lines or any of the other types. 

It might be easier to compare the individual offices with 'bars', totalbars',
or 'lines'.

   use PDF::Reuse::SimpleChart;
   use PDF::Reuse;
   use strict;
     
   prFile('myFile.pdf');
   prCompress(1);
   my $s = PDF::Reuse::SimpleChart->new();

   ###########
   # Money in
   ###########

   $s->columns( qw(Month   January February Mars  April  May  June  July));
   $s->add(     qw(Riga        436   790     579   1023   964  520    390));
   $s->add(     qw(Helsinki    529   630     789    567   570   94    180));
   $s->add(     qw(Stockholm   469   534     642    767   712  399    190));
   $s->add(     qw(Oslo        569   833     967   1589   790  158    345));

   $s->draw(x      => 45,
            y      => 455,
            yUnit  => '1000 Euros',
            type   => 'area',
            title  => 'Money In',
            height => 300,
            width  => 460);

   ###################################
   # Costs are to be shown separately
   ###################################

   my $costs = PDF::Reuse::SimpleChart->new();
   
   $costs->columns( qw(Month   January February Mars April  May  June  July));
   $costs->add(     qw(Riga        -316  -290  -376   -823 -243  -320  -509));
   $costs->add(     qw(Helsinki    -440  -830  -989   -671 -170  -394  -618));
   $costs->add(     qw(Stockholm   -218  -345  -242   -467 -412  -299  -590));
   $costs->add(     qw(Oslo        -369  -343  -567   -589 -390  -258  -459));

   $costs->draw(x      => 45,
                y      => 55,
                yUnit  => '1000 Euros',
                type   => 'area',
                title  => 'Costs',
                height => 300,
                width  => 460);

   ####################################
   # The costs are added to 'money in'
   ####################################

   $s->add( qw(Riga        -316  -290  -376   -823 -243  -320  -509));
   $s->add( qw(Helsinki    -440  -830  -989   -671 -170  -394  -618));
   $s->add( qw(Stockholm   -218  -345  -242   -467 -412  -299  -590));
   $s->add( qw(Oslo        -369  -343  -567   -589 -390  -258  -459));

   prPage();

   $s->draw(x     => 45,
            y     => 455,
            yUnit => '1000 Euros',
            type  => 'area',
            title => 'Profit');

   ########
   # Taxes
   ########

   $s->add( qw(Riga        -116  -90   -179   -230  -43  -20  -90));
   $s->add( qw(Helsinki     40   -130  -190   -32   -70  -30  -18));
   $s->add( qw(Stockholm    28   -45   -42    -107  -92  -99  -90));
   $s->add( qw(Oslo        -169  -43   -67    -189  -190 -58  -59));

   $s->draw(x     => 45,
            y     => 55,
            yUnit => '1000 Euros',
            type  => 'area',
            title => 'After Tax');

    prEnd(); 


=head1 SEE ALSO

   PDF::Reuse
   PDF::Reuse::Tutorial

=head1 AUTHOR

Lars Lundberg, E<lt>elkelund @ worldonline . seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Lars Lundberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

You get this module free as it is, but nothing is guaranteed to work, whatever 
implicitly or explicitly stated in this document, and everything you do, 
you do at your own risk - I will not take responsibility 
for any damage, loss of money and/or health that may arise from the use of this module.

=cut