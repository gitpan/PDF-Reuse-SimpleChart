package PDF::Reuse::SimpleChart;
use PDF::Reuse;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

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
   return $self;
}

sub marginAction
{  my $self = shift;
   my $code = shift;
   if ($code !~ m'\"'os)
   {  $code = '"' . $code . '"';
   }
   elsif ($code !~ m/\'/os)
   {  $code = '\'' . $code . '\'';
   }
   else
   {  $code =~ s/\'/\\\'/og;
      $code =~ s/\\\\\'/\\\'/og;
      $code = "'" . $code . "'";
   }
   {  $self->{marginAction} = $code;
   }
   return $self;
}

sub marginToolTip
{  my $self = shift;
   my $text = shift;
   if ($text !~ m'\"'os)
   {  $text = '"' . $text . '"';
   }
   elsif ($text !~ m/\'/os)
   {  $text = '\'' . $text . '\'';
   }
   else
   {  $text =~ s/\'/\\\'/og;
      $text =~ s/\\\\\'/\\\'/og;
      $text = "'" . $text . "'";
   }
   $self->{marginToolTip} = $text;
   return $self;
}


sub barsActions
{  my $self = shift;
   my $namn = shift;
   my (@codeArray, $str);
   for (@_)
   {  if ($_ !~ m'\"'os)
      {  $str = '"' . $_ . '"';
         push @codeArray, $str;
      }
      elsif ($_ !~ m/\'/os)
      {  $str = '\'' . $_ . '\'';
         push @codeArray, $str;
      }
      else
      {  $str = $_;
         $str =~ s/\'/\\\'/og;
         $str =~ s/\\\\\'/\\\'/og;
         $str = "'" . $str . "'";
         push @codeArray, $str;
      }
   }

   if ($namn)
   {  $self->{barAction}->{$namn} = \@codeArray;
   }
   return $self;
}

sub barsToolTips
{  my $self = shift;
   my $namn = shift;
   my (@toolTips, $str);
   for (@_)
   {  if ($_ !~ m'\"'os)
      {  $str = '"' . $_ . '"';
         push @toolTips, $str;
      }
      elsif ($_ !~ m/\'/os)
      {  $str = '\'' . $_ . '\'';
         push @toolTips, $str;
      }
      else
      {  $str = $_;
         $str =~ s/\'/\\\'/og;
         $str =~ s/\\\\\'/\\\'/og;
         $str = "'" . $str . "'";
         push @toolTips, $str;
      }
   }
   if ($namn)
   {  $self->{barToolTip}->{$namn} = \@toolTips;
   }
   return $self;
}

sub columnsActions
{  my $self = shift;
   my (@codeArray, $str);
   for (@_)
   {  if ($_ !~ m'\"'os)
      {  $str = '"' . $_ . '"';
         push @codeArray, $str;
      }
      elsif ($_ !~ m/\'/os)
      {  $str = '\'' . $_ . '\'';
         push @codeArray, $str;
      }
      else
      {  $str = $_;
         $str =~ s/\'/\\\'/og;
         $str =~ s/\\\\\'/\\\'/og;
         $str = "'" . $str . "'";
         push @codeArray, $str;
      }
   }

   $self->{columnsActions} = \@codeArray;
   
   return $self;
}

sub columnsToolTips
{  my $self = shift;
   my (@toolTips, $str);
   for (@_)
   {  if ($_ !~ m'\"'os)
      {  $str = '"' . $_ . '"';
         push @toolTips, $str;
      }
      elsif ($_ !~ m/\'/os)
      {  $str = '\'' . $_ . '\'';
         push @toolTips, $str;
      }
      else
      {  $str = $_;
         $str =~ s/\'/\\\'/og;
         $str =~ s/\\\\\'/\\\'/og;
         $str = "'" . $str . "'";
         push @toolTips, $str;
      }
   }
   $self->{columnsToolTips} = \@toolTips;
   return $self;
}


sub boxAction
{  my $self = shift;
   my $namn = shift;
   my $code = shift;
   if ($code !~ m'\"'os)
   {  $code = '"' . $code . '"';
   }
   elsif ($code !~ m/\'/os)
   {  $code = '\'' . $code . '\'';
   }
   else
   {  $code =~ s/\'/\\\'/og;
      $code =~ s/\\\\\'/\\\'/og;
      $code = "'" . $code . "'";
   }
   {  $self->{boxAction}->{$namn} = $code;
   }
   return $self;
}

sub boxToolTip
{  my $self = shift;
   my $namn = shift;
   my $text = shift;
   if ($text !~ m'\"'os)
   {  $text = '"' . $text . '"';
   }
   elsif ($text !~ m/\'/os)
   {  $text = '\'' . $text . '\'';
   }
   else
   {  $text =~ s/\'/\\\'/og;
      $text =~ s/\\\\\'/\\\'/og;
      $text = "'" . $text . "'";
   }
   $self->{boxToolTip}->{$namn} = $text;
   return $self;
}


sub defineIArea
{  my $self = shift;
   my $code =<<"EOF";
function iArea()
{  var vec = iArea.arguments;
   var page = vec[0];
   var x  = vec[1];
   var y2 = vec[2];
   var x2 = vec[3] + x;     
   var y  = y2 + vec[4];
   var name = 'p' + page + 'x' + x + 'y' + y + 'x2' + x2 + 'y2' + y2;
   var b = this.addField(name, "button", page, [x, y, x2, y2]);
   b.setAction("MouseUp", vec[5]);
   if (vec[6])
     b.userName = vec[6]; 
}
EOF

  prJs($code);
  return $self;
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
   #my $punkt = index($tal, '.');
   #if ($punkt > 0)
   #{  $langd -= $punkt;
   #}
   
   my $xCor  = ($langd * 12) || 25;         # margin to the left
   my $yCor  = 20;                          # margin from the bottom
   my $xEnd  = $self->{width};
   my $yEnd  = $self->{height};
   my $xArrow = $xEnd * 0.9;
   my $yArrow = $yEnd * 0.97;
   my $xAreaEnd = $xEnd * 0.85;
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
   $font = prFont('H');
   
   my $labelStep = sprintf("%.5f", ($xAxis / $xSteps));
   my $width  = sprintf("%.5f", ($labelStep / ( $groups + 1)));
   my $prop   = sprintf("%.5f", ($yAxis / $ySteps));
   my $xStart = $xArrow + 10;
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
   {  $xT =  $self->{width} - (length($self->{title}) * 11);
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
   for (my $i = 0; $i < $xSteps; $i++)
   {  if (($self->{type} eq 'area') || ($self->{type} eq 'lines'))
      {   $str .= "0.9 0.9 0.9 RG\n";
          $str .= "$xT $yAreaEnd m\n";
          $str .= "$xT $yCor l\n";
          $str .= "S\n";
          $str .= "0 0 0 RG\n";
          $xT += $labelStep;
      }

      if ((defined $self->{iparam})
      &&  (defined $self->{columnsActions}->[$i]))
      {   $self->insert($x,
                        0,
                        $labelStep,
                        $yCor,
                        $self->{iparam},
                        $self->{columnsActions}->[$i],
                        $self->{columnsToolTips}->[$i]);
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
   $x = $xCor + sprintf("%.3f", ($labelStep / 2.5));
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

   if ((defined $self->{marginAction})
   &&  (defined $self->{iparam}))
   {   $self->insert( 0,
                      0,
                      $xCor,
                      $yArrow,
                      $self->{iparam},
                      $self->{marginAction},
                      $self->{marginToolTip});
   }

   $str .= "0 0 0 RG\n";
   my $col1 = 0.9;
   my $col2 = 0.4;
   my $col3 = 0.9;
   
   if (defined $self->{groupstitle})
   {   my $yTemp = $yStart + 20;
       if ($yTemp < ($y0 + 20))
       {  $yTemp = $y0 - 20;
          $yStart = $yTemp - 20;
       } 
       $str .= "0 0 0 rg\n";
       $str .= "BT\n";
       $str .= "/$font 12 Tf\n";
       $str .= "$xStart $yTemp Td\n";       
       $str .= '(' . $self->{groupstitle} . ') Tj' . "\n";
       $str .= "ET\n";
   }
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
      my $name = $self->{sequence}->[$i];
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
      if ($name)
      {  $str .= '(' . $name . ') Tj' . "\n";
      }
      else
      {  $str .= '(' . $i . ') Tj' . "\n";
      }
      $str .= "ET\n";

      if  ((defined $self->{iparam})
      &&   (defined $self->{boxAction}->{$name}))
      {   $self->insert($xStart,
                        $yStart,
                        10,
                        7,
                        $self->{iparam},
                        $self->{boxAction}->{$name},
                        $self->{boxToolTip}->{$name});
      }
       
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
                if ((defined $self->{iparam})
                &&  (defined $self->{barAction}->{$namn}->[$j]))
                {   $self->insert( $xCor,
                                   $y0,
                                   $width,
                                   $height,
                                   $self->{iparam},
                                   $self->{barAction}->{$namn}->[$j],
                                   $self->{barToolTip}->{$namn}->[$j]);
                }
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
          my $yCurrent;
          my $height = 0;
          my $i = -1;
          for my $namn (@{$self->{sequence}})
          {   $i++;
              if (defined $self->{series}->{$namn}->[$j])
              {  if ($self->{series}->{$namn}->[$j] > 0)
                 {  $height = $self->{series}->{$namn}->[$j] * $prop;
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $y $width $height re\n";
                    $str .= "b*\n";
                    $yCurrent = $y;
                    $y += $height;
                 }
                 else
                 {  $height = $self->{series}->{$namn}->[$j] * $prop;
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $yNeg $width $height re\n";
                    $str .= "b*\n";
                    $yCurrent = $yNeg;
                    $yNeg += $height;
                 }
                 if ((defined $self->{iparam})
                 &&  (defined $self->{barAction}->{$namn}->[$j]))
                 {   $self->insert( $x,
                                    $yCurrent,
                                    $width,
                                    $height,
                                    $self->{iparam},
                                    $self->{barAction}->{$namn}->[$j],
                                    $self->{barToolTip}->{$namn}->[$j]);
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
          my $yCurrent;
          my $yNeg   = $y0;
          my $height = 0;
          
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
                    $yCurrent = $y;
                    $y += $height;
                 }
                 else
                 {  $height = sprintf ("%.4f", (($self->{series}->{$namn}->[$j] / $self->{tot}[$j]) * 100 
                              * $prop));
                    $str .= "$color[$i] rg\n";
                    $str .= "$x $yNeg $width $height re\n";
                    $str .= "b*\n";
                    $yCurrent = $yNeg;
                    $yNeg += $height;
                 }
                 if ((defined $self->{iparam})
                 &&  (defined $self->{barAction}->{$namn}->[$j]))
                 {   $self->insert( $x,
                                    $yCurrent,
                                    $width,
                                    $height,
                                    $self->{iparam},
                                    $self->{barAction}->{$namn}->[$j],
                                    $self->{barToolTip}->{$namn}->[$j]);
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


sub insert
{   my $self = shift;
    my ($xPos, $yPos, $wid, $hei, $page, $action, $mess) = @_;
       
    my $x      = $self->{x} + $xPos * ($self->{xsize} * $self->{size});
    my $y      = $self->{y} + $yPos * ($self->{ysize} * $self->{size});
    my $width  = $wid * ($self->{xsize} * $self->{size});
    my $height = $hei * ($self->{ysize} * $self->{size});
    
    if ($mess)
    {  prInit("iArea($page, $x, $y, $width, $height, $action, $mess);");
    }
    else
    {  prInit("iArea($page, $x, $y, $width, $height, $action);");
    }
    1;
}

1;

__END__


=head1 NAME

PDF::Reuse::SimpleChart - Produce simple charts with PDF::Reuse

=head1 SYNOPSIS

=for synopsis.pl begin

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

=for end

=head1 DESCRIPTION

To draw simple charts with the help of PDF::Reuse. Currently there are 5 types:
'bars', 'totalbars','percentbars', 'lines' and 'area'.

You can also add interactive functions to the chart. If your user has Acrobat Reader
5.0.5 or higher, he/she should be able to use the functions. The Reader needs to have
the option "Allow File Open Actions and Launching File Attachments" checked under
"Preferences".

If he/she uses Acrobat there is a complication. Everything should work fine as long
as new files are not read via the web. Acrobat has a plug in, "webpdf.api", which
converts documents, also PDF-documents, when they are fetched over the net.
That is probably a good idea in some cases, but here it changes new documents, 
and the JavaScripts needed for the interactive functions are lost (wasn't PDF meant
to be a "Portable Document Format" ?), and as an addition to the problems
the procedure is painfully slow. The user will have the chart, but he/she will not
be able to use the interactive functions. (In cases of real emergency, you can
disable the plug in simply by removing it from the directory Plug_ins under Acrobat,
put it in a safe place, and start Acrobat. And put it back next time you need it.) 

Anyway, almost every computer has the Reader somewhere, and if it is not of the
right version, it can be downloaded. So with a little effort, it should be possible
to run these interactive functions on most computers.

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

=for textfile.txt begin

    Month   January February Mars  April  May  June  July
    Riga        314    490    322   -965  736   120   239
    Helsinki    389   -865   -242      7  689   294   518
    Stockholm   456   -712    542    367  742   189   190
    Oslo        622    533    674   1289  679   -56   345

=for end

ex. ('example.pl'):

=for example.pl begin

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

=for end

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

=item background

Three RGB numbers ex. '0.95 0.95 0.95'.

=item noUnits

If this parameter is equal to 1, no units are written.

=item title

Title above the chart

=item groupsTitle

Titel above the column to the right of the chart

=back

=head2 color

   $s->color( ('1 1 0', '0 1 1', '0 1 0', '1 0 0', '0 0 1'));

To define colors to be used. The parameter to this method is a list of RGB numbers.

=head1 Methods for Acrobat Reader 5.0.5 or higher

=head2 barsActions

   $s->barsActions('name', 'jScript1', 'jScript2', ... 'jScriptN');

To define JavaScript actions for the bars (bars, totalbars, percentbars). The name
has to be the same as 'name' in the add method. 

=head2 barsToolTips

   $s->barsToolTips('name', 'text1', 'text2', ... 'textN');

Defines tool tip texts for the actions defined with 'barsActions'. The name connects
the texts to the right bars.

=head2 boxAction

   $s->boxAction('name', 'jScript');

To define a JavaScript action for the little box with the name to the left of the
graph. 

=head2 boxToolTip

   $s->boxToolTip('name', 'text');

Defines a tool tip text for the action defined with 'boxAction'. The name connects
the texts to the right box.

=head2 columnsActions

   $s->columnsActions('jScript1', 'jScript2', ... 'jScriptN');

Defines a JavaScript action to be taken for each column

=head2 columnsToolTips

   $s->columnsToolTips('text1', 'text2', ... 'textN');   

Defines tool tip texts for the actions defined with 'columnsActions'. 

=head2 defineIArea

   $s->defineIArea();

Defines the JavaScript function iArea in a new document. 
B<N.B. Mandatory for every document where you use these interactive charts.>

=head2 draw

=over 4

=item iparam

=back

Each time the method draw is used and you need JavaScript functions to be active
the parameter iparam is needed and it has to hold the page number (starting with 0). 
ex.:

   $s->draw(x           =>  45,
            y           =>  500,
            type        => 'lines',
            iparam      =>  0,
            height      =>  300,
            width       =>  460,
            groupsTitle => 'Stations',
            title       => "Passengers");

B<Mandatory each time you want interactive functions to be active.>

=head2 marginAction

   $s->marginAction('JavaScript');

Defines a JavaScript action to be taken if you click in the area left of the chart.

=head2 MarginToolTip

   $s->marginToolTip('text');

Defines a tool tip text for the action defined with 'marginAction'.

=head1 A general example 

Everything is just invented. It is here to show how to use the module. If you want
the graphs to be less 'dramatic' change the type to lines or any of the other types. 

It might be easier to compare the individual offices with 'bars', totalbars',
or 'lines'.

=for general.pl begin

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

=for end

=head1 An example for Acrobat Reader 5.0.5 or higher

This is an example how you can "drill-down" into a chart and look at different
aspects of your data. You have 5 layouts and 20 different combinations of view =
100 more or less different charts, and you can look at fractions of the data.

First run the program 'testData.pl'. It creates 12960 lines with random data.

Put 'data.dat' in the directory defined for cgi-bin in a test environment.

Copy the other programs to the same directory.

Change or remove the shebang-line inside 'aspects.pl'.  
Run "aspects.pl" to generate 20 new programs.

You should have your local web server running.

Run one of the new programs e.g. "offmon.pl" and you get the PDF-file "offmon.pdf".

Open the file with Acrobat Reader and click on the bars, boxes or margins of the
chart to change aspects or layout.

=for testData.pl begin

     # testData.pl

     use strict;
     my @offices  = ('Helsinki', 'Oslo', 'Riga', 'St Petersburg', 
                     'Stockholm', 'Tallinn');
     my @deps     = (qw(Consulting Hardware Sales Software Staff));
     my @projects = (qw(Grid HospitalSystem NotSpecified OffShore
                      PowerPlant Switches ));
     my @types    = (qw(Admin Debited Development Education Salary Travel));
     my @months   = (qw(2003-01 2003-02 2003-03 2003-04 2003-05 2003-06 
                        2003-07 2003-08 2003-09 2003-10 2003-11 2003-12));
     my @factor   = ( 5, 7, 3, 8, 9, 4);
     my $i = -1;
     srand(time);
     my $number;

     open (OUT, ">data.dat") || die "Couldn't open data.dat $!\n";
     for my $office (@offices)
     {   $i++;
         for my $dep (@deps)
         {   for my $project (@projects)
             {   for my $type (@types)
                 {   for my $month (@months)
                     {   if ($type eq 'Debited')
                         {   $number = 97;
                         } 
                         elsif ($type eq 'Salary')
                         {   $number = 19;
                         }
                         elsif ($type eq 'Travel')
                         {   $number = 5;
                         }
                         else
                         {   $number = 9;
                         }
                         $number /= 2 if ($dep eq 'Staff');
                         $number /= 1.5 if ($project eq 'NotSpecified');
                         $number *= $factor[$i];
                         my $sum = sprintf("%.0f", rand($number)) + $factor[$i];
                         if (($sum % 12) < 10)
                         {  if ($type ne 'Debited') 
                            {  $sum *= -1;
                            }
                         }
                         else
                         {  $sum *= -1;
                         }
                         print OUT "$office;$dep;$project;$type;$month;$sum\n";
                     }
                 }
             }
         }
     }
     close OUT;

=for end

And then we need a JavaScript with a popup menu for the interactive areas of the
chart. ('aspects.js')

=for aspects.js begin

     function aspects(sentence)
     {   var target;
         var b = 'http://127.0.0.1:80/cgi-bin/';
         var a = ['offmon.pl', 'offdep.pl', 'offpro.pl', 'offtyp.pl', 
                  'depmon.pl', 'depoff.pl', 'deppro.pl', 'deptyp.pl',
                  'promon.pl', 'prooff.pl', 'prodep.pl', 'protyp.pl',
                  'typmon.pl', 'typoff.pl', 'typdep.pl', 'typpro.pl',
                  'monoff.pl', 'mondep.pl', 'monpro.pl', 'montyp.pl',
                  'bars', 'totalbars', 'percentbars', 'lines', 'area'];
         var n = ['(O)Month', '(O)Department', '(O)Project', '(O)Profit/Cost Type',
                  '(D)Month','(D)Office', '(D)Project', '(D)Profit/Cost Type',
                  '(P)Month', '(P)Office', '(P)Department', '(P)Profit/Cost Type',
                  '(C)Month', '(C)Office', '(C)Department', '(C)Project',
                  'Office', 'Department', 'Project', 'Profit/Cost',
                  'Bars', 'Stapled total bars', 'Stapled percentual bars', 
                  'Lines', 'Area'];
         var c = app.popUpMenu(['Office', n[0], n[1], n[2], n[3]],
                               ['Department', n[4], n[5], n[6], n[7]],
                               ['Project', n[8], n[9], n[10], n[11]],
                               ['Profit/Cost Type', n[12], n[13], n[14], n[15]],
                               ['Month', n[16], n[17], n[18], n[19]], '-',
                               ['Layout', n[20], n[21], n[22], n[23], n[24]]);
         for (var i = 0; i < n.length; i++)
         {   if (c == n[i])
             {   if (i < 20)
                    target = b + a[i] + '?sen=' + hexEncode(sentence) +
                    '&chart=' + chartVariant() + '&sel=' + hexEncode(sel()) + '&';
                 else
                    target = b + current() + '?chart=' + a[i] + '&sel=' 
                    + hexEncode(sel()) + '&sen=' + hexEncode(sentence) + '&';
                this.getURL(target, false);
                 break;
              }
          }
     } 

=for end

And a little JavaScript to hex encode the strings sent to the server ('hexEncode.js')

=for hexEncode.js begin

     function hexEncode(str)
     {  var out = '';
        for (var i = 0; i < str.length; i++)
        {  var num = str.charCodeAt(i);
           if ((num < 48) || (num > 122) || ((num > 57) && (num < 65))
           || ((num > 90) && (num < 97))) 
               out = out + '%' + util.printf("%x", num);
           else
               out = out + str[i];
        }
        return out;  
     }

=for end

And finally we have a program ('aspects.pl') that generates 20 other programs.
(Of course it could have made it with one single program, but it happened to
be done like this.) The generated programs are probably easier to read than this one.

=for aspects.pl begin

   use strict;
   my @dimension1 = (qw(Office Department Project Type Month));  # "Groups"
   my @dimension2 = (qw(Month Type Project Department Office));  # "Columns"

   my ($dim1, $dim2, $short1, $short2, $dimStr1, $dimStr2, $aspect, $column,
       $groupsTitle);

   for $dim1 (@dimension1)
   {   for $dim2 (@dimension2)
       {   if ($dim1 eq $dim2)
           {  next;
           }
           $short1      = lc(substr($dim1, 0, 3)); 
           $short2      = lc(substr($dim2, 0, 3));
           $dimStr1     = '$' . $dim1;
           $dimStr2     = '$' . $dim2;
           $column      = $dim2;
           $groupsTitle = $dim1;
           $aspect      = "$dim1/s split into $dim2/s";
           my $fileName = $short1 . $short2 . '.pl';
           open (OUT, ">$fileName") || die "Couldn't open $fileName $!\n";
           my $string = getText();
           print OUT $string;
           close OUT;
       }
   }

   sub getText
   {  my $str =<<"EOF";
\#!C:/Perl5.8/bin/perl

   use PDF::Reuse::SimpleChart;
   use PDF::Reuse;
   use strict;

   my (\$string, \%data, \$value, \$key, \$doc, \%accum, \%aspect1, \%aspect2);

   my \$tot = 0;

   my \$selection = '';

   my \%sel = ( minoff => 'Helsinki',
               maxoff => 'Tallinn',
               mindep => 'Consulting',
               maxdep => 'Staff',
               mintyp => 'Admin',
               maxtyp => 'Travel',
               minpro => 'Grid',
               maxpro => 'Switches',
               minmon => '2003-01',
               maxmon => '2003-12');
        
   ###############################
   # First get data to work with 
   ###############################

   if ( \$ENV{'REQUEST_METHOD'} eq "GET" 
   &&   \$ENV{'QUERY_STRING'}   ne '') 
   {  \$string = \$ENV{'QUERY_STRING'};
   }
   else                                         
   ###################################
   # If the program is run "manually"
   ###################################
   {  \$doc = substr(\$0, 0, index(\$0, '.')) . '.pdf';       
   }    

   ###############################################
   # Split and decode the hex-encoded strings
   # Create a hash with user data
   ###############################################

   for my \$pair (split('&', \$string)) 
   {  if (\$pair =~ /(.*)=(.*)/)                        # found key = value;
      {   (\$key,\$value) = (\$1,\$2);                  # get key, value.
           \$value =~ s/\\+/ /g;
           \$value =~ s/%(..)/pack('C',hex(\$1))/eg;  
           \$data{\$key} = \$value;                     # Create the hash.
      }
   }

   ################################################################
   # If there was a requesting program, the selection will replace
   # the default one, and a limiting sentence will be added
   ################################################################

   if (\$string)                             
   {  \%sel = split(/:/, \$data{sel});        # selection 
      my \@add   = split(/:/, \$data{sen});   # sentence 
      my \$i = 0;
      while(defined \$add[\$i])
      {  \$sel{\$add[\$i]} = \$add[\$i + 1] if defined \$add[\$i + 1];
         \$i += 2;
      }
   }

   my \$chartType  = \$data{chart} || 'bars'; 

   ##################################################
   # The new selection will be prepared as a string  
   ##################################################
         
   while ( my (\$key, \$value) = each \%sel)
   {  \$selection .= "\$key:\$value:";
   }

   ############################################################################
   # Create new output. If no document name was defined, send output to STDOUT
   ############################################################################
   
   if (! defined \$doc)
   {  \$| = 1;
      print STDOUT "Cache-Control: no-transform\\n";
      print STDOUT "Content-Type: application/pdf \\n\\n";

      prFile();
   }
   else
   {  prFile(\$doc);
   }
   prCompress(1);
   prJs('aspects.js');       # The file with the pop-up menu
   prJs('hexEncode.js');     # To hex-encode with JavaScript

   #####################################################################
   # Three small JavaScript functions will be added to the new document
   # They will have information about the program that created the new
   # chart: program name, chart type and used data selection
   #####################################################################

   prJs('function current() { return "$short1$short2.pl"; }');
   prJs("function chartVariant() { return '\$chartType'; }");
   prJs("function sel() { return '\$selection'; }");

   my \$s = PDF::Reuse::SimpleChart->new();

   ##################################################################
   # To create definitions for interactive areas in the new document
   ##################################################################

   \$s->defineIArea();

   #####################################
   # What to do and display to the left
   #####################################

   \$s->marginAction('aspects("dummy:nothing");');
   \$s->marginToolTip('Click and change aspect');

   #################################
   # Selection from the "database"
   #################################

   open (IN, "data.dat") || die ("Couldn't open data.dat \$! \\n");
   while (my (\$Office, \$Department, \$Project, \$Type, \$Month, \$sum) 
                                  = split(/;/, <IN>))
   {   
       if ( (\$Office     ge \$sel{minoff}) && (\$Office     le \$sel{maxoff})
       &&   (\$Department ge \$sel{mindep}) && (\$Department le \$sel{maxdep})
       &&   (\$Project    ge \$sel{minpro}) && (\$Project    le \$sel{maxpro})
       &&   (\$Type       ge \$sel{mintyp}) && (\$Type       le \$sel{maxtyp})
       &&   (\$Month      ge \$sel{minmon}) && (\$Month      le \$sel{maxmon}))
       {  \$accum{$dimStr1}->{$dimStr2} += \$sum;
          \$tot                         += \$sum;
          \$aspect1{$dimStr1}           += \$sum;
          \$aspect2{$dimStr2}           += \$sum;
       }
   }
   close IN;
   my \@groups       = sort (keys \%aspect1);
   my \@columns      = sort (keys \%aspect2);

   #######################################################################
   # Define columns, actions and tool tips for the areas under the y-axis
   #######################################################################

   \$s->columns( "$column", \@columns);
   \$s->columnsActions( map("aspects('min$short2:\$_:max$short2:\$_');", \@columns));
   \$s->columnsToolTips( map("\$_: \$aspect2{\$_}", \@columns));

   for my \$group (\@groups)
   {   ########################################################################
       # Define data, actions ( the string sent as a sentence, describe how
       # the data is limited for each specific bar) and tool tips for the bars
       ########################################################################
       my \@barValues = map( \$accum{\$group}->{\$_}, (sort(keys \%{\$accum{\$group}})));
       my \@barsActions = 
  map("aspects('min$short1:\$group:max$short1:\$group:min$short2:\$_:max$short2:\$_');",
      \@columns);

       \$s->add(\$group, \@barValues);

       \$s->barsActions(\$group,  \@barsActions );
       
       \$s->barsToolTips(\$group, map( "\$group: \$_ ", \@barValues) );

       ##################################################################
       # Each box to the right of the graph gets its action and tool tip
       ##################################################################

       \$s->boxAction(\$group, "aspects('min$short1:\$group:max$short1:\$group');");
       \$s->boxToolTip(\$group, "\$group: \$aspect1{\$group}");
   }
   
   my \$yUnit = (\$chartType eq 'percentbars') ? 'Percent' : '1000 Euros';

   \$s->draw(x           => 45,
             y           => 500,
             type        => \$chartType,
             iparam      => 0,
             height      => 300,
             width       => 460,
             yUnit       => \$yUnit,
             groupsTitle => "$groupsTitle",
             title       => "$aspect");

   ##############################################################
   # Texts under the chart, telling what selection has been used
   ##############################################################

   prText( 45, 450, "Office           \$sel{minoff}"); 
   prText(190, 450, "- \$sel{maxoff}");
   prText(300, 450, "Sum of processed values: \$tot");
   prText( 45, 435, "Department \$sel{mindep}");
   prText(190, 435, "- \$sel{maxdep}");
   prText( 45, 420, "Project         \$sel{minpro}");
   prText(190, 420, "- \$sel{maxpro}");
   prText( 45, 405, "Type            \$sel{mintyp}"); 
   prText(190, 405, "- \$sel{maxtyp}");
   prText( 45, 390, "Month          \$sel{minmon}");
   prText(190, 390, "- \$sel{maxmon}");



   prFontSize(9);
   prText(45,360, 
   'You need Acrobat Reader 5.0.5 or higher to use the interactive functions of the chart,');
   prText(45, 345,
   'and the Reader needs to have the option "Allow File Open Actions and Launching File ');
   prText(45, 330, 'Attachments" checked under "Preferences"');
   prText(45, 315, 
   'If you use Acrobat, a plug-in, "webpdf.api", converts documents fetched over the net,');
   prText(45, 300, 'and necessary JavaScripts are lost. ');  
 

   prEnd();
   ############################################## 
   # Next word has to be put in the first column
   ##############################################

EOF

   return $str;
} 

=for end

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