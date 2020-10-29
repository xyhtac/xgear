#!/usr/bin/perl -w
use File::Copy;

$config{'markup_dir'}="../style";
$config{'modules_dir'}="modules";
$config{'content_dir'}="../content";
$config{'news_dir'}="news";
$config{'index_filename'}="index.ini";
$config{'index_default'}="index.ini.default";
$config{'users_registry'}="users.txt";
$config{'size_abbrevations'}="Bytes,KBytes,MBytes,GBytes";
$config{'size_precision'}="2";
$config{'default_url'}="Use navigation panel";
$config{'default_markup'}="index.html";
$config{'400_url'}="errors/400.htm";
$config{'401_url'}="errors/401.htm";
$config{'403_url'}="errors/403.htm";
$config{'404_url'}="errors/404.htm";
$config{'unauthorized_url'}="errors/wrongpass.htm";
$config{'filename_length'}=32;


&get_cookie;
&parse_fields;
&parse_users_registry;
&check_request;
&parse_html;

# The program has prepared following useful information that you can use now:
# %field - fully parsed and decoded form input data.
# %cookie - parsed cookies.
#
# Also, you can place your own variables into the 'xgear.conf' file in order to
# prevent troubles with the variable naming. All system and user-defined
# variables are accessible in the %config hash.
#
# User-defined modules can be placed either here as a subroutines, or inside
# special directory. (It is predefined in the "modules_dir" line of the "xgear.conf")
# In case of using external files, filename will be used to identify your module.

sub menu {
	local ($markup,$block,$out) = @_ if @_;
	&parse_index($config{'content_dir'});
	%root_info=%info;
	opendir (ROOT, "$config{'content_dir'}");
		@items=readdir(ROOT);
	closedir (ROOT);
	foreach (@items) {
		$caption=$_;
		$caption=$root_info{$_} if $root_info{$_};
		if ($root_info{'xg_hide'} !~ /$_/ && -d "$config{'content_dir'}/$_") {
			$block=$markup;
			$block=~s/<!--xg_var:folder-->/$caption/g;
			$block=~s/<!--xg_sample:(\w+)-->(.+?)<!--\/xg_sample-->/&list_items("$_",$1,$2)/igse;
			$out.=$block;
		};
	};
	return $out;
};

sub list_items {
	local ($dir,$param,$markup,$block,$out) = @_ if @_;
	opendir (DIR, "$config{'content_dir'}/$dir");
		@files=readdir(DIR);
	closedir (DIR);
	&parse_index("$config{'content_dir'}/$dir");
	foreach (@files) {
		if ($info{$_}) {
			$caption=$info{$_};
		} else {
			$caption=$_;
		};
		if ($_ =~ /\.link$/ && !-d "$config{'content_dir'}/$dir/$_") {
			open (LINK, "$config{'content_dir'}/$dir/$_");
				$url_line=join('',<LINK>);
			close (LINK);
			$url_line=~s/[\n\r]//;
			if ($url_line !~ /http:\/\//i) {
				$url_line="?object=$url_line";
			};
		} else {
			$url_line="?object=$dir/$_";
		};
		if ($info{'xg_hide'} !~ /$_/ && $_ !~ /^\.+/) {
			if ($param eq "files" && ! -d "$config{'content_dir'}/$dir/$_" || $param eq "folders" && -d "$config{'content_dir'}/$dir/$_") {
				$block=$markup;
				$block=~s/<!--xg_var:caption-->/$caption/ig;
				$block=~s/<!--xg_var:link-->/$url_line/ig;
				$out.=$block;
			};
		};
	};
	return "$out";
};



sub header {
	local ($markup) = @_ if @_;
	$markup=~s/<!--xg_sample:\w+-->(.+?)<!--\/xg_sample-->/&link_line($1)/igse;
	return $markup;
};
sub link_line {
	local ($markup,$out) = @_ if @_;
	@p=split(/\//, $field{'object'});
	for ($n=0;$n<$#p+1;$n++) {
		$url=join('/',@p[0..$n]);
		$info_url=join('/',@p[0..$n-1]);
		&parse_index("$config{'content_dir'}/$info_url");
		$caption=$p[$n];
		$caption=$info{$p[$n]} if $info{$p[$n]};
		$block=$markup;
			$block=~s/<!--xg_var:link-->/?object=$url/ig;
			$block=~s/<!--xg_var:caption-->/$caption/ig;
		$out.=$block;
	};
	return $out;
};


sub content {
	local ($markup) = @_ if @_; StepIn:
	
	if (!-d "$config{'content_dir'}/$field{'object'}") { 
		open (FILE, "$config{'content_dir'}/$field{'object'}");
			$filecontent=join('',<FILE>);
		close (FILE);
	};
	if ($filecontent =~ /<!--xg_use_filter:(\w+)-->/) {
		if (exists &$1) {
			$filecontent=&$1($filecontent);
		} else { return "[ XG: Filter '$1' not found ]" };
	} elsif (-d "$config{'content_dir'}/$field{'object'}") {
		&parse_index("$config{'content_dir'}/$field{'object'}");
		if (-e "$config{'content_dir'}/$field{'object'}/$info{'xg_index'}") {
			$field{'object'}="$field{'object'}/$info{'xg_index'}";
			goto "StepIn";
		} else {
			$markup=~s/<!--xg_sample:(\w+)-->(.+?)<!--\/xg_sample-->/&list_items($field{'object'},$1,$2)/igse;
			$filecontent=$markup;
		};
	} elsif ($field{'object'}=~/\.txt$/) {
		$filecontent=&make_html($filecontent);
	};
	return $filecontent;
};


### Essential subroutines.

sub parse_users_registry {
	open (REG, "$config{'users_registry'}");
		local @lines=<REG>;
	close (REG);
	foreach (@lines) {
		local @parts=split(/\:/,$_);
		$key{$parts[0]}=$parts[1];
		$rank{$parts[0]}=$parts[2];
	};
};

sub parse_html {
	open (MARKUP, "$config{'markup_dir'}/$field{'use_markup'}");
		$html=join('',<MARKUP>);
	close (MARKUP);
	$html =~ s/<!--xg_mod:(\w+)-->(.+?)<!--\/xg_mod-->/&module_loader($1,$2)/igse;
	print "Content-type: text/html\n\n $html";
};

sub parse_index {
	local ($dir,$override)=@_ if @_;
	%info=();%access=();

	if (!-e "$dir/$config{'index_filename'}" && !$override) {
		open (DEFAULT, "$config{'index_default'}");
			$fc=join('',<DEFAULT>);
		close (DEFAULT);
		open (INDEX, ">$dir/$config{'index_filename'}");
			print INDEX $fc;
		close (INDEX);
	};
	open (NAME, "$dir/$config{'index_filename'}");
		@names=<NAME>;
	close (NAME);
	foreach (@names) {
		local ($item)=$_; chomp($item);

		#@parts=split(/#/,$item); $item=$parts[0];

		if ($item && $item !~/^\#/) {
			@parts=split(/=/,$item);
			$value=join('=',@parts[1..$#parts]);
			$value=~s/"/'/g;
			
			if ($parts[0] eq "xg_access_level") {
				$access{'level'}=$value;
			} elsif ($parts[0] eq "xg_special_allow") {
				$access{'allow'}=$value;
			} elsif ($parts[0] eq "xg_special_deny") {
				$access{'deny'}=$value;
			} else {
				if (!$info{@parts[0]}) {
					$info{@parts[0]}=$value;
				} else {
					$info{@parts[0]}.=",$value";
				};
			};
		};
	};
};


sub parse_fields {
        (*fval) = @_ if @_ ;
        local ($buf);
        if ($ENV{'REQUEST_METHOD'} eq 'POST') {
                read(STDIN,$buf,$ENV{'CONTENT_LENGTH'});
        }
        else {
                $buf=$ENV{'QUERY_STRING'};
        }
        if ($buf eq "") {
                        return 0 ;
                }
        else {
                @fval=split(/&/,$buf);
                foreach $i (0 .. $#fval){
                  ($name,$val)=split (/=/,$fval[$i],2);
                  $val=~tr/+/ /;
                  $val=~ s/%(..)/pack("c",hex($1))/ge;
                  $name=~tr/+/ /;
                  $name=~ s/%(..)/pack("c",hex($1))/ge;
                  if (!$field{$name}) {
                        $field{$name}=$val;
                  } else {
                        $field{$name} .= " ".$val;
                  };
                 }
        };
  return 1;
};

sub module_loader {
	local ($modname, $content) = @_ if @_;
	if (exists &$modname) {
		$result=&$modname($content);
	} elsif (-e "$config{'modules_dir'}/$modname.m") { 
		open (MODULE, "$config{'modules_dir'}/$modname.m");
			eval join('',<MODULE>);
		close (MODULE);
		$result=&$modname($content);
	} else {
		return "[ XG: Module '$modname' not exists ]";
	}; return "$result";
};

sub desize {
	local ($size,$step) = @_ if @_;
	local @abbrevations = split(/,/,$config{'size_abbrevations'});
	while ($size>1024) { $size=$size/1024; $step++ };
	($real,$mantissa)=split(/\./,$size);
	$mantissa=".".substr($mantissa,0,$config{'size_precision'}) if $mantissa;
	$size="$real$mantissa $abbrevations[$step]";
	return $size;
};



sub get_cookie {
	local @env_cookie=split(/; /,$ENV{'HTTP_COOKIE'});
	foreach (@env_cookie) {
		local @parts=split(/=/,$_);

                @parts[0]=~tr/+/ /;
                @parts[0]=~ s/%(..)/pack("c",hex($1))/ge;
                @parts[1]=~tr/+/ /;
                @parts[1]=~ s/%(..)/pack("c",hex($1))/ge;

		$cookie{@parts[0]}=@parts[1];
	};
};

sub check_request {
	if (!$cookie{'xg_username'} || !&authorize_user($cookie{'xg_username'},$cookie{'xg_password'})) {
		$cookie{'xg_username'} = "Guest";
		$cookie{'xg_rank'}=0;
	};
	$field{'object'} = $config{'default_url'} if !$field{'object'};
	if (!-e "$config{'content_dir'}/$field{'object'}") { $field{'object'} = $config{'404_url'} };
	if ($field{'object'} =~ /\.\./i || $field{'object'} =~ /\\/i) { $field{'object'} = $config{'400_url'} };

	@url_parts=split(/\//,$field{'object'}); $parent=join('/',@url_parts[0..$#url_parts-1]);
	&parse_index("$config{'content_dir'}/$parent");
	if ($info{'xg_hide'} =~ /$url_parts[$#url_parts]/) { $field{'object'} = $config{'403_url'}; };
	if (-d "$config{'content_dir'}/$field{'object'}") {
		&parse_index("$config{'content_dir'}/$field{'object'}");
	};
	unless (&check_allowance($cookie{'xg_username'},$access{'allow'},$access{'deny'},$access{'level'})) {
		$field{'object'} = $config{'401_url'};
	};
	if (!$field{'use_markup'} || !-e "$config{'markup_dir'}/$field{'use_markup'}" || $field{'use_markup'} =~ /\.\./i) {
		$field{'use_markup'}=$config{'default_markup'};
	};
};

sub authorize_user {
	local ($username, $password) = @_ if @_;
	$crypted=crypt($password,$username);
	if ($key{$username} eq $crypted) {
		$cookie{'xg_rank'}=$rank{$username};
		return 1;
	} else {
		if ($password) {
			$field{'object'}=$config{'unauthorized_url'};
		};
		return 0;
	};
};

sub check_allowance {
	local($username,$allow,$deny,$level)= @_ if @_;
	if (&case_shift($deny) =~ /&case_shift($username)/i) { $denied=1 };
	if (&case_shift($allow) =~ /&case_shift($username)/i) { $allowed=1 };
	if ( ($level <= $rank{$username} && !$denied) || $allowed) {
		return 1
	} else { return 0 };
};

sub make_html {
	local ($entry) = @_ if @_;
	$entry=~ s/&/&amp;/g;
	$entry=~ s/"/&quot;/g;
	$entry=~ s/</&lt;/g;
	$entry=~ s/>/&gt;/g;
	$entry=~ s/(http:\/\/\S+)/<a href="$1" target="_blank">$1<\/A>/g;
	$entry=~ s/(\S+@\S+\.\S+)/<a href="mailto:$1" target="_blank">$1<\/A>/g;
	$entry=~ s/\n/<br> /g;
	return $entry;
};

sub case_shift {
	local($string)=@_ if @_;
	$string=~tr/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÜÛÚÝÞß/àáâãäå¸æçèéêëìíîïðñòóôõö÷øùüûúýþÿ/;
	$string=~tr/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/;
	return $string;
};
