sub fileman {
	($markup) = @_ if @_;
	@parts=split(/\//,$ENV{'SCRIPT_FILENAME'});
	$homedir=join('/',@parts[0..$#parts-1]);

	&parse_index("$config{'content_dir'}/$field{'item'}",1);
	&trigger;
	

	$markup=~s/<!--xg_var:hidden-->/$info{'xg_hide'}/gie;
	$markup=~s/<!--xg_var:parent-->/&find_parent_dir/gie;
	$markup=~s/<!--xg_var:item-->/$field{'item'}/gie;
	$markup=~s/<!--xg_sample:(\w+)-->(.+?)<!--\/xg_sample-->/&make_item_list($field{'item'},$1,$2)/igse;
	$markup=~s/<!--xg_var:itemcount-->/$item_count/gie;
	$markup=~s/<!--xg_var:err-->/$err/gie;

	$markup=~s/<!--xg_var:clipboard-->/$cookie{'selection'}/gie;
	return $markup;
};
sub find_parent_dir {
	@parts=split(/\//,"/$field{'item'}");
	$parent=join("/",@parts[1..$#parts-1]);
	return "$parent";
};

sub make_item_list {
	local ($dir,$param,$markup,$block,$out) = @_ if @_;
	opendir (DIR, "$config{'content_dir'}/$dir");
		@files=readdir(DIR);
	closedir (DIR);

	foreach (@files) {
		if (! -d "$config{'content_dir'}/$dir/$_") {
			$filesize=-s "$config{'content_dir'}/$dir/$_";
			$filesize=&desize($filesize);
		};
		$fileage=&date_calculator(time()-86400*int(-M "$config{'content_dir'}/$dir/$_"));
		if ($dir) { $url_line="$dir/$_" } else { $url_line=$_ };
		if ($_ !~ /^\.+/) {
			if ($param eq "files" && ! -d "$config{'content_dir'}/$dir/$_" || $param eq "folders" && -d "$config{'content_dir'}/$dir/$_") {
				if ($info{'xg_hide'}=~/$_/) {$ishidden="checked"} else { $ishidden="" };
				$item_count++;
				$block=$markup;
				$block=~s/<!--xg_var:ishidden-->/$ishidden/ig;
				$block=~s/<!--xg_var:counter-->/$item_count/ig;
				$block=~s/<!--xg_var:filename-->/$_/ig;
				$block=~s/<!--xg_var:caption-->/$info{$_}/ig;
				$block=~s/<!--xg_var:url-->/$url_line/ig;
				$block=~s/<!--xg_var:size-->/$filesize/ig;
				$block=~s/<!--xg_var:date-->/$fileage/ig;
				$out.=$block;
			};
		};
	};
	return "$out";
};

sub date_calculator {
	($distance) = @_ if @_;
	($s,$m,$h,$d,$mon,$y,$w,$yd,$is) = localtime($distance);
	$y=1900+$y; $mon++;
	return "$d.$mon.$y";
};

sub info_alter {
	open (INFO,"$config{'content_dir'}/$field{'item'}/$config{'index_filename'}");
		$filecontent=join('',<INFO>);
	close (INFO);

	foreach (keys %field) {
		#$field{$_}=~s/\n//;
		($identifier,$name)=split(/\|/,$_);
		if ($identifier eq "xginfo") {
				$filecontent=~s/\n$name\=.*//g;
				$filecontent.="\n$name\=$field{$_}";
		};
	};

	$filecontent=~s/\nxg_hide\=.*//g;
	$filecontent.="\nxg_hide\=$field{'hidden'}";
	$filecontent=~ s/\n{4,}//g;
	

	unlink ("$config{'content_dir'}/$field{'item'}/$config{'index_filename'}");
	open (INFO,">$config{'content_dir'}/$field{'item'}/$config{'index_filename'}");
		print INFO $filecontent;
	close (INFO);
};


# Логическая функция выбора текущего действия. Выбор действия производится
# исходя из содержимого элемента 'action' хэша %field.
#
# Подразумевается также наличие скаляров $cookie{'selection'} и
# $field{'selection'}, содержащих список элементов в буфере обмена
# и список выделенных на данный момент элементов соответственно,
# а также $field{'item'} - путь к активной папке.
# В случае отсутствия в скалярах подходящей информации, циклы
# foreach не выполняются, к аварийному заваршению программы это не приводит.

sub trigger {
	@clipboard=split(/#/,$cookie{'selection'});
	@selection=split(/#/,$field{'selection'});

	if ($field{'action'} eq "paste") {

		# В случае выполнения команды paste, программа приступает
		# к копированию или перемещению (копированию и удалению 
		# источника), используя данные о содержимом буфера обмена
		# ($cookie{'selection'}).

		foreach (@clipboard) {
			@parts=split(/\//,$_);
			$filename=$parts[$#parts];
			
			# Следующий блок отвечает за подбор уникального имени
			# для нового файла, если заданное ранее имя уже 
			# существует, путем добавления к имени файла строки 
			# "Copy_". 

			rebuild:
			$new_url=&secure("$config{'content_dir'}/$field{'item'}/$filename");
			if (-e $new_url && $filename) {
				$filename="Copy_$filename";
				goto "rebuild";
			};
			
			# Перед выполнением каких-либо действий, убеждаемся в 
			# существовании запрошенного элемента (файла или папки - 
			# на данный момент безразлично) и в том, что полученный 
			# путь не является ссылкой на вышестоящую папку.

			if (-e "$config{'content_dir'}/$_" && $filename) {
				if ($cookie{'action'} eq "copy") {
					unless (-d "$config{'content_dir'}/$_") {

						# Копируем файл или сообщаем об
						# ошибке. Копирование производим
						# с помощью функции copy() 
						# модуля File/copy.pm

						copy ("$config{'content_dir'}/$_",$new_url) or die "Copy failed: $!";
					} else {
						
						# Копируем папку со всеми вложенными
						# элементами с помощью функции &copy_tree

						&copy_tree("$config{'content_dir'}/$_",$new_url);
					};
				} elsif ($cookie{'action'} eq "cut") {
					unless (-d "$config{'content_dir'}/$_") {

						# Перемещаем файл или сообщаем об
						# ошибке. Перемещение производим
						# с помощью функции move() 
						# модуля File/copy.pm

						move ("$config{'content_dir'}/$_",$new_url) or die "Move failed: $!";
					} else {
						
						# Перемещаем папку.
						# Шаг1. копируем папку со всеми вложенными
						# элементами с помощью функции &copy_tree

						&copy_tree("$config{'content_dir'}/$_",$new_url);

						# Шаг2. удаляем исходную папку со всеми вложенными
						# элементами с помощью функции &del_tree

						&del_tree("$config{'content_dir'}/$_");
					};
				};
			};
		};

		# По завершении работы программы, необходимо сбросить значения буфера обмена
		# в cookie браузера. Этим занимается клиентская часть программы (javascript),
		# поэтому присваиваем значение clear переменной $cookie{'selection'} - 
		# В дальнейшем это значение возвращается клиенту подпрограммой обработки html.
 
		$cookie{'selection'}="clear";
	};
	if ($field{'action'} eq "delete") {
		foreach (@selection) {
			@parts=split(/\//,$_);
			$filename=$parts[$#parts];
			
			# При удалении файла используем список, переданный в строке запроса
			# $field{'selection'}. Проверяем существование запрошенного элемента
			# и правильность запроса.

			if (-e "$config{'content_dir'}/$_" && $filename) {
				if (!-d "$config{'content_dir'}/$_") {
					
					# удаляем файл средствами встроенной в Perl
					# функции unlink.

					unlink ("$config{'content_dir'}/$_");
				} else {
					# Удаляем папку со всеми вложенными
					# элементами с помощью функции &del_tree

					&del_tree("$config{'content_dir'}/$_");
				};
			};
		};
	};


	if ($field{'action'} eq "rename") {
		@parts=split(/\//,$selection[$#selection]);
		$filename=$parts[$#parts];

		$source=&secure($filename);
		$destination=&secure($field{'newname'});
		$url=&secure("$config{'content_dir'}/$field{'item'}");
		
		if (length($destination) > $config{'filename_length'}) { 
			$destination=substr($destination,0,$config{'filename_length'})
		};

		if ($destination eq "null" || !$destination) { 
			$err.="Cannot rename: Filename is empty;";
			goto "action_abort";
		};

		chdir $url;
		$isOk=rename ($source,$destination);
		chdir $homedir;

		unless ($isOk) {
			$err.="Cannot rename: Bad request; ";
		};
	};
	if ($field{'action'} eq "create") {
		
	};
	if ($field{'action'} eq "reset") {
		if (-e "$config{'content_dir'}/$field{'item'}/$config{'index_filename'}") {
			unlink "$config{'content_dir'}/$field{'item'}/$config{'index_filename'}";
		};
		&parse_index("$config{'content_dir'}/$field{'item'}");
	};
	if ($field{'action'} eq "change") {
		%info=();
		&info_alter;
		&parse_index("$config{'content_dir'}/$field{'item'}",1);
	};


# В случае возникновения ошибок, программа возвращается
# сюда.

action_abort:
};

sub secure {
	
	# Подпрограмма исключения из строки запроса ненужных
	# и опасных символов. На входе\выходе скаляр $string.

	local ($string) = @_ if @_;
	$string=~s/\/{2,}/\//g;
	$string=~s/[\!\~\@\$\%\^\&\*\(\)\=\+\"\№\;\:\?\\]//g;
	return $string;
};


sub del_tree {
	local($current_item)=@_ if @_;
	@file_list=(); @dir_list=();
	&list_tree($current_item);
	foreach $file_id (@file_list){
		$action_url=&secure("$current_item/$file_id");
		unlink ($action_url);
	};
	for ($i=$#dir_list;$i>-1;$i--) {
		$dir_id=$dir_list[$i];
		$action_url=&secure("$current_item/$dir_id");
		rmdir $action_url;
	};
	rmdir $current_item;
};

sub copy_tree {
	local($current_item,$new_url)=@_ if @_;
	if ($new_url=~/$current_item/) { $err.="Filesystem error: Recursive copying; "; goto "action_abort" };
	mkdir $new_url;
	@file_list=(); @dir_list=();
	&list_tree($current_item);
	foreach $dir_id (@dir_list){
		$action_url=&secure("$new_url/$dir_id");
		mkdir $action_url;
	};
	foreach $file_id (@file_list){
		$source=&secure("$current_item/$file_id");
		$destination=&secure("$new_url/$file_id");
		copy ($source,$destination) or die "Copy failed: $!";
	};
};

sub list_tree {
	local($cd,$save_dir)=@_ if @_;
	foreach (&dir($cd)) {
		if (!-d "$cd/$_") {
			push (@file_list,"$save_dir/$_");
		} elsif($_ !~ /\.\./ && $_ ne '.') {
			push (@dir_list,"$save_dir/$_");
			&list_tree("$cd/$_","$save_dir/$_");
		};
	};
};
sub dir {
	local($dir)=@_ if @_;
	opendir (D, $dir);
		@i=readdir(D);
	closedir (D);
	return @i;
};
