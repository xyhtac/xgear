@mnames=(
'january',
'february',
'march',
'april',
'may',
'june',
'july',
'august',
'september',
'october',
'november',
'december',
'jan',
'feb',
'mar',
'apr',
'may',
'jun',
'jul',
'aug',
'sep',
'oct',
'nov',
'dec'
); 
($s,$m,$h,$d,$mon,$y,$w,$yd,$is) = localtime();
unless ($field{'news_month'}) {
	$ty=1900+$y; $tm = $mon+1; if (length($tm) eq 1) { $tm="0$tm" }; 
	$field{'news_month'}="$tm-$ty";
};

sub calendar {
	local ($markup) = @_ if @_;
	$markup=~s/<!--xg_sample:list-->(.+?)<!--\/xg_sample-->/&list_months($1)/igse;
	$markup=~s/<!--xg_sample:week-->(.+?)<!--\/xg_sample-->/&build($1)/igse;
	$markup=~s/<!--xg_var:object-->/$field{'object'}/ige;
	return $markup;
};

sub list_months {
	local ($block,$out,$date) = @_ if @_;
	opendir (NEWS, "$config{'content_dir'}/$config{'news_dir'}");
		@items=readdir(NEWS);
	closedir (NEWS);
	$current_month=$mon+1;
	if (length($current_month) eq 1) { $current_month="0$current_month" };
	$current_year=1900+$y;

	$month_list=join('#',@items);
	$current_date="$current_month-$current_year";
	if ($month_list !~ /$current_date/) {
		unshift(@items,"$current_date");
	};

	foreach $date (@items) {
		if ((-d "$config{'content_dir'}/$config{'news_dir'}/$date" && $date !~ /^\.+/) || ($date eq $current_date)) {
			$temp=$block;
			($monthindex,$yearindex)=split(/-/,$date);
			$caption="$mnames[$monthindex-1] $yearindex";
			if ($date eq $field{'news_month'}) {
				$option_state="selected";
			} else {
				$option_state="";
			};
			$temp=~s/<!--xg_var:value-->/$date/ig;
			$temp=~s/<!--xg_var:caption-->/$caption/ig;
			$temp=~s/<!--xg_var:selected-->/$option_state/ig;
			$out.=$temp;
		};
	}; return "$out $current_month-$current_year";
};

sub build {
	local ($block,$out,$year,$month,$delta,$inday,$seconds) = @_ if @_;
	@days=(31,28,31,30,31,30,31,31,30,31,30,31);
	($month,$year)=split(/-/,$field{'news_month'}); $inday=86400;
	if (int($year/4) eq ($year/4)) { $days[1]++ };
	$years_passed=$year-1969; $super_years=int($years_passed/4);
	for ($i=0;$i<$month-1;$i++) { $delta+=$days[$i] };
	$seconds=(($years_passed-1)*365+$super_years+$delta)*$inday;
	@date_parts = localtime($seconds-10800); $wday = $date_parts[6];	 
	$wday = 7 unless $wday; $weeks_count=($days[$month-1]+$wday)/7;
	if ($weeks_count =~ /\./) { $weeks_count=int($weeks_count)+1 };
	for ($i=1;$i<=$weeks_count;$i++) {
		$temp=$block;
		for ($l=1;$l<8;$l++) {
			if (($i > 1 || $l>=$wday) && $date<$days[$month-1] ) {
				$date++; $c_date=$date;
				if (length($c_date) eq 1) { $c_date="0$c_date" };
				if (-e "$config{'content_dir'}/$config{'news_dir'}/$month-$year/$c_date") {
					$stylesheet="news-active";
					$link_line="?object=$config{'news_dir'}/$month-$year/$c_date";
				} else { 
					$link_line=""; $stylesheet="news-passive"; 
				};
				if ($date eq $d && $month == $mon+1 && $year eq $y+1900) { 
					$stylesheet="news-today";
				};
				$temp=~s/<!--xg_var:caption$l-->/$date/igse;
				$temp=~s/<!--xg_var:link$l-->/$link_line/igs;
				$temp=~s/<!--xg_var:style$l-->/$stylesheet/igs;
			}; 
		};
		$out.=$temp;
	};
	return $out;
};