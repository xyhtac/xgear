sub logon {
	local ($markup) = @_ if @_;
	$markup=~s/<!--xg_sample:login-->(.+?)<!--\/xg_sample-->/&login($1)/igse;
	$markup=~s/<!--xg_sample:logout-->(.+?)<!--\/xg_sample-->/&list_modules($1)/igse;
	return $markup;
};

sub login {
	local ($block) = @_ if @_;
	if ($cookie{'xg_username'} ne "Guest") { return "" };	

	return $block;
};
sub list_modules {
	local ($block) = @_ if @_;
	if ($cookie{'xg_username'} eq "Guest") { return "" };
	$block=~s/<!--xg_var:username-->/$cookie{'xg_username'}/ige;
	$block=~s/<!--xg_var:rank-->/$cookie{'xg_rank'}/ige;
	return $block;
};